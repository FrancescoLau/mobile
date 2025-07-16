// lib/services/workout_service.dart

import '../models/workout.dart';
import '../models/exercise.dart';

class WorkoutService {
  static final List<Workout> _workouts = [
    // SOLO ALLENAMENTI CONSIGLIATI (RIMOSSI QUELLI PERSONALI)
    Workout(
      id: '1',
      title: 'Allenamento Base',
      description: 'Perfetto per principianti',
      difficulty: 'Facile',
      duration: 30,
      createdBy: 'admin',
      isRecommended: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      exercises: [
        Exercise(
          id: '1',
          name: 'Push-up',
          description: 'Esercizio per petto e tricipiti',
          sets: 3,
          reps: 10,
          duration: 0,
          createdAt: DateTime.now(),
        ),
        Exercise(
          id: '2',
          name: 'Squat',
          description: 'Esercizio per gambe e glutei',
          sets: 3,
          reps: 12,
          duration: 0,
          createdAt: DateTime.now(),
        ),
      ],
    ),
    Workout(
      id: '2',
      title: 'Allenamento Avanzato',
      description: 'Per atleti esperti',
      difficulty: 'Difficile',
      duration: 60,
      createdBy: 'admin',
      isRecommended: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      exercises: [
        Exercise(
          id: '3',
          name: 'Burpees',
          description: 'Esercizio completo per tutto il corpo',
          sets: 4,
          reps: 8,
          duration: 0,
          createdAt: DateTime.now(),
        ),
        Exercise(
          id: '4',
          name: 'Pull-up',
          description: 'Esercizio per schiena e bicipiti',
          sets: 3,
          reps: 6,
          duration: 0,
          createdAt: DateTime.now(),
        ),
      ],
    ),
    Workout(
      id: '5',
      title: 'Cardio Leggero',
      description: 'Allenamento cardio per tutti i livelli',
      difficulty: 'Medio',
      duration: 40,
      createdBy: 'admin',
      isRecommended: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      exercises: [
        Exercise(
          id: '5',
          name: 'Jumping Jacks',
          description: 'Salti sul posto per riscaldamento',
          sets: 3,
          reps: 20,
          duration: 0,
          createdAt: DateTime.now(),
        ),
        Exercise(
          id: '6',
          name: 'Mountain Climbers',
          description: 'Esercizio cardio e core',
          sets: 3,
          reps: 15,
          duration: 0,
          createdAt: DateTime.now(),
        ),
      ],
    ),
  ];

  static Future<Workout?> getWorkoutById(String workoutId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _workouts.firstWhere((w) => w.id == workoutId);
    } catch (e) {
      return null;
    }
  }

  static Future<List<Workout>> getAllWorkouts() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_workouts);
  }

  static Future<List<Workout>> getRecommendedWorkouts() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _workouts.where((w) => w.isRecommended).toList();
  }

  static Future<List<Workout>> getPersonalWorkouts() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _workouts.where((w) => !w.isRecommended).toList();
  }

  static Future<List<Workout>> searchWorkouts(String query) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (query.isEmpty) return [];
    final allWorkouts = await getAllWorkouts();
    return allWorkouts.where((w) => w.matchesQuery(query)).toList();
  }

  static Future<bool> addWorkout(Workout workout) async {
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      _workouts.add(workout);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateWorkout(Workout workout) async {
    await Future.delayed(const Duration(milliseconds: 400));
    try {
      final index = _workouts.indexWhere((w) => w.id == workout.id);
      if (index != -1) {
        _workouts[index] = workout;
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteWorkout(String workoutId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      _workouts.removeWhere((w) => w.id == workoutId);
      return true;
    } catch (e) {
      return false;
    }
  }
}
