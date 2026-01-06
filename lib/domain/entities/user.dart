/// User roles in LocaGest
enum UserRole {
  admin,
  gestionnaire,
  assistant;

  /// Parse role from string (database value)
  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UserRole.gestionnaire,
    );
  }

  /// Get display name in French
  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Administrateur';
      case UserRole.gestionnaire:
        return 'Gestionnaire';
      case UserRole.assistant:
        return 'Assistant';
    }
  }
}

/// User entity (Domain layer - pure Dart, no dependencies)
class User {
  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final String? avatarUrl;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.avatarUrl,
    required this.createdAt,
  });

  /// Check if user is admin
  bool get isAdmin => role == UserRole.admin;

  /// Check if user is gestionnaire
  bool get isGestionnaire => role == UserRole.gestionnaire;

  /// Check if user is assistant
  bool get isAssistant => role == UserRole.assistant;

  /// Check if user can manage other users
  bool get canManageUsers => isAdmin;

  /// Check if user can manage buildings (full CRUD)
  bool get canManageBuildings => isAdmin || isGestionnaire;

  /// Check if user can view buildings (read only)
  bool get canViewBuildings => true;

  /// Check if user can generate reports
  bool get canGenerateReports => isAdmin || isGestionnaire;

  /// Copy with modified fields
  User copyWith({
    String? id,
    String? email,
    String? fullName,
    UserRole? role,
    String? avatarUrl,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          fullName == other.fullName &&
          role == other.role;

  @override
  int get hashCode =>
      id.hashCode ^ email.hashCode ^ fullName.hashCode ^ role.hashCode;

  @override
  String toString() {
    return 'User{id: $id, email: $email, fullName: $fullName, role: $role}';
  }
}
