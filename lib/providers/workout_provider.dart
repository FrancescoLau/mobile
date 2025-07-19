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
  bool get isAdmin => _isAdmin;

  // GETTER CORRETTI PER ALLENAMENTI FILTRATI CON RICERCA E DIFFICOLTÀ
  List<Workout> get filteredRecommendedWorkouts {
    List<Workout> baseList =
        _searchQuery.isEmpty ? _recommendedWorkouts : _searchResults;
    baseList = baseList.where((w) => w.isRecommended).toList();

    if (_selectedDifficulty == null ||
        _selectedDifficulty!.isEmpty ||
        _selectedDifficulty == 'Tutte') {
      return baseList;
    }

    return baseList
        .where((w) =>
            w.difficulty.toLowerCase() == _selectedDifficulty!.toLowerCase())
        .toList();
  }

  List<Workout> get filteredPersonalWorkouts {
    List<Workout> baseList =
        _searchQuery.isEmpty ? _personalWorkouts : _searchResults;
    baseList = baseList.where((w) => !w.isRecommended).toList();

    if (_selectedDifficulty == null ||
        _selectedDifficulty!.isEmpty ||
        _selectedDifficulty == 'Tutte') {
      return baseList;
    }

    return baseList
        .where((w) =>
            w.difficulty.toLowerCase() == _selectedDifficulty!.toLowerCase())
        .toList();
  }

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

  // Metodo per filtrare per difficoltà
  void filterByDifficulty(String? difficulty) {
    _selectedDifficulty = difficulty;
    notifyListeners();
  }

  // Metodo per pulire i filtri
  void clearFilters() {
    _selectedDifficulty = null;
    notifyListeners();
  }

  // Metodo per la ricerca
  Future<void> searchWorkouts(String query) async {
    _searchQuery = query.toLowerCase();
    if (query.isEmpty) {
      _searchResults.clear();
      notifyListeners();
      return;
    }

    _setLoading(true);
    _clearError();
    try {
      // Cerca in entrambe le liste (consigliati e personali)
      final allWorkouts = [..._recommendedWorkouts, ..._personalWorkouts];
      _searchResults = allWorkouts
          .where((workout) =>
              workout.title.toLowerCase().contains(_searchQuery) ||
              workout.description.toLowerCase().contains(_searchQuery))
          .toList();

      notifyListeners();
    } catch (e) {
      _setError('Errore durante la ricerca: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Metodo per pulire la ricerca
  void clearSearch() {
    _searchQuery = '';
    _searchResults.clear();
    notifyListeners();
  }

  // METODO CORRETTO PER APPLICARE RICERCA E FILTRO INSIEME
  void applySearchAndFilter(String query, String? difficulty) {
    if (query.trim().isNotEmpty) {
      searchWorkouts(query);
    } else {
      clearSearch();
    }

    filterByDifficulty(difficulty);
  }

  // METODO CORRETTO PER AGGIUNGERE WORKOUT CONSIGLIATO
  Future<void> addRecommendedWorkout(Workout workout,
      {String? userEmail}) async {
    _setLoading(true);
    _clearError();
    try {
      Workout processedWorkout;
      if (isAdmin) {
        processedWorkout = workout.copyWith(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          createdAt: DateTime.now(),
          isRecommended: true,
          createdBy: userEmail ?? 'admin', // CAMPO CREATEDBY CORRETTO
        );
      } else {
        processedWorkout = workout.copyWith(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          createdAt: DateTime.now(),
          isRecommended: true,
          difficulty: 'Medio',
          createdBy: userEmail ?? '', // CAMPO CREATEDBY CORRETTO
        );
      }

      await WorkoutService.addWorkout(processedWorkout);
      _recommendedWorkouts.add(processedWorkout);
      notifyListeners();
    } catch (e) {
      _setError('Errore durante l\'aggiunta dell\'allenamento: $e');
    } finally {
      _setLoading(false);
    }
  }

  // METODO CORRETTO PER AGGIUNGERE WORKOUT PERSONALE
  Future<void> addPersonalWorkout(Workout workout, {String? userEmail}) async {
    _setLoading(true);
    _clearError();
    try {
      Workout processedWorkout;
      if (isAdmin) {
        processedWorkout = workout.copyWith(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          createdAt: DateTime.now(),
          isRecommended: false,
          createdBy: userEmail ?? 'admin', // CAMPO CREATEDBY CORRETTO
        );
      } else {
        processedWorkout = workout.copyWith(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          createdAt: DateTime.now(),
          isRecommended: false,
          difficulty: 'Medio',
          createdBy: userEmail ?? '', // CAMPO CREATEDBY CORRETTO
        );
      }

      await WorkoutService.addWorkout(processedWorkout);
      _personalWorkouts.add(processedWorkout);
      notifyListeners();
    } catch (e) {
      _setError('Errore durante l\'aggiunta dell\'allenamento: $e');
    } finally {
      _setLoading(false);
    }
  }

  // METODO CORRETTO PER AGGIORNARE WORKOUT
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

      await WorkoutService.updateWorkout(processedWorkout);
      _updateWorkoutInList(processedWorkout);
      notifyListeners();
    } catch (e) {
      _setError('Errore durante l\'aggiornamento dell\'allenamento: $e');
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

  // METODO CORRETTO PER ELIMINARE WORKOUT
  Future<void> deleteWorkout(String workoutId) async {
    _setLoading(true);
    _clearError();
    try {
      await WorkoutService.deleteWorkout(workoutId);
      _recommendedWorkouts.removeWhere((w) => w.id == workoutId);
      _personalWorkouts.removeWhere((w) => w.id == workoutId);
      notifyListeners();
    } catch (e) {
      _setError('Errore durante l\'eliminazione dell\'allenamento: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Metodi alias per compatibilità CON SUPPORTO USEREMAIL
  Future<bool> createRecommendedWorkout(Workout workout,
      {String? userEmail}) async {
    try {
      await addRecommendedWorkout(workout, userEmail: userEmail);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> createPersonalWorkout(Workout workout,
      {String? userEmail}) async {
    try {
      await addPersonalWorkout(workout, userEmail: userEmail);
      return true;
    } catch (e) {
      return false;
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
