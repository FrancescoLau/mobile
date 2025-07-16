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

  // Ottieni recensioni per un allenamento specifico
  List<Review> getWorkoutReviews(String workoutId) {
    return List.unmodifiable(_workoutReviews[workoutId] ?? []);
  }

  // Ottieni rating medio per un allenamento
  double getAverageRating(String workoutId) {
    final reviews = _workoutReviews[workoutId] ?? [];
    if (reviews.isEmpty) return 0.0;

    final totalRating =
        reviews.fold<double>(0, (sum, review) => sum + review.rating);
    return totalRating / reviews.length;
  }

  // Carica recensioni per un allenamento (integrato con ReviewService)
  Future<void> loadWorkoutReviews(String workoutId) async {
    _setLoading(true);
    _clearError();

    try {
      // Usa il ReviewService per caricare le recensioni
      final reviews = await ReviewService.getWorkoutReviews(workoutId);
      final averageRating =
          await ReviewService.calculateAverageRating(workoutId);

      _workoutReviews[workoutId] = reviews;
      _averageRatings[workoutId] = averageRating;

      notifyListeners();
    } catch (e) {
      _setError('Errore durante il caricamento delle recensioni: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Carica recensioni dell'utente corrente (integrato con ReviewService)
  Future<void> loadUserReviews(String userId) async {
    _setLoading(true);
    _clearError();

    try {
      // Usa il ReviewService per caricare le recensioni dell'utente
      _userReviews = await ReviewService.getUserReviews(userId);
      notifyListeners();
    } catch (e) {
      _setError('Errore durante il caricamento delle tue recensioni: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Aggiungi recensione (integrato con ReviewService)
  Future<bool> addReview(
      String workoutId, String userId, double rating, String comment) async {
    if (rating < 1 || rating > 5) {
      _setError('Il rating deve essere compreso tra 1 e 5');
      return false;
    }

    if (comment.trim().isEmpty) {
      _setError('Il commento non può essere vuoto');
      return false;
    }

    // Verifica se l'utente ha già recensito
    final hasReviewed = await ReviewService.hasUserReviewed(userId, workoutId);
    if (hasReviewed) {
      _setError('Hai già recensito questo allenamento');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final newReview = Review(
        id: 'review_${DateTime.now().millisecondsSinceEpoch}',
        workoutId: workoutId,
        userId: userId,
        userEmail: 'user@example.com',
        rating: rating,
        comment: comment,
        createdAt: DateTime.now(),
        isHidden: false,
      );

      // Usa il ReviewService per aggiungere la recensione
      final success = await ReviewService.addReview(newReview);

      if (success) {
        // Ricarica i dati per aggiornare lo stato locale
        await loadWorkoutReviews(workoutId);
        await loadUserReviews(userId);
        return true;
      } else {
        _setError('Errore durante l\'aggiunta della recensione');
        return false;
      }
    } catch (e) {
      _setError('Errore durante l\'aggiunta della recensione: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Aggiorna recensione (integrato con ReviewService)
  Future<bool> updateReview(
      String reviewId, double rating, String comment) async {
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
      // Trova la recensione esistente
      Review? existingReview;
      for (final review in _userReviews) {
        if (review.id == reviewId) {
          existingReview = review;
          break;
        }
      }

      if (existingReview == null) {
        _setError('Recensione non trovata');
        return false;
      }

      final updatedReview = existingReview.copyWith(
        rating: rating,
        comment: comment,
        updatedAt: DateTime.now(),
      );

      // Usa il ReviewService per aggiornare la recensione
      final success = await ReviewService.updateReview(updatedReview);

      if (success) {
        // Ricarica i dati per aggiornare lo stato locale
        await loadWorkoutReviews(existingReview.workoutId);
        await loadUserReviews(existingReview.userId);
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

  // Elimina recensione (integrato con ReviewService)
  Future<bool> deleteReview(String reviewId) async {
    _setLoading(true);
    _clearError();

    try {
      // Trova la recensione da eliminare per ottenere workoutId e userId
      Review? reviewToDelete;
      for (final review in _userReviews) {
        if (review.id == reviewId) {
          reviewToDelete = review;
          break;
        }
      }

      if (reviewToDelete == null) {
        _setError('Recensione non trovata');
        return false;
      }

      // Usa il ReviewService per eliminare la recensione
      final success = await ReviewService.deleteReview(reviewId);

      if (success) {
        // Ricarica i dati per aggiornare lo stato locale
        await loadWorkoutReviews(reviewToDelete.workoutId);
        await loadUserReviews(reviewToDelete.userId);
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

  // Modera recensione (solo admin) - integrato con ReviewService
  Future<bool> moderateReview(String reviewId, bool hide) async {
    _setLoading(true);
    _clearError();

    try {
      // Usa il ReviewService per moderare la recensione
      final success = await ReviewService.moderateReview(reviewId, hide);

      if (success) {
        // Trova e aggiorna la recensione localmente
        for (final workoutId in _workoutReviews.keys) {
          final reviews = _workoutReviews[workoutId]!;
          for (int i = 0; i < reviews.length; i++) {
            if (reviews[i].id == reviewId) {
              reviews[i] = reviews[i].copyWith(isHidden: hide);
              break;
            }
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

  // Verifica se l'utente ha già recensito un allenamento (integrato con ReviewService)
  Future<bool> hasUserReviewed(String userId, String workoutId) async {
    try {
      return await ReviewService.hasUserReviewed(userId, workoutId);
    } catch (e) {
      return false;
    }
  }

  // Ottieni la recensione dell'utente per un allenamento (integrato con ReviewService)
  Future<Review?> getUserReviewForWorkout(
      String userId, String workoutId) async {
    try {
      return await ReviewService.getUserReviewForWorkout(userId, workoutId);
    } catch (e) {
      return null;
    }
  }

  // Ottieni statistiche recensioni (integrato con ReviewService)
  Future<Map<String, dynamic>> getWorkoutReviewStats(String workoutId) async {
    try {
      final stats = await ReviewService.getWorkoutReviewStats(workoutId);
      return {
        'totalReviews': stats.totalReviews,
        'averageRating': stats.averageRating,
        'ratingDistribution': stats.ratingDistribution,
      };
    } catch (e) {
      return {
        'totalReviews': 0,
        'averageRating': 0.0,
        'ratingDistribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
      };
    }
  }

  // Cerca recensioni (integrato con ReviewService)
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

  // Metodi privati per gestire lo stato
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
  }

  // Pulisce tutti i dati (utile per logout)
  void clear() {
    _workoutReviews.clear();
    _averageRatings.clear();
    _userReviews.clear();
    _clearError();
    notifyListeners();
  }

  // Metodi di utilità aggiuntivi

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
      return 0;
    }
  }

  // Inizializza il provider con dati di esempio
  Future<void> initializeWithSampleData() async {
    await ReviewService.seedReviews();
  }
}
