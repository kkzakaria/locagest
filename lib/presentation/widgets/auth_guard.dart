import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

/// Widget that guards child content based on authentication state
/// Shows loading indicator while auth is initializing
/// Redirects to login if not authenticated (handled by GoRouter)
class AuthGuard extends ConsumerWidget {
  final Widget child;
  final Widget? loadingWidget;

  const AuthGuard({
    super.key,
    required this.child,
    this.loadingWidget,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return authState.when(
      data: (state) {
        if (!state.isInitialized) {
          return _buildLoading();
        }

        if (!state.isAuthenticated) {
          // GoRouter will handle redirect, show loading in meantime
          return _buildLoading();
        }

        return child;
      },
      loading: () => _buildLoading(),
      error: (error, stack) => _buildLoading(),
    );
  }

  Widget _buildLoading() {
    return loadingWidget ??
        const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
  }
}

/// Widget that shows content only when user is NOT authenticated
/// Used for auth pages (login, register, etc.)
class UnauthGuard extends ConsumerWidget {
  final Widget child;
  final Widget? loadingWidget;

  const UnauthGuard({
    super.key,
    required this.child,
    this.loadingWidget,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return authState.when(
      data: (state) {
        if (!state.isInitialized) {
          return _buildLoading();
        }

        if (state.isAuthenticated) {
          // GoRouter will handle redirect, show loading in meantime
          return _buildLoading();
        }

        return child;
      },
      loading: () => _buildLoading(),
      error: (error, stack) => _buildLoading(),
    );
  }

  Widget _buildLoading() {
    return loadingWidget ??
        const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
  }
}

/// Wrapper widget that provides auth initialization check
/// Use at the root of the app to wait for auth to initialize
class AuthInitializer extends ConsumerWidget {
  final Widget child;
  final Widget? loadingWidget;

  const AuthInitializer({
    super.key,
    required this.child,
    this.loadingWidget,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isInitialized = ref.watch(isAuthInitializedProvider);

    if (!isInitialized) {
      return loadingWidget ??
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Chargement...',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
    }

    return child;
  }
}
