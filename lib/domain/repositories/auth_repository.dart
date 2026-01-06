import '../entities/user.dart';

/// Authentication repository interface (Domain layer)
/// Defines the contract for authentication operations
abstract class AuthRepository {
  /// Sign in with email and password
  /// Throws [AuthException] on failure
  Future<User> signIn({
    required String email,
    required String password,
  });

  /// Sign up with email, password, and full name
  /// Throws [AuthException] on failure
  Future<User> signUp({
    required String email,
    required String password,
    required String fullName,
  });

  /// Sign out current user
  Future<void> signOut();

  /// Get currently authenticated user
  /// Returns null if not authenticated
  Future<User?> getCurrentUser();

  /// Request password reset email
  /// Throws [AuthException] on failure
  Future<void> resetPasswordForEmail({required String email});

  /// Update password with new value
  /// Requires valid reset token in session
  /// Throws [AuthException] on failure
  Future<void> updatePassword({required String newPassword});

  /// Get all users (admin only)
  /// Throws [UnauthorizedException] if not admin
  Future<List<User>> getAllUsers();

  /// Update user role (admin only)
  /// Throws [UnauthorizedException] if not admin
  /// Throws [LastAdminException] if trying to demote last admin
  Future<void> updateUserRole({
    required String userId,
    required UserRole newRole,
  });

  /// Stream of auth state changes
  Stream<User?> get authStateChanges;

  /// Check if user is currently authenticated
  bool get isAuthenticated;
}
