import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user.dart' as domain;
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../core/errors/auth_exceptions.dart' as app_errors;

/// Provider for Supabase client instance
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Provider for AuthRemoteDatasource
final authRemoteDatasourceProvider = Provider<AuthRemoteDatasource>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return AuthRemoteDatasourceImpl(supabaseClient: supabaseClient);
});

/// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remoteDatasource = ref.watch(authRemoteDatasourceProvider);
  return AuthRepositoryImpl(remoteDatasource: remoteDatasource);
});

/// Auth state that tracks loading, error, and user states
class AuthState {
  final domain.User? user;
  final bool isLoading;
  final app_errors.AppAuthException? error;
  final bool isInitialized;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isInitialized = false,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    domain.User? user,
    bool? isLoading,
    app_errors.AppAuthException? error,
    bool? isInitialized,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  @override
  String toString() =>
      'AuthState(user: $user, isLoading: $isLoading, error: $error, isInitialized: $isInitialized)';
}

/// AsyncNotifier for authentication state management
class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    // Initialize by checking current authentication state
    final repository = ref.read(authRepositoryProvider);

    try {
      final user = await repository.getCurrentUser();
      return AuthState(
        user: user,
        isInitialized: true,
      );
    } catch (e) {
      return const AuthState(
        isInitialized: true,
      );
    }
  }

  /// Sign in with email and password
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = AsyncValue.data(
      state.value?.copyWith(isLoading: true, clearError: true) ??
          const AuthState(isLoading: true),
    );

    try {
      final repository = ref.read(authRepositoryProvider);
      final user = await repository.signIn(
        email: email,
        password: password,
      );

      state = AsyncValue.data(AuthState(
        user: user,
        isInitialized: true,
      ));
    } on app_errors.AppAuthException catch (e) {
      state = AsyncValue.data(AuthState(
        error: e,
        isInitialized: true,
      ));
    } catch (e) {
      state = AsyncValue.data(AuthState(
        error: app_errors.NetworkException(message: e.toString()),
        isInitialized: true,
      ));
    }
  }

  /// Sign up with email, password, and full name
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    state = AsyncValue.data(
      state.value?.copyWith(isLoading: true, clearError: true) ??
          const AuthState(isLoading: true),
    );

    try {
      final repository = ref.read(authRepositoryProvider);
      final user = await repository.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );

      state = AsyncValue.data(AuthState(
        user: user,
        isInitialized: true,
      ));
    } on app_errors.AppAuthException catch (e) {
      state = AsyncValue.data(AuthState(
        error: e,
        isInitialized: true,
      ));
    } catch (e) {
      state = AsyncValue.data(AuthState(
        error: app_errors.NetworkException(message: e.toString()),
        isInitialized: true,
      ));
    }
  }

  /// Sign out
  Future<void> signOut() async {
    state = AsyncValue.data(
      state.value?.copyWith(isLoading: true, clearError: true) ??
          const AuthState(isLoading: true),
    );

    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.signOut();

      state = const AsyncValue.data(AuthState(
        isInitialized: true,
      ));
    } on app_errors.AppAuthException catch (e) {
      state = AsyncValue.data(state.value?.copyWith(
            isLoading: false,
            error: e,
          ) ??
          AuthState(error: e, isInitialized: true));
    } catch (e) {
      state = AsyncValue.data(state.value?.copyWith(
            isLoading: false,
            error: app_errors.NetworkException(message: e.toString()),
          ) ??
          AuthState(
            error: app_errors.NetworkException(message: e.toString()),
            isInitialized: true,
          ));
    }
  }

  /// Request password reset email
  Future<void> resetPasswordForEmail({required String email}) async {
    state = AsyncValue.data(
      state.value?.copyWith(isLoading: true, clearError: true) ??
          const AuthState(isLoading: true),
    );

    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.resetPasswordForEmail(email: email);

      state = AsyncValue.data(
        state.value?.copyWith(isLoading: false) ??
            const AuthState(isInitialized: true),
      );
    } on app_errors.AppAuthException catch (e) {
      state = AsyncValue.data(state.value?.copyWith(
            isLoading: false,
            error: e,
          ) ??
          AuthState(error: e, isInitialized: true));
    } catch (e) {
      state = AsyncValue.data(state.value?.copyWith(
            isLoading: false,
            error: app_errors.NetworkException(message: e.toString()),
          ) ??
          AuthState(
            error: app_errors.NetworkException(message: e.toString()),
            isInitialized: true,
          ));
    }
  }

  /// Update password
  Future<void> updatePassword({required String newPassword}) async {
    state = AsyncValue.data(
      state.value?.copyWith(isLoading: true, clearError: true) ??
          const AuthState(isLoading: true),
    );

    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.updatePassword(newPassword: newPassword);

      state = AsyncValue.data(
        state.value?.copyWith(isLoading: false) ??
            const AuthState(isInitialized: true),
      );
    } on app_errors.AppAuthException catch (e) {
      state = AsyncValue.data(state.value?.copyWith(
            isLoading: false,
            error: e,
          ) ??
          AuthState(error: e, isInitialized: true));
    } catch (e) {
      state = AsyncValue.data(state.value?.copyWith(
            isLoading: false,
            error: app_errors.NetworkException(message: e.toString()),
          ) ??
          AuthState(
            error: app_errors.NetworkException(message: e.toString()),
            isInitialized: true,
          ));
    }
  }

  /// Clear any error state
  void clearError() {
    if (state.value?.error != null) {
      state = AsyncValue.data(state.value!.copyWith(clearError: true));
    }
  }

  /// Refresh the current user
  Future<void> refreshUser() async {
    try {
      final repository = ref.read(authRepositoryProvider);
      final user = await repository.getCurrentUser();

      state = AsyncValue.data(AuthState(
        user: user,
        isInitialized: true,
      ));
    } catch (_) {
      // Silent fail on refresh
    }
  }
}

/// Main auth provider using AsyncNotifier
final authProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

/// Convenience provider to get current user directly
final currentUserProvider = Provider<domain.User?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.value?.user;
});

/// Convenience provider to check if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.value?.isAuthenticated ?? false;
});

/// Convenience provider to check if auth is loading
final isAuthLoadingProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.value?.isLoading ?? true;
});

/// Convenience provider to check if auth is initialized
final isAuthInitializedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.value?.isInitialized ?? false;
});

/// Convenience provider to get auth error
final authErrorProvider = Provider<app_errors.AppAuthException?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.value?.error;
});
