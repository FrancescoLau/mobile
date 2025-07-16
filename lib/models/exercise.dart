// lib/models/exercise.dart
import 'dart:convert';

class Exercise {
  final String id;
  final String name;
  final String description;
  final int sets;
  final int reps;
  final int duration; // secondi facoltativi
  final int? weight; // Peso opzionale per compatibilità
  final String? notes; // Note opzionali
  final DateTime createdAt; // Richiesto per compatibilità

  const Exercise({
    required this.id,
    required this.name,
    required this.description,
    required this.sets,
    required this.reps,
    required this.duration,
    this.weight,
    this.notes,
    required this.createdAt,
  });

  /* ---------- serializzazione ---------- */
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'sets': sets,
        'reps': reps,
        'duration': duration,
        'weight': weight,
        'notes': notes,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory Exercise.fromMap(Map<String, dynamic> map) => Exercise(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        description: map['description'] ?? '',
        sets: map['sets'] ?? 0,
        reps: map['reps'] ?? 0,
        duration: map['duration'] ?? 0,
        weight: map['weight'],
        notes: map['notes'],
        createdAt: map['createdAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
            : DateTime.now(),
      );

  String toJson() => json.encode(toMap());
  factory Exercise.fromJson(String source) =>
      Exercise.fromMap(json.decode(source));

  /* ---------- utilità per ricerca & validazione ---------- */
  bool matches(String query) =>
      name.toLowerCase().contains(query.toLowerCase()) ||
      description.toLowerCase().contains(query.toLowerCase());

  List<String> validate() {
    final errors = <String>[];
    if (name.isEmpty) errors.add('Nome vuoto');
    if (sets <= 0) errors.add('Serie deve essere > 0');
    if (reps <= 0 && duration <= 0) {
      errors.add('Serve almeno ripetizioni o durata');
    }
    return errors;
  }

  bool isEquivalentTo(Exercise other) =>
      name == other.name &&
      sets == other.sets &&
      reps == other.reps &&
      duration == other.duration;

  /* ---------- metodi aggiuntivi per compatibilità ---------- */

  Exercise copyWith({
    String? id,
    String? name,
    String? description,
    int? sets,
    int? reps,
    int? duration,
    int? weight,
    String? notes,
    DateTime? createdAt,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      duration: duration ?? this.duration,
      weight: weight ?? this.weight,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Exercise.example() {
    return Exercise(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Esercizio di esempio',
      description: 'Descrizione dell\'esercizio',
      sets: 3,
      reps: 10,
      duration: 180,
      weight: null,
      notes: 'Note aggiuntive',
      createdAt: DateTime.now(),
    );
  }

  bool get isValid => validate().isEmpty;

  // ✅ GETTER RICHIESTO DAL WORKOUT MODEL
  int get estimatedTotalDuration {
    // Se c'è una durata specifica, usala
    if (duration > 0) return duration;

    // Altrimenti stima: 2 secondi per rep + 30 secondi di riposo tra set
    return (sets * reps * 2) + ((sets - 1) * 30);
  }

  @override
  String toString() {
    return 'Exercise(id: $id, name: $name, sets: $sets, reps: $reps, duration: $duration)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Exercise &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.sets == sets &&
        other.reps == reps &&
        other.duration == duration &&
        other.weight == weight &&
        other.notes == notes;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        description.hashCode ^
        sets.hashCode ^
        reps.hashCode ^
        duration.hashCode ^
        weight.hashCode ^
        notes.hashCode;
  }
}
