// lib/models/workout.dart
import 'dart:convert';
import 'exercise.dart';

class Workout {
  final String id;
  final String title;
  final String description;
  final String difficulty;
  final int duration;
  final List<Exercise> exercises;
  final String createdBy;
  final bool isRecommended;
  final DateTime createdAt;

  const Workout({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.duration,
    required this.exercises,
    required this.createdBy,
    required this.isRecommended,
    required this.createdAt,
  });

  /* ---------- serializzazione ---------- */
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'difficulty': difficulty,
      'duration': duration,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'createdBy': createdBy,
      'isRecommended': isRecommended,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Workout.fromMap(Map<String, dynamic> map) {
    return Workout(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      difficulty: map['difficulty'] ?? 'Medio',
      duration: map['duration'] ?? 0,
      exercises: List<Exercise>.from(
        (map['exercises'] ?? []).map((e) => Exercise.fromMap(e)),
      ),
      createdBy: map['createdBy'] ?? '',
      isRecommended: map['isRecommended'] ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());
  factory Workout.fromJson(String source) =>
      Workout.fromMap(json.decode(source));

  /* ---------- metodi di utilità ---------- */

  // Metodo per la ricerca richiesto da workout_service.dart
  bool matchesQuery(String query) {
    final lowerQuery = query.toLowerCase();
    return title.toLowerCase().contains(lowerQuery) ||
        description.toLowerCase().contains(lowerQuery) ||
        difficulty.toLowerCase().contains(lowerQuery) ||
        exercises.any((exercise) => exercise.matches(lowerQuery));
  }

  List<String> validate() {
    final errors = <String>[];

    if (title.isEmpty) errors.add('Titolo vuoto');
    if (description.isEmpty) errors.add('Descrizione vuota');
    if (difficulty.isEmpty) errors.add('Difficoltà non specificata');
    if (duration <= 0) errors.add('Durata deve essere > 0');
    if (exercises.isEmpty) errors.add('Almeno un esercizio richiesto');

    for (int i = 0; i < exercises.length; i++) {
      final exerciseErrors = exercises[i].validate();
      for (final error in exerciseErrors) {
        errors.add('Esercizio ${i + 1}: $error');
      }
    }

    return errors;
  }

  bool get isValid => validate().isEmpty;

  int get estimatedTotalDuration {
    return exercises.fold<int>(
        0, (total, exercise) => total + exercise.estimatedTotalDuration);
  }

  int get totalExercises => exercises.length;

  int get totalSets =>
      exercises.fold(0, (total, exercise) => total + exercise.sets);

  // Factory per creare un workout di esempio
  factory Workout.example() {
    return Workout(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Workout di esempio',
      description: 'Allenamento completo per principianti',
      difficulty: 'Medio',
      duration: 30,
      exercises: [
        Exercise.example(),
        Exercise.example(),
      ],
      createdBy: 'system',
      isRecommended: true,
      createdAt: DateTime.now(),
    );
  }

  // Metodi per gestire gli esercizi
  Workout addExercise(Exercise exercise) {
    final newExercises = List<Exercise>.from(exercises)..add(exercise);
    return copyWith(exercises: newExercises);
  }

  Workout removeExercise(String exerciseId) {
    final newExercises = exercises.where((e) => e.id != exerciseId).toList();
    return copyWith(exercises: newExercises);
  }

  Workout updateExercise(String exerciseId, Exercise updatedExercise) {
    final newExercises =
        exercises.map((e) => e.id == exerciseId ? updatedExercise : e).toList();
    return copyWith(exercises: newExercises);
  }

  @override
  String toString() {
    return 'Workout(id: $id, title: $title, difficulty: $difficulty, exercises: ${exercises.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Workout &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.difficulty == difficulty &&
        other.duration == duration &&
        other.createdBy == createdBy &&
        other.isRecommended == isRecommended &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        description.hashCode ^
        difficulty.hashCode ^
        duration.hashCode ^
        createdBy.hashCode ^
        isRecommended.hashCode ^
        createdAt.hashCode;
  }

  // Aggiungi questo metodo alla classe Workout in lib/models/workout.dart

  Workout copyWith({
    String? id,
    String? title,
    String? description,
    String? difficulty,
    int? duration,
    List<Exercise>? exercises,
    String? createdBy,
    bool? isRecommended,
    DateTime? createdAt,
  }) {
    return Workout(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      duration: duration ?? this.duration,
      exercises: exercises ?? this.exercises,
      createdBy: createdBy ?? this.createdBy,
      isRecommended: isRecommended ?? this.isRecommended,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
