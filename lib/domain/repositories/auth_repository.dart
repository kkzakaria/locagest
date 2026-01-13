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

  /// Verify OTP code for signup, recovery, or email change
  /// Returns the authenticated user on success
  /// Throws [InvalidOtpException] if code is invalid
  /// Throws [OtpExpiredException] if code has expired
  Future<User?> verifyOtp({
    required String type,
    required String email,
    required String token,
  });

  /// Resend OTP code for signup or email change
  /// For recovery, use resetPasswordForEmail instead
  /// Throws [TooManyRequestsException] if rate limited
  Future<void> resendOtp({
    required String type,
    required String email,
  });

  /// Request email change for current user
  /// Sends OTP to the new email address
  /// Throws [EmailAlreadyInUseException] if email is taken
  Future<void> requestEmailChange({required String newEmail});
}
