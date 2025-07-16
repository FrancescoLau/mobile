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
  static final _reviews = <Review>[];

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
    return _reviews.where((r) => r.userId == userId && !r.isHidden).toList();
  }

  static Future<List<Review>> getWorkoutReviews(String workoutId) async {
    await Future.delayed(const Duration(milliseconds: 30));
    return _reviews
        .where((r) => r.workoutId == workoutId && !r.isHidden)
        .toList();
  }

  /* ---------- Operazioni CRUD ---------- */

  static Future<bool> addReview(Review review) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      // Verifica se l'utente ha già recensito questo workout
      final existingReview = _reviews.any(
          (r) => r.userId == review.userId && r.workoutId == review.workoutId);

      if (existingReview) {
        return false; // Utente ha già recensito
      }

      // Valida la recensione
      final validationErrors = validateReview(review);
      if (validationErrors.isNotEmpty) {
        return false;
      }

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
        _reviews[index] = review.copyWith(updatedAt: DateTime.now());
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

  static Future<bool> hasUserReviewed(String userId, String workoutId) async {
    await Future.delayed(const Duration(milliseconds: 20));
    return _reviews.any((r) => r.userId == userId && r.workoutId == workoutId);
  }

  /* ---------- Metodi di Ricerca ---------- */

  static Future<Review?> getUserReviewForWorkout(
      String userId, String workoutId) async {
    await Future.delayed(const Duration(milliseconds: 30));
    try {
      return _reviews.firstWhere(
        (r) => r.workoutId == workoutId && r.userId == userId && !r.isHidden,
      );
    } catch (e) {
      return null;
    }
  }

  static Future<List<Review>> searchReviews(String query) async {
    await Future.delayed(const Duration(milliseconds: 50));
    if (query.isEmpty) return [];

    final lowerQuery = query.toLowerCase();
    return _reviews
        .where((r) =>
            !r.isHidden &&
            (r.comment.toLowerCase().contains(lowerQuery) ||
                r.userEmail.toLowerCase().contains(lowerQuery)))
        .toList();
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

    // Calcola distribuzione rating
    final ratingDistribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final review in list) {
      final rating = review.rating.round();
      ratingDistribution[rating] = (ratingDistribution[rating] ?? 0) + 1;
    }

    return ReviewStats(
      avg: avg,
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
    validReviews.sort((a, b) => b.rating.compareTo(a.rating));
    return validReviews.take(limit).toList();
  }

  static List<String> validateReview(Review review) {
    final errors = <String>[];

    if (review.rating < 1.0 || review.rating > 5.0) {
      errors.add('Il rating deve essere tra 1.0 e 5.0');
    }

    if (review.comment.trim().isEmpty) {
      errors.add('Il commento non può essere vuoto');
    }

    if (review.comment.length < 10) {
      errors.add('Il commento deve essere di almeno 10 caratteri');
    }

    if (review.comment.length > 500) {
      errors.add('Il commento non può superare 500 caratteri');
    }

    if (review.userEmail.isEmpty || !review.userEmail.contains('@')) {
      errors.add('Email non valida');
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
}
