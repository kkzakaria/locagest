import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../core/utils/secure_storage.dart';
import '../datasources/auth_remote_datasource.dart';

/// Implementation of AuthRepository
/// Bridges the domain layer with the data layer
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _remoteDatasource;
  User? _cachedUser;

  AuthRepositoryImpl({required AuthRemoteDatasource remoteDatasource})
      : _remoteDatasource = remoteDatasource;

  @override
  Future<User> signIn({
    required String email,
    required String password,
  }) async {
    final userModel = await _remoteDatasource.signIn(
      email: email,
      password: password,
    );

    final user = userModel.toEntity();
    _cachedUser = user;

    // Store user ID for quick access
    await SecureStorage.saveUserId(user.id);

    return user;
  }

  @override
  Future<User> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final userModel = await _remoteDatasource.signUp(
      email: email,
      password: password,
      fullName: fullName,
    );

    final user = userModel.toEntity();
    _cachedUser = user;

    // Store user ID for quick access
    await SecureStorage.saveUserId(user.id);

    return user;
  }

  @override
  Future<void> signOut() async {
    await _remoteDatasource.signOut();
    await SecureStorage.clearAll();
    _cachedUser = null;
  }

  @override
  Future<User?> getCurrentUser() async {
    // Return cached user if available
    if (_cachedUser != null) {
      return _cachedUser;
    }

    final userModel = await _remoteDatasource.getCurrentUser();
    if (userModel == null) {
      return null;
    }

    _cachedUser = userModel.toEntity();
    return _cachedUser;
  }

  @override
  Future<void> resetPasswordForEmail({required String email}) async {
    await _remoteDatasource.resetPasswordForEmail(email: email);
  }

  @override
  Future<void> updatePassword({required String newPassword}) async {
    await _remoteDatasource.updatePassword(newPassword: newPassword);
  }

  @override
  Future<List<User>> getAllUsers() async {
    final userModels = await _remoteDatasource.getAllUsers();
    return userModels.map((model) => model.toEntity()).toList();
  }

  @override
  Future<void> updateUserRole({
    required String userId,
    required UserRole newRole,
  }) async {
    await _remoteDatasource.updateUserRole(
      userId: userId,
      newRole: newRole.name,
    );

    // Clear cache to force refresh
    if (_cachedUser?.id == userId) {
      _cachedUser = null;
    }
  }

  @override
  Stream<User?> get authStateChanges {
    return _remoteDatasource.authStateChanges.asyncMap((authState) async {
      final event = authState.event;

      if (event == supabase.AuthChangeEvent.signedIn ||
          event == supabase.AuthChangeEvent.tokenRefreshed ||
          event == supabase.AuthChangeEvent.userUpdated) {
        // User is authenticated, fetch profile
        try {
          final userModel = await _remoteDatasource.getCurrentUser();
          if (userModel != null) {
            _cachedUser = userModel.toEntity();
            return _cachedUser;
          }
        } catch (_) {
          // Failed to get profile, return null
        }
      }

      if (event == supabase.AuthChangeEvent.signedOut) {
        _cachedUser = null;
        await SecureStorage.clearAll();
      }

      return null;
    });
  }

  @override
  bool get isAuthenticated => _cachedUser != null;

  /// Clear the cached user (useful for testing or forced refresh)
  void clearCache() {
    _cachedUser = null;
  }
}
