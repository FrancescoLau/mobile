// lib/providers/workout_provider.dart
import 'package:flutter/foundation.dart';
import '../models/workout.dart';
import '../services/workout_service.dart';

class WorkoutProvider extends ChangeNotifier {
  // Stato privato
  bool _isLoading = false;
  String? _errorMessage;
  List<Workout> _recommendedWorkouts = [];
  List<Workout> _personalWorkouts = [];
  List<Workout> _searchResults = [];
  String _searchQuery = '';
  String? _selectedDifficulty;

  List<Workout> _allWorkouts = []; // contiene tutti gli allenamenti caricati

  // Riferimento per controllo admin
  bool _isAdmin = false;

  // Getter per lo stato
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Workout> get recommendedWorkouts =>
      List.unmodifiable(_recommendedWorkouts);
  List<Workout> get personalWorkouts => List.unmodifiable(_personalWorkouts);
  List<Workout> get searchResults => List.unmodifiable(_searchResults);
  String get searchQuery => _searchQuery;
  String? get selectedDifficulty => _selectedDifficulty;

  // Getter per controllo admin
  bool get isAdmin => _isAdmin;

  // Setter per controllo admin
  void setAdminStatus(bool isAdmin) {
    _isAdmin = isAdmin;
    notifyListeners();
  }

  // Caricamento iniziale dei workout
  Future<void> loadWorkouts() async {
    _setLoading(true);
    _clearError();

    try {
      final recommended = await WorkoutService.getRecommendedWorkouts();
      final personal = await WorkoutService.getPersonalWorkouts();

      _recommendedWorkouts = recommended;
      _personalWorkouts = personal;

      notifyListeners();
    } catch (e) {
      _setError('Errore durante il caricamento degli allenamenti: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Aggiunta workout consigliato
  Future<void> addRecommendedWorkout(Workout workout) async {
    _setLoading(true);
    _clearError();

    try {
      Workout processedWorkout;

      if (isAdmin) {
        processedWorkout = workout.copyWith(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          createdAt: DateTime.now(),
          isRecommended: true,
        );
      } else {
        processedWorkout = workout.copyWith(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          createdAt: DateTime.now(),
          isRecommended: true,
          difficulty: 'Medio',
        );
      }

      _recommendedWorkouts.add(processedWorkout);
      notifyListeners();
    } catch (e) {
      _setError('Errore durante l\'aggiunta dell\'allenamento: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Aggiunta workout personale
  Future<void> addPersonalWorkout(Workout workout) async {
    _setLoading(true);
    _clearError();

    try {
      Workout processedWorkout;

      if (isAdmin) {
        processedWorkout = workout.copyWith(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          createdAt: DateTime.now(),
          isRecommended: false,
        );
      } else {
        processedWorkout = workout.copyWith(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          createdAt: DateTime.now(),
          isRecommended: false,
          difficulty: 'Medio',
        );
      }

      _personalWorkouts.add(processedWorkout);
      notifyListeners();
    } catch (e) {
      _setError('Errore durante l\'aggiunta dell\'allenamento: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Aggiornamento workout
  Future<void> updateWorkout(Workout workout) async {
    _setLoading(true);
    _clearError();

    try {
      Workout processedWorkout;

      if (isAdmin) {
        processedWorkout = workout.copyWith(
          createdAt: workout.createdAt,
        );
      } else {
        processedWorkout = workout.copyWith(
          createdAt: workout.createdAt,
          difficulty: 'Medio',
        );
      }

      _updateWorkoutInList(processedWorkout);
      notifyListeners();
    } catch (e) {
      _setError('Errore durante l\'aggiornamento dell\'allenamento: $e');
    } finally {
      _setLoading(false);
    }
  }

  // METODI MANCANTI RICHIESTI DALLE SCHERMATE

  // Metodo per pulire la ricerca
  void clearSearch() {
    _searchQuery = '';
    _searchResults.clear();
    notifyListeners();
  }

  List<Workout> get filteredWorkouts {
    if (_selectedDifficulty == null || _selectedDifficulty!.isEmpty) {
      return _allWorkouts;
    }
    return _allWorkouts
        .where((w) =>
            w.difficulty.toLowerCase() == _selectedDifficulty!.toLowerCase())
        .toList();
  }

  // Metodo per filtrare per difficoltà
  void filterByDifficulty(String? difficulty) {
    _selectedDifficulty = difficulty;
    if (difficulty == null || difficulty.isEmpty || difficulty == 'Tutte') {
      _searchResults = [..._recommendedWorkouts, ..._personalWorkouts];
    } else {
      _searchResults = [..._recommendedWorkouts, ..._personalWorkouts]
          .where((w) => w.difficulty.toLowerCase() == difficulty.toLowerCase())
          .toList();
    }
    notifyListeners();
  }

  // Metodo per creare workout consigliato (alias per addRecommendedWorkout)
  Future<bool> createRecommendedWorkout(Workout workout) async {
    try {
      await addRecommendedWorkout(workout);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Metodo per creare workout personale (alias per addPersonalWorkout)
  Future<bool> createPersonalWorkout(Workout workout) async {
    try {
      await addPersonalWorkout(workout);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Metodo per la ricerca
  Future<void> searchWorkouts(String query) async {
    _searchQuery = query;

    if (query.isEmpty) {
      _searchResults.clear();
      notifyListeners();
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      final results = await WorkoutService.searchWorkouts(query);
      _searchResults = results;
      notifyListeners();
    } catch (e) {
      _setError('Errore durante la ricerca: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Metodo per aggiornare workout nella lista appropriata
  void _updateWorkoutInList(Workout workout) {
    if (workout.isRecommended) {
      final index = _recommendedWorkouts.indexWhere((w) => w.id == workout.id);
      if (index != -1) {
        _recommendedWorkouts[index] = workout;
      }
    } else {
      final index = _personalWorkouts.indexWhere((w) => w.id == workout.id);
      if (index != -1) {
        _personalWorkouts[index] = workout;
      }
    }
  }

  // Eliminazione workout
  Future<void> deleteWorkout(String workoutId) async {
    _setLoading(true);
    _clearError();

    try {
      _recommendedWorkouts.removeWhere((w) => w.id == workoutId);
      _personalWorkouts.removeWhere((w) => w.id == workoutId);

      notifyListeners();
    } catch (e) {
      _setError('Errore durante l\'eliminazione dell\'allenamento: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Refresh dati
  Future<void> refresh() async {
    await loadWorkouts();
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
    notifyListeners();
  }

  // Pulisce tutti i dati
  void clear() {
    _recommendedWorkouts.clear();
    _personalWorkouts.clear();
    _searchResults.clear();
    _searchQuery = '';
    _selectedDifficulty = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
