// lib/services/auth_service.dart
import '../models/user.dart';

class AuthService {
  // Simulazione utente corrente
  static String? _currentUserId;
  static String? _currentUserRole;
  static String? _currentUserEmail;
  static String? _currentUsername;

  // Dati mock per testing
  static final Map<String, Map<String, dynamic>> _mockUsers = {
    'admin@workout.com': {
      'password': 'admin123',
      'role': 'admin',
      'id': 'admin_001',
      'username': 'Admin',
      'isAdmin': true,
    },
    'user@workout.com': {
      'password': 'user123',
      'role': 'user',
      'id': 'user_001',
      'username': 'User',
      'isAdmin': false,
    },
  };

  // Getter per lo stato corrente
  static String? get currentUserId => _currentUserId;
  static String? get currentUserRole => _currentUserRole;
  static String? get currentUserEmail => _currentUserEmail;
  static String? get currentUsername => _currentUsername;
  static bool get isLoggedIn => _currentUserId != null;
  static bool get isAdmin => _currentUserRole == 'admin';

  // Login
  static Future<AuthResult> login(String email, String password) async {
    // Simula delay di rete
    await Future.delayed(const Duration(seconds: 1));

    if (_mockUsers.containsKey(email)) {
      final userData = _mockUsers[email]!;
      if (userData['password'] == password) {
        _currentUserId = userData['id'] as String;
        _currentUserRole = userData['role'] as String;
        _currentUserEmail = email;
        _currentUsername = userData['username'] as String;

        return AuthResult.success('Login effettuato con successo');
      }
    }

    return AuthResult.error('Email o password non corretti');
  }

  // Login con username
  static Future<AuthResult> loginWithUsername(
      String username, String password) async {
    await Future.delayed(const Duration(seconds: 1));

    for (final entry in _mockUsers.entries) {
      final userData = entry.value;
      if (userData['username'] == username &&
          userData['password'] == password) {
        _currentUserId = userData['id'] as String;
        _currentUserRole = userData['role'] as String;
        _currentUserEmail = entry.key;
        _currentUsername = username;

        return AuthResult.success('Login effettuato con successo');
      }
    }

    return AuthResult.error('Username o password non corretti');
  }

  // Registrazione
  static Future<AuthResult> register(String email, String password,
      {String? username}) async {
    await Future.delayed(const Duration(seconds: 1));

    if (_mockUsers.containsKey(email)) {
      return AuthResult.error('Email già registrata');
    }

    // Verifica se username è già in uso
    if (username != null) {
      for (final userData in _mockUsers.values) {
        if (userData['username'] == username) {
          return AuthResult.error('Username già in uso');
        }
      }
    }

    // Simula registrazione
    final newUserId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    final newUsername = username ?? email.split('@')[0];

    _mockUsers[email] = {
      'password': password,
      'role': 'user',
      'id': newUserId,
      'username': newUsername,
      'isAdmin': false,
    };

    _currentUserId = newUserId;
    _currentUserRole = 'user';
    _currentUserEmail = email;
    _currentUsername = newUsername;

    return AuthResult.success('Registrazione completata con successo');
  }

  // Logout
  static Future<void> logout() async {
    _currentUserId = null;
    _currentUserRole = null;
    _currentUserEmail = null;
    _currentUsername = null;
  }

  // Ottieni utente corrente
  static Future<User?> getCurrentUser() async {
    if (!isLoggedIn) return null;

    return User(
      id: _currentUserId!,
      email: _currentUserEmail!,
      username: _currentUsername ?? '',
      role: _currentUserRole!,
      isAdmin: _currentUserRole == 'admin',
      createdAt: DateTime.now(),
    );
  }

  // Verifica permessi
  static bool hasPermission(String permission) {
    switch (permission) {
      case 'create_personal_workout':
      case 'add_review':
        return isLoggedIn;
      case 'create_recommended_workout':
      case 'moderate_content':
      case 'manage_difficulty':
      case 'moderate_reviews':
        return isAdmin;
      default:
        return false;
    }
  }

  // Aggiorna profilo
  static Future<AuthResult> updateProfile({
    required String userId,
    String? username,
    String? email,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (userId != _currentUserId) {
      return AuthResult.error('Non autorizzato');
    }

    try {
      if (username != null) {
        _currentUsername = username;
      }
      if (email != null) {
        _currentUserEmail = email;
      }

      return AuthResult.success('Profilo aggiornato con successo');
    } catch (e) {
      return AuthResult.error('Errore durante l\'aggiornamento del profilo');
    }
  }

  // Cambio password
  static Future<AuthResult> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (userId != _currentUserId) {
      return AuthResult.error('Non autorizzato');
    }

    // Verifica password corrente
    final userData = _mockUsers[_currentUserEmail];
    if (userData == null || userData['password'] != currentPassword) {
      return AuthResult.error('Password corrente non corretta');
    }

    // Aggiorna password
    userData['password'] = newPassword;
    return AuthResult.success('Password cambiata con successo');
  }

  // Verifica validità sessione
  static Future<bool> isSessionValid() async {
    return isLoggedIn;
  }

  // Rinnova sessione
  static Future<AuthResult> renewSession() async {
    if (!isLoggedIn) {
      return AuthResult.error('Sessione non valida');
    }
    return AuthResult.success('Sessione rinnovata');
  }

  // Ottieni permessi utente corrente
  static List<String> getCurrentUserPermissions() {
    final permissions = <String>[];

    if (isLoggedIn) {
      permissions.addAll(['create_personal_workout', 'add_review']);
    }

    if (isAdmin) {
      permissions.addAll([
        'create_recommended_workout',
        'moderate_content',
        'manage_difficulty',
        'moderate_reviews',
      ]);
    }

    return permissions;
  }
}

// Classe per i risultati dell'autenticazione
class AuthResult {
  final bool success;
  final String message;

  AuthResult._(this.success, this.message);

  factory AuthResult.success(String message) => AuthResult._(true, message);
  factory AuthResult.error(String message) => AuthResult._(false, message);
}
