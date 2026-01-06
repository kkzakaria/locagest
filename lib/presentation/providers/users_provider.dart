import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/user.dart';
import '../../core/errors/auth_exceptions.dart' as app_errors;
import 'auth_provider.dart';

/// State for user list management
class UsersState {
  final List<User> users;
  final bool isLoading;
  final app_errors.AppAuthException? error;

  const UsersState({
    this.users = const [],
    this.isLoading = false,
    this.error,
  });

  UsersState copyWith({
    List<User>? users,
    bool? isLoading,
    app_errors.AppAuthException? error,
    bool clearError = false,
  }) {
    return UsersState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Notifier for managing user list (admin only)
class UsersNotifier extends AsyncNotifier<UsersState> {
  @override
  Future<UsersState> build() async {
    return const UsersState();
  }

  /// Load all users from the server
  Future<void> loadUsers() async {
    state = AsyncValue.data(
      state.value?.copyWith(isLoading: true, clearError: true) ??
          const UsersState(isLoading: true),
    );

    try {
      final repository = ref.read(authRepositoryProvider);
      final users = await repository.getAllUsers();

      state = AsyncValue.data(UsersState(users: users));
    } on app_errors.AppAuthException catch (e) {
      state = AsyncValue.data(UsersState(error: e));
    } catch (e) {
      state = AsyncValue.data(UsersState(
        error: app_errors.NetworkException(message: e.toString()),
      ));
    }
  }

  /// Update a user's role
  Future<bool> updateUserRole({
    required String userId,
    required UserRole newRole,
  }) async {
    state = AsyncValue.data(
      state.value?.copyWith(isLoading: true, clearError: true) ??
          const UsersState(isLoading: true),
    );

    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.updateUserRole(userId: userId, newRole: newRole);

      // Reload users to get updated data
      await loadUsers();
      return true;
    } on app_errors.AppAuthException catch (e) {
      state = AsyncValue.data(
        state.value?.copyWith(isLoading: false, error: e) ??
            UsersState(error: e),
      );
      return false;
    } catch (e) {
      state = AsyncValue.data(
        state.value?.copyWith(
              isLoading: false,
              error: app_errors.NetworkException(message: e.toString()),
            ) ??
            UsersState(error: app_errors.NetworkException(message: e.toString())),
      );
      return false;
    }
  }

  /// Clear any error
  void clearError() {
    if (state.value?.error != null) {
      state = AsyncValue.data(state.value!.copyWith(clearError: true));
    }
  }
}

/// Provider for users state
final usersProvider =
    AsyncNotifierProvider<UsersNotifier, UsersState>(UsersNotifier.new);

/// Convenience provider for users list
final usersListProvider = Provider<List<User>>((ref) {
  final usersState = ref.watch(usersProvider);
  return usersState.value?.users ?? [];
});

/// Convenience provider to check if users are loading
final isUsersLoadingProvider = Provider<bool>((ref) {
  final usersState = ref.watch(usersProvider);
  return usersState.value?.isLoading ?? false;
});

/// Convenience provider to get users error
final usersErrorProvider = Provider<app_errors.AppAuthException?>((ref) {
  final usersState = ref.watch(usersProvider);
  return usersState.value?.error;
});
