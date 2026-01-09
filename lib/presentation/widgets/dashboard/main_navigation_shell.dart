import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Main navigation shell widget with bottom navigation bar
/// Provides persistent bottom navigation across main screens
class MainNavigationShell extends ConsumerWidget {
  final Widget child;

  const MainNavigationShell({
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _getSelectedIndex(location),
        onDestinationSelected: (index) => _navigateTo(context, index),
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
    if (location.startsWith('/payments')) return 3;
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
        context.go('/payments');
        break;
    }
  }
}
