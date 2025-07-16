// lib/models/review.dart
class Review {
  final String id;
  final String workoutId;
  final String userId;
  final String userEmail;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isHidden;

  const Review({
    required this.id,
    required this.workoutId,
    required this.userId,
    required this.userEmail,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.updatedAt,
    required this.isHidden,
  });

  // Metodo copyWith per creare copie modificate
  Review copyWith({
    String? id,
    String? workoutId,
    String? userId,
    String? userEmail,
    double? rating,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isHidden,
  }) {
    return Review(
      id: id ?? this.id,
      workoutId: workoutId ?? this.workoutId,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isHidden: isHidden ?? this.isHidden,
    );
  }

  // Serializzazione JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workoutId': workoutId,
      'userId': userId,
      'userEmail': userEmail,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isHidden': isHidden,
    };
  }

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      workoutId: json['workoutId'],
      userId: json['userId'],
      userEmail: json['userEmail'],
      rating: json['rating'].toDouble(),
      comment: json['comment'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      isHidden: json['isHidden'] ?? false,
    );
  }

  // Validazione
  bool get isValid {
    return id.isNotEmpty &&
        workoutId.isNotEmpty &&
        userId.isNotEmpty &&
        userEmail.isNotEmpty &&
        rating >= 1.0 &&
        rating <= 5.0 &&
        comment.trim().isNotEmpty;
  }

  // Metodo per formattare la data
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} giorni fa';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ore fa';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minuti fa';
    } else {
      return 'Ora';
    }
  }

  // Rating come numero di stelle
  String get starRating {
    return '★' * rating.round() + '☆' * (5 - rating.round());
  }

  @override
  String toString() {
    return 'Review(id: $id, workoutId: $workoutId, userId: $userId, rating: $rating)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Review &&
        other.id == id &&
        other.workoutId == workoutId &&
        other.userId == userId &&
        other.rating == rating &&
        other.comment == comment;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        workoutId.hashCode ^
        userId.hashCode ^
        rating.hashCode ^
        comment.hashCode;
  }
}
