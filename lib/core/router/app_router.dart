import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/providers/auth_provider.dart';
import '../../presentation/providers/onboarding_provider.dart';
import '../../presentation/pages/intro/splash_page.dart';
import '../../presentation/pages/intro/onboarding_page.dart';
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
import '../../presentation/pages/units/unit_form_page.dart';
import '../../presentation/pages/units/unit_detail_page.dart';
import '../../presentation/pages/units/unit_edit_page.dart';
import '../../presentation/pages/tenants/tenants_list_page.dart';
import '../../presentation/pages/tenants/tenant_form_page.dart';
import '../../presentation/pages/tenants/tenant_detail_page.dart';
import '../../presentation/pages/tenants/tenant_edit_page.dart';
import '../../presentation/pages/leases/leases_list_page.dart';
import '../../presentation/pages/leases/lease_form_page.dart';
import '../../presentation/pages/leases/lease_detail_page.dart';
import '../../presentation/pages/leases/lease_edit_page.dart';
import '../../presentation/pages/payments/payments_page.dart';
import '../../presentation/pages/receipts/receipt_preview_page.dart';
import '../../presentation/pages/auth/otp_verification_page.dart';
import '../../presentation/pages/profile/profile_page.dart';
import '../../presentation/widgets/dashboard/main_navigation_shell.dart';

/// Route paths
class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String onboarding = '/onboarding';

  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String otpVerification = '/auth/otp-verification';
  static const String dashboard = '/dashboard';
  static const String profile = '/profile';
  static const String userManagement = '/settings/users';

  // Buildings routes
  static const String buildings = '/buildings';
  static const String buildingNew = '/buildings/new';
  static const String buildingDetail = '/buildings/:id';
  static const String buildingEdit = '/buildings/:id/edit';

  // Units routes
  static const String unitNew = '/buildings/:buildingId/units/create';
  static const String unitDetail = '/buildings/:buildingId/units/:unitId';
  static const String unitEdit = '/buildings/:buildingId/units/:unitId/edit';

  // Tenants routes
  static const String tenants = '/tenants';
  static const String tenantNew = '/tenants/new';
  static const String tenantDetail = '/tenants/:id';
  static const String tenantEdit = '/tenants/:id/edit';

  // Leases routes
  static const String leases = '/leases';
  static const String leaseNew = '/leases/new';
  static const String leaseDetail = '/leases/:id';
  static const String leaseEdit = '/leases/:id/edit';

  // Payments routes
  static const String payments = '/payments';

  // Receipts routes
  static const String receiptPreview = '/receipts/preview/:paymentId';
  static const String receiptHistory = '/receipts/history/:tenantId';
}

/// GoRouter provider with auth redirect logic
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final onboardingCompleted = ref.watch(onboardingProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final authData = authState.value;

      // Wait for initialization
      if (isLoading || authData == null || !authData.isInitialized) {
        return null;
      }

      final isAuthenticated = authData.isAuthenticated;

      // Check onboarding
      if (!onboardingCompleted) {
        if (state.matchedLocation == AppRoutes.splash || 
            state.matchedLocation == AppRoutes.onboarding) {
          return null;
        }
        return AppRoutes.splash;
      }

      if (state.matchedLocation == AppRoutes.splash || 
          state.matchedLocation == AppRoutes.onboarding) {
        return AppRoutes.login;
      }
      final isAuthRoute = state.matchedLocation.startsWith('/auth');
      final isResetPassword = state.matchedLocation == AppRoutes.resetPassword;

      // Allow reset password and OTP pages access even when authenticated
      final isOtpPage = state.matchedLocation.startsWith(AppRoutes.otpVerification);
      if (isResetPassword || isOtpPage) {
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
      // Intro routes
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),

      // Auth routes (outside shell - no bottom nav)
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
      GoRoute(
        path: AppRoutes.otpVerification,
        name: 'otp-verification',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          final type = state.uri.queryParameters['type'] ?? 'signup';
          final redirect = state.uri.queryParameters['redirect'];
          return OtpVerificationPage(
            email: email,
            otpType: type,
            redirectTo: redirect,
          );
        },
      ),

      // Main app routes with bottom navigation (T062-T063)
      ShellRoute(
        builder: (context, state, child) => MainNavigationShell(child: child),
        routes: [
          // Dashboard
          GoRoute(
            path: AppRoutes.dashboard,
            name: 'dashboard',
            builder: (context, state) => const DashboardPage(),
          ),
          // Buildings list
          GoRoute(
            path: AppRoutes.buildings,
            name: 'buildings',
            builder: (context, state) => const BuildingsListPage(),
          ),
          // Tenants list
          GoRoute(
            path: AppRoutes.tenants,
            name: 'tenants',
            builder: (context, state) => const TenantsListPage(),
          ),
          // Payments
          GoRoute(
            path: AppRoutes.payments,
            name: 'payments',
            builder: (context, state) => const PaymentsPage(),
          ),
        ],
      ),

      // Detail routes outside shell (no bottom nav on detail pages - T064)
      // Profile route
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        builder: (context, state) => const ProfilePage(),
      ),

      // Settings routes
      GoRoute(
        path: AppRoutes.userManagement,
        name: 'user-management',
        builder: (context, state) => const UserManagementPage(),
      ),

      // Buildings detail routes
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

      // Units routes
      GoRoute(
        path: AppRoutes.unitNew,
        name: 'unit-new',
        builder: (context, state) {
          final buildingId = state.pathParameters['buildingId']!;
          return UnitFormPage(buildingId: buildingId);
        },
      ),
      GoRoute(
        path: AppRoutes.unitDetail,
        name: 'unit-detail',
        builder: (context, state) {
          final buildingId = state.pathParameters['buildingId']!;
          final unitId = state.pathParameters['unitId']!;
          return UnitDetailPage(buildingId: buildingId, unitId: unitId);
        },
      ),
      GoRoute(
        path: AppRoutes.unitEdit,
        name: 'unit-edit',
        builder: (context, state) {
          final buildingId = state.pathParameters['buildingId']!;
          final unitId = state.pathParameters['unitId']!;
          return UnitEditPage(buildingId: buildingId, unitId: unitId);
        },
      ),

      // Tenants detail routes
      GoRoute(
        path: AppRoutes.tenantNew,
        name: 'tenant-new',
        builder: (context, state) => const TenantFormPage(),
      ),
      GoRoute(
        path: AppRoutes.tenantDetail,
        name: 'tenant-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return TenantDetailPage(tenantId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.tenantEdit,
        name: 'tenant-edit',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return TenantEditPage(tenantId: id);
        },
      ),

      // Leases routes
      GoRoute(
        path: AppRoutes.leases,
        name: 'leases',
        builder: (context, state) => const LeasesListPage(),
      ),
      GoRoute(
        path: AppRoutes.leaseNew,
        name: 'lease-new',
        builder: (context, state) {
          final unitId = state.uri.queryParameters['unitId'];
          final tenantId = state.uri.queryParameters['tenantId'];
          return LeaseFormPage(unitId: unitId, tenantId: tenantId);
        },
      ),
      GoRoute(
        path: AppRoutes.leaseDetail,
        name: 'lease-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return LeaseDetailPage(leaseId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.leaseEdit,
        name: 'lease-edit',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return LeaseEditPage(leaseId: id);
        },
      ),

      // Receipts routes
      GoRoute(
        path: AppRoutes.receiptPreview,
        name: 'receipt-preview',
        builder: (context, state) {
          final paymentId = state.pathParameters['paymentId']!;
          return ReceiptPreviewPage(paymentId: paymentId);
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

  // Payments navigation
  void goToPayments() => go(AppRoutes.payments);
}
