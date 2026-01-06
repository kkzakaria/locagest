import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/providers/auth_provider.dart';
import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/pages/auth/register_page.dart';
import '../../presentation/pages/auth/forgot_password_page.dart';
import '../../presentation/pages/auth/reset_password_page.dart';
import '../../presentation/pages/home/dashboard_page.dart';
import '../../presentation/pages/settings/user_management_page.dart';
import '../../presentation/pages/buildings/building_form_page.dart';
import '../../presentation/pages/buildings/buildings_list_page.dart';
import '../../presentation/pages/buildings/building_detail_page.dart';
import '../../presentation/pages/buildings/building_edit_page.dart';

/// Route paths
class AppRoutes {
  AppRoutes._();

  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String dashboard = '/dashboard';
  static const String userManagement = '/settings/users';

  // Buildings routes
  static const String buildings = '/buildings';
  static const String buildingNew = '/buildings/new';
  static const String buildingDetail = '/buildings/:id';
  static const String buildingEdit = '/buildings/:id/edit';
}

/// GoRouter provider with auth redirect logic
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: AppRoutes.login,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final authData = authState.value;

      // Wait for initialization
      if (isLoading || authData == null || !authData.isInitialized) {
        return null;
      }

      final isAuthenticated = authData.isAuthenticated;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');
      final isResetPassword = state.matchedLocation == AppRoutes.resetPassword;

      // Allow reset password page access even when authenticated (from deep link)
      if (isResetPassword) {
        return null;
      }

      // If not authenticated and not on auth route, redirect to login
      if (!isAuthenticated && !isAuthRoute) {
        return AppRoutes.login;
      }

      // If authenticated and on auth route (except reset password), redirect to dashboard
      if (isAuthenticated && isAuthRoute) {
        return AppRoutes.dashboard;
      }

      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        name: 'reset-password',
        builder: (context, state) => const ResetPasswordPage(),
      ),

      // Main app routes
      GoRoute(
        path: AppRoutes.dashboard,
        name: 'dashboard',
        builder: (context, state) => const DashboardPage(),
      ),

      // Settings routes
      GoRoute(
        path: AppRoutes.userManagement,
        name: 'user-management',
        builder: (context, state) => const UserManagementPage(),
      ),

      // Buildings routes
      GoRoute(
        path: AppRoutes.buildings,
        name: 'buildings',
        builder: (context, state) => const BuildingsListPage(),
      ),
      GoRoute(
        path: AppRoutes.buildingNew,
        name: 'building-new',
        builder: (context, state) => const BuildingFormPage(),
      ),
      GoRoute(
        path: AppRoutes.buildingDetail,
        name: 'building-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return BuildingDetailPage(buildingId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.buildingEdit,
        name: 'building-edit',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return BuildingEditPageWrapper(buildingId: id);
        },
      ),

      // Root redirect
      GoRoute(
        path: '/',
        redirect: (context, state) => AppRoutes.dashboard,
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Page non trouvee',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.matchedLocation,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.dashboard),
              child: const Text('Retour a l\'accueil'),
            ),
          ],
        ),
      ),
    ),
  );
});

/// Extension for easy navigation
extension GoRouterExtension on BuildContext {
  void goToLogin() => go(AppRoutes.login);
  void goToRegister() => go(AppRoutes.register);
  void goToForgotPassword() => go(AppRoutes.forgotPassword);
  void goToResetPassword() => go(AppRoutes.resetPassword);
  void goToDashboard() => go(AppRoutes.dashboard);
  void goToUserManagement() => go(AppRoutes.userManagement);

  // Buildings navigation
  void goToBuildings() => go(AppRoutes.buildings);
  void goToNewBuilding() => go(AppRoutes.buildingNew);
}
