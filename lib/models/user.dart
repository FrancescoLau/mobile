// lib/models/user.dart
class User {
  final String id;
  final String email;
  final String username;
  final String role;
  final bool isAdmin;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const User({
    required this.id,
    required this.email,
    required this.username,
    required this.role,
    required this.isAdmin,
    required this.createdAt,
    this.updatedAt,
  });

  // Metodo copyWith per creare copie modificate
  User copyWith({
    String? id,
    String? email,
    String? username,
    String? role,
    bool? isAdmin,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      role: role ?? this.role,
      isAdmin: isAdmin ?? this.isAdmin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Serializzazione JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'role': role,
      'isAdmin': isAdmin,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      role: json['role'],
      isAdmin: json['isAdmin'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  // Metodo per verificare se è un admin
  bool get hasAdminRole => role == 'admin' || isAdmin;

  // Metodo per ottenere il nome display
  String get displayName => username.isNotEmpty ? username : email;

  @override
  String toString() {
    return 'User(id: $id, email: $email, username: $username, role: $role, isAdmin: $isAdmin)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.email == email &&
        other.username == username &&
        other.role == role &&
        other.isAdmin == isAdmin;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        email.hashCode ^
        username.hashCode ^
        role.hashCode ^
        isAdmin.hashCode;
  }
}
