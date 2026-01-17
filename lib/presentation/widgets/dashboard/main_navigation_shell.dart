import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import 'dashboard_app_bar.dart';

/// Main navigation shell widget with bottom navigation bar and global AppBar
/// Provides persistent bottom navigation and AppBar across main screens
class MainNavigationShell extends ConsumerWidget {
  final Widget child;

  const MainNavigationShell({
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final user = ref.watch(currentUserProvider);
    final totalOverdueAsync = ref.watch(totalOverdueCountProvider);

    return Scaffold(
      extendBody: true, // Allow body to extend behind bottom nav
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              DashboardAppBar(
                user: user,
                notificationCount: totalOverdueAsync.valueOrNull ?? 0,
                onProfileTap: () => context.push(AppRoutes.profile),
                onNotificationTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notifications à venir')),
                  );
                },
              ),
              Expanded(
                child: child,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _getSelectedIndex(location),
        onDestinationSelected: (index) => _navigateTo(context, index),
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 2,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.home_work_outlined),
            selectedIcon: Icon(Icons.home_work),
            label: 'Immeubles',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Locataires',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: 'Baux',
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon: Icon(Icons.payments),
            label: 'Paiements',
          ),
        ],
      ),
    );
  }

  /// Determine which tab is active based on current route (T059)
  int _getSelectedIndex(String location) {
    if (location.startsWith('/buildings')) return 1;
    if (location.startsWith('/tenants')) return 2;
    if (location.startsWith('/leases')) return 3;
    if (location.startsWith('/payments')) return 4;
    return 0; // Dashboard
  }

  /// Navigate to the selected tab (T060)
  void _navigateTo(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/buildings');
        break;
      case 2:
        context.go('/tenants');
        break;
      case 3:
        context.go('/leases');
        break;
      case 4:
        context.go('/payments');
        break;
    }
  }
}
