// lib/services/review_service.dart
import 'dart:async';
import '../models/review.dart';

class ReviewStats {
  final double avg;
  final int count;
  final Map<int, int> ratingDistribution;

  const ReviewStats({
    required this.avg,
    required this.count,
    this.ratingDistribution = const {},
  });

  double get averageRating => avg;
  int get totalReviews => count;
  bool get hasReviews => count > 0;

  // Percentuale per ogni rating
  double getPercentage(int rating) {
    if (count == 0) return 0.0;
    return (ratingDistribution[rating] ?? 0) / count * 100;
  }
}

class ReviewService {
  static final List<Review> _reviews = [];

  /* ---------- Metodi di Base ---------- */

  static Future<double> calculateAverageRating(String workoutId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final list =
        _reviews.where((r) => r.workoutId == workoutId && !r.isHidden).toList();
    if (list.isEmpty) return 0.0;
    return list.map((e) => e.rating).reduce((a, b) => a + b) / list.length;
  }

  static Future<List<Review>> getUserReviews(String userId) async {
    await Future.delayed(const Duration(milliseconds: 30));
    final userReviews =
        _reviews.where((r) => r.userId == userId && !r.isHidden).toList();
    // CORREZIONE: Ordina per data di creazione (più recenti prima)
    userReviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return userReviews;
  }

  static Future<List<Review>> getWorkoutReviews(String workoutId) async {
    await Future.delayed(const Duration(milliseconds: 30));
    final workoutReviews =
        _reviews.where((r) => r.workoutId == workoutId && !r.isHidden).toList();
    // CORREZIONE: Ordina per data di creazione (più recenti prima)
    workoutReviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return workoutReviews;
  }

  /* ---------- Operazioni CRUD ---------- */

  static Future<bool> addReview(Review review) async {
    // CORREZIONE: Aggiungi delay per consistenza
    await Future.delayed(const Duration(milliseconds: 60));

    try {
      // CORREZIONE: Verifica solo recensioni non nascoste
      final existingReview = _reviews.any((r) =>
          r.userId == review.userId &&
          r.workoutId == review.workoutId &&
          !r.isHidden);

      if (existingReview) {
        return false;
      }

      // Valida la recensione
      final errors = validateReview(review);
      if (errors.isNotEmpty) {
        return false;
      }

      // Aggiungi la recensione
      _reviews.add(review);
      return true;
    } catch (e) {
      print('Errore aggiunta recensione: $e');
      return false;
    }
  }

  static Future<bool> updateReview(Review review) async {
    await Future.delayed(const Duration(milliseconds: 80));
    try {
      final index = _reviews.indexWhere((r) => r.id == review.id);
      if (index != -1) {
        _reviews[index] = review;
        return true;
      }
      return false;
    } catch (e) {
      print('Errore aggiornamento recensione: $e');
      return false;
    }
  }

  static Future<bool> deleteReview(String reviewId) async {
    await Future.delayed(const Duration(milliseconds: 60));
    try {
      final initialLength = _reviews.length;
      _reviews.removeWhere((r) => r.id == reviewId);
      return _reviews.length < initialLength;
    } catch (e) {
      print('Errore eliminazione recensione: $e');
      return false;
    }
  }

  /* ---------- Funzioni di Controllo ---------- */

  static Future<bool> moderateReview(String id, bool hide) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      final index = _reviews.indexWhere((r) => r.id == id);
      if (index != -1) {
        _reviews[index] = _reviews[index].copyWith(
          isHidden: hide,
          updatedAt: DateTime.now(),
        );
        return true;
      }
      return false;
    } catch (e) {
      print('Errore moderazione recensione: $e');
      return false;
    }
  }

  // CORREZIONE: Esclude le recensioni nascoste dal controllo
  static Future<bool> hasUserReviewed(String userId, String workoutId) async {
    await Future.delayed(const Duration(milliseconds: 20));
    return _reviews.any(
        (r) => r.userId == userId && r.workoutId == workoutId && !r.isHidden);
  }

  /* ---------- Metodi di Ricerca ---------- */

  // CORREZIONE: Permette di trovare anche recensioni nascoste per l'editing
  static Future<Review?> getUserReviewForWorkout(
      String userId, String workoutId) async {
    await Future.delayed(const Duration(milliseconds: 30));
    try {
      return _reviews.firstWhere(
        (r) => r.workoutId == workoutId && r.userId == userId,
      );
    } catch (e) {
      return null;
    }
  }

  static Future<List<Review>> searchReviews(String query) async {
    await Future.delayed(const Duration(milliseconds: 50));
    if (query.isEmpty) return [];

    final lowerQuery = query.toLowerCase();
    final searchResults = _reviews
        .where((r) =>
            !r.isHidden &&
            (r.comment.toLowerCase().contains(lowerQuery) ||
                r.userEmail.toLowerCase().contains(lowerQuery)))
        .toList();

    // CORREZIONE: Ordina i risultati per rilevanza/data
    searchResults.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return searchResults;
  }

  /* ---------- Statistiche ---------- */

  static Future<ReviewStats> getWorkoutReviewStats(String workoutId) async {
    await Future.delayed(const Duration(milliseconds: 40));
    final list =
        _reviews.where((r) => r.workoutId == workoutId && !r.isHidden).toList();

    if (list.isEmpty) {
      return const ReviewStats(avg: 0.0, count: 0, ratingDistribution: {});
    }

    final avg = list.map((e) => e.rating).reduce((a, b) => a + b) / list.length;

    // CORREZIONE: Migliore gestione della distribuzione rating
    final ratingDistribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final review in list) {
      final rating = review.rating.round().clamp(1, 5); // Assicura range 1-5
      ratingDistribution[rating] = (ratingDistribution[rating] ?? 0) + 1;
    }

    return ReviewStats(
      avg: double.parse(avg.toStringAsFixed(1)), // Arrotonda a 1 decimale
      count: list.length,
      ratingDistribution: ratingDistribution,
    );
  }

  /* ---------- Metodi di Utilità ---------- */

  static Future<List<Review>> getRecentReviews({int limit = 10}) async {
    await Future.delayed(const Duration(milliseconds: 30));
    final validReviews = _reviews.where((r) => !r.isHidden).toList();
    validReviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return validReviews.take(limit).toList();
  }

  static Future<List<Review>> getTopReviews({int limit = 10}) async {
    await Future.delayed(const Duration(milliseconds: 30));
    final validReviews = _reviews.where((r) => !r.isHidden).toList();
    // CORREZIONE: Prima per rating, poi per data se stesso rating
    validReviews.sort((a, b) {
      final ratingComparison = b.rating.compareTo(a.rating);
      if (ratingComparison != 0) return ratingComparison;
      return b.createdAt.compareTo(a.createdAt);
    });
    return validReviews.take(limit).toList();
  }

  // CORREZIONE: Validazione email migliorata
  static List<String> validateReview(Review review) {
    final errors = <String>[];

    if (review.rating < 1.0 || review.rating > 5.0) {
      errors.add('Il rating deve essere tra 1.0 e 5.0');
    }

    if (review.comment.trim().isEmpty) {
      errors.add('Il commento non può essere vuoto');
    }

    if (review.comment.trim().length > 500) {
      errors.add('Il commento non può superare i 500 caratteri');
    }

    if (review.userEmail.isEmpty) {
      errors.add('Email richiesta');
    }

    return errors;
  }

  /* ---------- Metodi per Testing e Debug ---------- */

  static Future<List<Review>> getAllReviews() async {
    await Future.delayed(const Duration(milliseconds: 20));
    return List<Review>.from(_reviews);
  }

  static Future<void> clearAllReviews() async {
    await Future.delayed(const Duration(milliseconds: 20));
    _reviews.clear();
  }

  static Future<void> seedReviews() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (_reviews.isEmpty) {
      _reviews.addAll([
        Review(
          id: 'review_1',
          workoutId: 'workout_1',
          userId: 'user_1',
          userEmail: 'mario.rossi@example.com',
          rating: 4.5,
          comment:
              'Ottimo allenamento per principianti! Gli esercizi sono ben spiegati e la progressione è graduale.',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          isHidden: false,
        ),
        Review(
          id: 'review_2',
          workoutId: 'workout_1',
          userId: 'user_2',
          userEmail: 'laura.bianchi@example.com',
          rating: 5.0,
          comment:
              'Perfetto per iniziare la giornata! Mi sento più energica dopo questo allenamento.',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          isHidden: false,
        ),
        Review(
          id: 'review_3',
          workoutId: 'workout_2',
          userId: 'user_3',
          userEmail: 'giuseppe.verdi@example.com',
          rating: 3.5,
          comment:
              'Buon allenamento ma un po\' impegnativo per chi è fuori forma. Consiglio di iniziare gradualmente.',
          createdAt: DateTime.now().subtract(const Duration(hours: 12)),
          isHidden: false,
        ),
        Review(
          id: 'review_4',
          workoutId: 'workout_1',
          userId: 'user_4',
          userEmail: 'anna.neri@example.com',
          rating: 4.0,
          comment:
              'Molto utile per mantenersi in forma a casa. Alcuni esercizi sono un po\' ripetitivi.',
          createdAt: DateTime.now().subtract(const Duration(hours: 6)),
          isHidden: false,
        ),
        Review(
          id: 'review_5',
          workoutId: 'workout_2',
          userId: 'user_5',
          userEmail: 'marco.ferrari@example.com',
          rating: 4.8,
          comment:
              'Fantastico! L\'allenamento più completo che abbia mai provato. Consigliatissimo a tutti.',
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
          isHidden: false,
        ),
      ]);
    }
  }

  static Future<int> getReviewCount(String workoutId) async {
    await Future.delayed(const Duration(milliseconds: 20));
    return _reviews
        .where((r) => r.workoutId == workoutId && !r.isHidden)
        .length;
  }

  // Metodo per ottenere recensioni per pagina (paginazione)
  static Future<List<Review>> getReviewsPage(String workoutId,
      {int page = 1, int limit = 10}) async {
    await Future.delayed(const Duration(milliseconds: 40));
    final workoutReviews =
        _reviews.where((r) => r.workoutId == workoutId && !r.isHidden).toList();

    workoutReviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final startIndex = (page - 1) * limit;
    final endIndex = startIndex + limit;

    if (startIndex >= workoutReviews.length) return [];

    return workoutReviews.sublist(
      startIndex,
      endIndex > workoutReviews.length ? workoutReviews.length : endIndex,
    );
  }

  // CORREZIONE: Metodo per ottenere statistiche semplici (compatibilità con ReviewProvider)
  static Future<Map<String, dynamic>> getWorkoutStats(String workoutId) async {
    await Future.delayed(const Duration(milliseconds: 40));

    try {
      final reviews = _reviews
          .where((r) => r.workoutId == workoutId && !r.isHidden)
          .toList();

      if (reviews.isEmpty) {
        return {'rating': 0.0, 'count': 0};
      }

      double totalRating = 0;
      for (var review in reviews) {
        totalRating += review.rating;
      }

      final average = totalRating / reviews.length;

      return {
        'rating': double.parse(average.toStringAsFixed(1)),
        'count': reviews.length
      };
    } catch (e) {
      print('Errore nel calcolo delle statistiche: $e');
      return {'rating': 0.0, 'count': 0};
    }
  }

  /* ---------- Metodi Aggiuntivi di Utilità ---------- */

  // NUOVO: Metodo per ottenere recensioni di un utente per un workout specifico (incluse nascoste)
  static Future<Review?> getUserReviewForWorkoutIncludeHidden(
      String userId, String workoutId) async {
    await Future.delayed(const Duration(milliseconds: 30));
    try {
      return _reviews.firstWhere(
        (r) => r.workoutId == workoutId && r.userId == userId,
      );
    } catch (e) {
      return null;
    }
  }

  // NUOVO: Metodo per verificare se ci sono recensioni moderate per un workout
  static Future<bool> hasModeratedReviews(String workoutId) async {
    await Future.delayed(const Duration(milliseconds: 20));
    return _reviews.any((r) => r.workoutId == workoutId && r.isHidden);
  }

  // NUOVO: Metodo per ottenere il numero di recensioni moderate
  static Future<int> getModeratedReviewCount(String workoutId) async {
    await Future.delayed(const Duration(milliseconds: 20));
    return _reviews.where((r) => r.workoutId == workoutId && r.isHidden).length;
  }
}
