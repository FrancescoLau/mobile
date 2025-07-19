// lib/providers/review_provider.dart
import 'package:flutter/foundation.dart';
import '../models/review.dart';
import '../services/review_service.dart';

class ReviewProvider extends ChangeNotifier {
  // Stato privato
  bool _isLoading = false;
  String? _errorMessage;
  final Map<String, List<Review>> _workoutReviews = {};
  final Map<String, double> _averageRatings = {};
  List<Review> _userReviews = [];

  // Getter per lo stato
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Review> get userReviews => List.unmodifiable(_userReviews);

  // CORREZIONE BUG #2: Ottieni recensioni per un allenamento specifico
  List<Review> getWorkoutReviews(String workoutId) {
    return List.unmodifiable(_workoutReviews[workoutId] ?? []);
  }

  // CORREZIONE BUG #2: Ottieni rating medio per un allenamento
  double getAverageRating(String workoutId) {
    final reviews = _workoutReviews[workoutId] ?? [];
    if (reviews.isEmpty) return 0.0;

    final totalRating = reviews.fold<double>(0, (sum, review) => sum + review.rating);
    return totalRating / reviews.length;
  }

  // Carica recensioni per un allenamento
  Future<void> loadWorkoutReviews(String workoutId) async {
    _setLoading(true);
    _clearError();

    try {
      final reviews = await ReviewService.getWorkoutReviews(workoutId);
      _workoutReviews[workoutId] = reviews;
      
      // CORREZIONE: Calcola la media localmente invece di fare una chiamata separata
      if (reviews.isNotEmpty) {
        final totalRating = reviews.fold<double>(0, (sum, review) => sum + review.rating);
        _averageRatings[workoutId] = totalRating / reviews.length;
      } else {
        _averageRatings[workoutId] = 0.0;
      }

      notifyListeners();
    } catch (e) {
      _setError('Errore durante il caricamento delle recensioni: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Carica recensioni dell'utente corrente
  Future<void> loadUserReviews(String userId) async {
    _setLoading(true);
    _clearError();

    try {
      _userReviews = await ReviewService.getUserReviews(userId);
      notifyListeners();
    } catch (e) {
      _setError('Errore durante il caricamento delle tue recensioni: $e');
    } finally {
      _setLoading(false);
    }
  }

  // CORREZIONE BUG #3: Aggiungi recensione con gestione errori migliorata
  Future<bool> addReview(
      String workoutId, String userId, String userEmail, double rating, String comment) async {
    _setLoading(true);
    _clearError();

    try {
      // Validazione parametri
      if (userEmail.isEmpty) {
        _setError('Devi essere loggato per pubblicare una recensione');
        return false;
      }

      if (rating < 1 || rating > 5) {
        _setError('Il rating deve essere compreso tra 1 e 5');
        return false;
      }

      if (comment.trim().isEmpty) {
        _setError('Il commento non può essere vuoto');
        return false;
      }

      // CORREZIONE BUG #3: Verifica recensione duplicata con messaggio specifico
      final hasReviewed = await ReviewService.hasUserReviewed(userId, workoutId);
      if (hasReviewed) {
        _setError('Hai già pubblicato una recensione per questo allenamento. Puoi modificare la tua recensione esistente.');
        return false;
      }

      final newReview = Review(
        id: 'review_${DateTime.now().millisecondsSinceEpoch}',
        workoutId: workoutId,
        userId: userId,
        userEmail: userEmail,
        rating: rating,
        comment: comment.trim(),
        createdAt: DateTime.now(),
        isHidden: false,
      );

      final success = await ReviewService.addReview(newReview);
      if (success) {
        // Aggiorna lo stato locale immediatamente
        if (_workoutReviews[workoutId] == null) {
          _workoutReviews[workoutId] = [];
        }
        _workoutReviews[workoutId]!.add(newReview);
        _userReviews.add(newReview);
        
        // Ricalcola la media
        await _recalculateAverage(workoutId);
        
        notifyListeners();
        return true;
      }

      _setError('Errore durante l\'aggiunta della recensione');
      return false;
    } catch (e) {
      _setError('Errore durante l\'aggiunta della recensione: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // CORREZIONE BUG #1: Metodo unificato per aggiornare recensioni
  Future<bool> updateReview(String reviewId, double rating, String comment) async {
    if (rating < 1 || rating > 5) {
      _setError('Il rating deve essere compreso tra 1 e 5');
      return false;
    }

    if (comment.trim().isEmpty) {
      _setError('Il commento non può essere vuoto');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      // CORREZIONE: Cerca in tutti i workout reviews, non solo nelle user reviews
      Review? existingReview;
      String? workoutId;
      
      // Cerca prima nelle recensioni utente
      for (final review in _userReviews) {
        if (review.id == reviewId) {
          existingReview = review;
          workoutId = review.workoutId;
          break;
        }
      }

      // Se non trovata, cerca in tutti i workout
      if (existingReview == null) {
        for (final wId in _workoutReviews.keys) {
          for (final review in _workoutReviews[wId]!) {
            if (review.id == reviewId) {
              existingReview = review;
              workoutId = wId;
              break;
            }
          }
          if (existingReview != null) break;
        }
      }

      if (existingReview == null) {
        _setError('Recensione non trovata');
        return false;
      }

      final updatedReview = existingReview.copyWith(
        rating: rating,
        comment: comment.trim(),
        updatedAt: DateTime.now(),
      );

      final success = await ReviewService.updateReview(updatedReview);

      if (success) {
        // CORREZIONE: Aggiorna immediatamente lo stato locale
        await _updateReviewInLocalState(reviewId, updatedReview);
        await _recalculateAverage(workoutId!);
        
        notifyListeners();
        return true;
      } else {
        _setError('Errore durante l\'aggiornamento della recensione');
        return false;
      }
    } catch (e) {
      _setError('Errore durante l\'aggiornamento della recensione: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Elimina recensione
  Future<bool> deleteReview(String reviewId) async {
    _setLoading(true);
    _clearError();

    try {
      Review? reviewToDelete;
      String? workoutId;
      
      // Trova la recensione
      for (final review in _userReviews) {
        if (review.id == reviewId) {
          reviewToDelete = review;
          workoutId = review.workoutId;
          break;
        }
      }

      if (reviewToDelete == null) {
        _setError('Recensione non trovata');
        return false;
      }

      final success = await ReviewService.deleteReview(reviewId);

      if (success) {
        // Rimuovi dallo stato locale
        _userReviews.removeWhere((r) => r.id == reviewId);
        _workoutReviews[workoutId]?.removeWhere((r) => r.id == reviewId);
        
        // Ricalcola la media
        await _recalculateAverage(workoutId!);
        
        notifyListeners();
        return true;
      } else {
        _setError('Errore durante l\'eliminazione della recensione');
        return false;
      }
    } catch (e) {
      _setError('Errore durante l\'eliminazione della recensione: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Modera recensione (solo admin)
  Future<bool> moderateReview(String reviewId, bool hide) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await ReviewService.moderateReview(reviewId, hide);

      if (success) {
        // Aggiorna localmente
        for (final workoutId in _workoutReviews.keys) {
          final reviews = _workoutReviews[workoutId]!;
          for (int i = 0; i < reviews.length; i++) {
            if (reviews[i].id == reviewId) {
              reviews[i] = reviews[i].copyWith(isHidden: hide);
              break;
            }
          }
        }
        
        // Aggiorna anche nelle user reviews
        for (int i = 0; i < _userReviews.length; i++) {
          if (_userReviews[i].id == reviewId) {
            _userReviews[i] = _userReviews[i].copyWith(isHidden: hide);
            break;
          }
        }
        
        notifyListeners();
        return true;
      } else {
        _setError('Errore durante la moderazione');
        return false;
      }
    } catch (e) {
      _setError('Errore durante la moderazione: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Verifica se l'utente ha già recensito un allenamento
  Future<bool> hasUserReviewed(String userId, String workoutId) async {
    try {
      return await ReviewService.hasUserReviewed(userId, workoutId);
    } catch (e) {
      return false;
    }
  }

  // Ottieni la recensione dell'utente per un allenamento
  Future<Review?> getUserReviewForWorkout(String userId, String workoutId) async {
    try {
      return await ReviewService.getUserReviewForWorkout(userId, workoutId);
    } catch (e) {
      return null;
    }
  }

  // CORREZIONE BUG #2: Metodo corretto per ottenere le statistiche
  Map<String, dynamic> getWorkoutStats(String workoutId) {
    final reviews = getWorkoutReviews(workoutId);
    if (reviews.isEmpty) {
      return {'rating': 0.0, 'count': 0};
    }
    
    final totalRating = reviews.fold<double>(0.0, (sum, review) => sum + review.rating);
    final avgRating = totalRating / reviews.length;
    
    return {
      'rating': double.parse(avgRating.toStringAsFixed(1)),
      'count': reviews.length
    };
  }

  // Ottieni statistiche recensioni complete
  Future<Map<String, dynamic>> getWorkoutReviewStats(String workoutId) async {
    try {
      final stats = await ReviewService.getWorkoutReviewStats(workoutId);
      return {
        'totalReviews': stats.totalReviews,
        'averageRating': stats.averageRating,
        'ratingDistribution': stats.ratingDistribution,
      };
    } catch (e) {
      // Fallback ai dati locali
      final localStats = getWorkoutStats(workoutId);
      return {
        'totalReviews': localStats['count'],
        'averageRating': localStats['rating'],
        'ratingDistribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
      };
    }
  }

  // Cerca recensioni
  Future<List<Review>> searchReviews(String query) async {
    _setLoading(true);
    _clearError();

    try {
      final results = await ReviewService.searchReviews(query);
      return results;
    } catch (e) {
      _setError('Errore durante la ricerca nelle recensioni: $e');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  // Ottieni le recensioni più recenti
  Future<List<Review>> getRecentReviews({int limit = 10}) async {
    try {
      return await ReviewService.getRecentReviews(limit: limit);
    } catch (e) {
      return [];
    }
  }

  // Ottieni le recensioni migliori
  Future<List<Review>> getTopReviews({int limit = 10}) async {
    try {
      return await ReviewService.getTopReviews(limit: limit);
    } catch (e) {
      return [];
    }
  }

  // Valida una recensione prima dell'invio
  List<String> validateReview(Review review) {
    return ReviewService.validateReview(review);
  }

  // Ottieni conteggio recensioni per un workout
  Future<int> getReviewCount(String workoutId) async {
    try {
      return await ReviewService.getReviewCount(workoutId);
    } catch (e) {
      // Fallback ai dati locali
      return getWorkoutReviews(workoutId).length;
    }
  }

  // Inizializza il provider con dati di esempio
  Future<void> initializeWithSampleData() async {
    await ReviewService.seedReviews();
  }

  // METODI PRIVATI DI UTILITÀ

  // Aggiorna una recensione nello stato locale
  Future<void> _updateReviewInLocalState(String reviewId, Review updatedReview) async {
    // Aggiorna nelle user reviews
    for (int i = 0; i < _userReviews.length; i++) {
      if (_userReviews[i].id == reviewId) {
        _userReviews[i] = updatedReview;
        break;
      }
    }

    // Aggiorna nelle workout reviews
    for (final workoutId in _workoutReviews.keys) {
      final reviews = _workoutReviews[workoutId]!;
      for (int i = 0; i < reviews.length; i++) {
        if (reviews[i].id == reviewId) {
          reviews[i] = updatedReview;
          break;
        }
      }
    }
  }

  // Ricalcola la media per un workout
  Future<void> _recalculateAverage(String workoutId) async {
    final reviews = _workoutReviews[workoutId] ?? [];
    if (reviews.isEmpty) {
      _averageRatings[workoutId] = 0.0;
    } else {
      final totalRating = reviews.fold<double>(0, (sum, review) => sum + review.rating);
      _averageRatings[workoutId] = totalRating / reviews.length;
    }
  }

  // Metodi per gestire lo stato
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  // Pulisce gli errori manualmente
  void clearError() {
    _clearError();
    notifyListeners();
  }

  // Pulisce tutti i dati (utile per logout)
  void clear() {
    _workoutReviews.clear();
    _averageRatings.clear();
    _userReviews.clear();
    _clearError();
    notifyListeners();
  }
}
