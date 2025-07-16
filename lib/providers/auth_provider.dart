// lib/providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  // Stato privato
  bool _isLoading = false;
  String? _errorMessage;
  User? _currentUser;

  // Getter per lo stato
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _currentUser;

  // Getter delegati all'AuthService con fallback locale
  bool get isLoggedIn => _currentUser != null || AuthService.isLoggedIn;
  bool get isAdmin => _currentUser?.isAdmin ?? AuthService.isAdmin;
  String? get currentUserId => _currentUser?.id ?? AuthService.currentUserId;
  String? get currentUserEmail =>
      _currentUser?.email ?? AuthService.currentUserEmail;
  String? get currentUserRole =>
      _currentUser?.role ?? AuthService.currentUserRole;
  String? get currentUsername =>
      _currentUser?.username ?? AuthService.currentUsername;

  // Inizializzazione del provider
  AuthProvider() {
    _initializeAuthState();
  }

  // Inizializza lo stato di autenticazione
  Future<void> _initializeAuthState() async {
    _setLoading(true);

    try {
      // Verifica se c'è una sessione attiva
      if (AuthService.isLoggedIn) {
        _currentUser = await AuthService.getCurrentUser();
        notifyListeners();
      }
    } catch (e) {
      print('Errore durante l\'inizializzazione: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Login
  Future<bool> login(String email, String password) async {
    // Validazione input
    if (email.isEmpty || password.isEmpty) {
      _setError('Email e password sono richiesti');
      return false;
    }

    if (!_isValidEmail(email)) {
      _setError('Email non valida');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final result = await AuthService.login(email, password);

      if (result.success) {
        _currentUser = await AuthService.getCurrentUser();
        notifyListeners();
        return true;
      } else {
        _setError(result.message);
        return false;
      }
    } catch (e) {
      _setError('Errore imprevisto durante il login: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Login con username
  Future<bool> loginWithUsername(String username, String password) async {
    if (username.isEmpty || password.isEmpty) {
      _setError('Username e password sono richiesti');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final result = await AuthService.loginWithUsername(username, password);

      if (result.success) {
        _currentUser = await AuthService.getCurrentUser();
        notifyListeners();
        return true;
      } else {
        _setError(result.message);
        return false;
      }
    } catch (e) {
      _setError('Errore imprevisto durante il login: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Registrazione
  Future<bool> register(String email, String password,
      {String? username}) async {
    // Validazione input
    if (email.isEmpty || password.isEmpty) {
      _setError('Email e password sono richiesti');
      return false;
    }

    if (!_isValidEmail(email)) {
      _setError('Email non valida');
      return false;
    }

    if (password.length < 6) {
      _setError('La password deve essere di almeno 6 caratteri');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final result =
          await AuthService.register(email, password, username: username);

      if (result.success) {
        _currentUser = await AuthService.getCurrentUser();
        notifyListeners();
        return true;
      } else {
        _setError(result.message);
        return false;
      }
    } catch (e) {
      _setError('Errore imprevisto durante la registrazione: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Logout
  Future<void> logout() async {
    _setLoading(true);
    _clearError();

    try {
      await AuthService.logout();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _setError('Errore durante il logout: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Verifica permessi
  bool hasPermission(String permission) {
    try {
      return AuthService.hasPermission(permission);
    } catch (e) {
      return false;
    }
  }

  // Metodi specifici per la Workout App
  bool canManageDifficulty() {
    return isAdmin || hasPermission('manage_difficulty');
  }

  bool canModerateReviews() {
    return isAdmin || hasPermission('moderate_reviews');
  }

  bool canCreateRecommendedWorkouts() {
    return isAdmin || hasPermission('create_recommended_workout');
  }

  // Aggiornamento profilo
  Future<bool> updateProfile({String? username, String? email}) async {
    if (_currentUser == null) {
      _setError('Utente non autenticato');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final result = await AuthService.updateProfile(
        userId: _currentUser!.id,
        username: username,
        email: email,
      );

      if (result.success) {
        _currentUser = await AuthService.getCurrentUser();
        notifyListeners();
        return true;
      } else {
        _setError(result.message);
        return false;
      }
    } catch (e) {
      _setError('Errore durante l\'aggiornamento del profilo: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Cambio password
  Future<bool> changePassword(
      String currentPassword, String newPassword) async {
    if (_currentUser == null) {
      _setError('Utente non autenticato');
      return false;
    }

    if (newPassword.length < 6) {
      _setError('La nuova password deve essere di almeno 6 caratteri');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final result = await AuthService.changePassword(
        userId: _currentUser!.id,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (result.success) {
        return true;
      } else {
        _setError(result.message);
        return false;
      }
    } catch (e) {
      _setError('Errore durante il cambio password: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Refresh dati utente
  Future<void> refreshUserData() async {
    if (!isLoggedIn) return;

    _setLoading(true);

    try {
      _currentUser = await AuthService.getCurrentUser();
      notifyListeners();
    } catch (e) {
      _setError('Errore durante l\'aggiornamento dei dati utente: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Verifica validità sessione
  Future<bool> isSessionValid() async {
    try {
      return await AuthService.isSessionValid();
    } catch (e) {
      return false;
    }
  }

  // Rinnova sessione
  Future<bool> renewSession() async {
    if (!isLoggedIn) return false;

    _setLoading(true);

    try {
      final result = await AuthService.renewSession();
      if (result.success) {
        _currentUser = await AuthService.getCurrentUser();
        notifyListeners();
        return true;
      } else {
        _setError(result.message);
        return false;
      }
    } catch (e) {
      _setError('Errore durante il rinnovo della sessione: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Metodi di utilità
  bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);
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
    _currentUser = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  // Ottieni permessi utente corrente
  List<String> getCurrentUserPermissions() {
    try {
      return AuthService.getCurrentUserPermissions();
    } catch (e) {
      return [];
    }
  }

  // Informazioni sessione
  Map<String, dynamic> getSessionInfo() {
    return {
      'isLoggedIn': isLoggedIn,
      'isAdmin': isAdmin,
      'userId': currentUserId,
      'userEmail': currentUserEmail,
      'userRole': currentUserRole,
      'username': currentUsername,
      'sessionValid': isLoggedIn,
    };
  }
}
