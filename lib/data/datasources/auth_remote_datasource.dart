import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../../core/errors/auth_exceptions.dart' as app_errors;

/// Remote data source for authentication operations
/// Directly interacts with Supabase Auth and profiles table
abstract class AuthRemoteDatasource {
  /// Sign in with email and password
  /// Throws [AccountLockedException] if account is locked
  /// Throws [InvalidCredentialsException] if credentials are invalid
  Future<UserModel> signIn({
    required String email,
    required String password,
  });

  /// Sign up with email, password, and full name
  /// Throws [EmailAlreadyInUseException] if email is taken
  /// Throws [WeakPasswordException] if password doesn't meet requirements
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String fullName,
  });

  /// Sign out current user
  Future<void> signOut();

  /// Get current authenticated user profile
  /// Returns null if not authenticated
  Future<UserModel?> getCurrentUser();

  /// Request password reset email
  Future<void> resetPasswordForEmail({required String email});

  /// Update password with new value
  /// Requires valid session (from reset link)
  Future<void> updatePassword({required String newPassword});

  /// Get all users (admin only)
  /// Throws [UnauthorizedException] if not admin
  Future<List<UserModel>> getAllUsers();

  /// Update user role (admin only)
  /// Throws [UnauthorizedException] if not admin
  /// Throws [LastAdminException] if trying to demote last admin
  Future<void> updateUserRole({
    required String userId,
    required String newRole,
  });

  /// Stream of auth state changes
  Stream<AuthState> get authStateChanges;
}

/// Implementation of AuthRemoteDatasource using Supabase
class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  final SupabaseClient _supabaseClient;

  AuthRemoteDatasourceImpl({required SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient;

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Step 1: Check if account is locked
      final lockoutCheck = await _supabaseClient.rpc(
        'check_login_attempt',
        params: {'user_email': email},
      );

      if (lockoutCheck != null && lockoutCheck['allowed'] == false) {
        final lockedUntil = lockoutCheck['locked_until'] != null
            ? DateTime.parse(lockoutCheck['locked_until'])
            : null;
        throw app_errors.AccountLockedException(lockedUntil: lockedUntil);
      }

      // Step 2: Attempt sign in
      final response = await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        // Record failed attempt
        await _recordFailedLogin(email);
        throw const app_errors.InvalidCredentialsException();
      }

      // Step 3: Reset failed attempts on success
      await _supabaseClient.rpc(
        'reset_login_attempts',
        params: {'user_email': email},
      );

      // Step 4: Get user profile
      return await _getUserProfile(response.user!.id);
    } on AuthException catch (e) {
      // Record failed attempt for auth errors
      await _recordFailedLogin(email);

      if (e.message.contains('Invalid login credentials')) {
        throw const app_errors.InvalidCredentialsException();
      }
      if (e.message.contains('Too many requests')) {
        throw const app_errors.TooManyRequestsException();
      }
      throw app_errors.NetworkException(message: e.message);
    } on app_errors.AccountLockedException {
      rethrow;
    } on app_errors.InvalidCredentialsException {
      rethrow;
    } catch (e) {
      throw app_errors.NetworkException(message: e.toString());
    }
  }

  @override
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await _supabaseClient.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

      if (response.user == null) {
        throw const app_errors.NetworkException(message: 'Sign up failed');
      }

      // Profile is auto-created by database trigger
      // Small delay to ensure trigger has executed
      await Future.delayed(const Duration(milliseconds: 500));

      return await _getUserProfile(response.user!.id);
    } on AuthException catch (e) {
      if (e.message.contains('already registered') ||
          e.message.contains('already exists')) {
        throw const app_errors.EmailAlreadyInUseException();
      }
      if (e.message.contains('Password should be at least')) {
        throw const app_errors.WeakPasswordException();
      }
      throw app_errors.NetworkException(message: e.message);
    } catch (e) {
      if (e is app_errors.EmailAlreadyInUseException || e is app_errors.WeakPasswordException) {
        rethrow;
      }
      throw app_errors.NetworkException(message: e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _supabaseClient.auth.signOut();
    } on AuthException catch (e) {
      throw app_errors.NetworkException(message: e.message);
    } catch (e) {
      throw app_errors.NetworkException(message: e.toString());
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _supabaseClient.auth.currentUser;
      if (user == null) {
        return null;
      }

      return await _getUserProfile(user.id);
    } on AuthException catch (e) {
      if (e.message.contains('expired') || e.message.contains('invalid')) {
        throw const app_errors.TokenExpiredException();
      }
      throw app_errors.NetworkException(message: e.message);
    } catch (e) {
      if (e is app_errors.TokenExpiredException) {
        rethrow;
      }
      throw app_errors.NetworkException(message: e.toString());
    }
  }

  @override
  Future<void> resetPasswordForEmail({required String email}) async {
    try {
      await _supabaseClient.auth.resetPasswordForEmail(
        email,
        redirectTo: 'locagest://reset-password',
      );
    } on AuthException catch (e) {
      throw app_errors.NetworkException(message: e.message);
    } catch (e) {
      throw app_errors.NetworkException(message: e.toString());
    }
  }

  @override
  Future<void> updatePassword({required String newPassword}) async {
    try {
      await _supabaseClient.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } on AuthException catch (e) {
      if (e.message.contains('Password should be at least')) {
        throw const app_errors.WeakPasswordException();
      }
      if (e.message.contains('invalid') || e.message.contains('expired')) {
        throw const app_errors.TokenExpiredException();
      }
      throw app_errors.NetworkException(message: e.message);
    } catch (e) {
      if (e is app_errors.WeakPasswordException || e is app_errors.TokenExpiredException) {
        rethrow;
      }
      throw app_errors.NetworkException(message: e.toString());
    }
  }

  @override
  Future<List<UserModel>> getAllUsers() async {
    try {
      final response = await _supabaseClient
          .from('profiles')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      if (e.code == '42501' || e.message.contains('permission denied')) {
        throw const app_errors.UnauthorizedException();
      }
      throw app_errors.NetworkException(message: e.message);
    } catch (e) {
      if (e is app_errors.UnauthorizedException) {
        rethrow;
      }
      throw app_errors.NetworkException(message: e.toString());
    }
  }

  @override
  Future<void> updateUserRole({
    required String userId,
    required String newRole,
  }) async {
    try {
      await _supabaseClient
          .from('profiles')
          .update({'role': newRole})
          .eq('id', userId);
    } on PostgrestException catch (e) {
      if (e.code == '42501' || e.message.contains('permission denied')) {
        throw const app_errors.UnauthorizedException();
      }
      if (e.message.contains('last admin') ||
          e.message.contains('Cannot demote')) {
        throw const app_errors.LastAdminException();
      }
      throw app_errors.NetworkException(message: e.message);
    } catch (e) {
      if (e is app_errors.UnauthorizedException || e is app_errors.LastAdminException) {
        rethrow;
      }
      throw app_errors.NetworkException(message: e.toString());
    }
  }

  @override
  Stream<AuthState> get authStateChanges =>
      _supabaseClient.auth.onAuthStateChange;

  /// Get user profile from profiles table
  Future<UserModel> _getUserProfile(String userId) async {
    try {
      final response = await _supabaseClient
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      return UserModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw app_errors.NetworkException(message: e.message);
    }
  }

  /// Record a failed login attempt (increments counter, may trigger lockout)
  Future<void> _recordFailedLogin(String email) async {
    try {
      await _supabaseClient.rpc(
        'record_failed_login',
        params: {'user_email': email},
      );
    } catch (_) {
      // Silent fail - don't want to mask the original error
    }
  }
}
