import 'dart:ui';
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
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(
                      context,
                      index: 0,
                      currentIndex: _getSelectedIndex(location),
                      icon: Icons.dashboard_outlined,
                      activeIcon: Icons.dashboard,
                      label: 'Accueil',
                    ),
                    _buildNavItem(
                      context,
                      index: 1,
                      currentIndex: _getSelectedIndex(location),
                      icon: Icons.home_work_outlined,
                      activeIcon: Icons.home_work,
                      label: 'Immeubles',
                    ),
                    _buildNavItem(
                      context,
                      index: 2,
                      currentIndex: _getSelectedIndex(location),
                      icon: Icons.people_outline,
                      activeIcon: Icons.people,
                      label: 'Locataires',
                    ),
                    _buildNavItem(
                      context,
                      index: 3,
                      currentIndex: _getSelectedIndex(location),
                      icon: Icons.description_outlined,
                      activeIcon: Icons.description,
                      label: 'Baux',
                    ),
                    _buildNavItem(
                      context,
                      index: 4,
                      currentIndex: _getSelectedIndex(location),
                      icon: Icons.payments_outlined,
                      activeIcon: Icons.payments,
                      label: 'Paiements',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required int currentIndex,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = index == currentIndex;
    const activeColor = Color(0xFF2196F3); // Blue from the image approximation
    const inactiveColor = Colors.grey;

    return InkWell(
      onTap: () => _navigateTo(context, index),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeColor : inactiveColor,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
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
