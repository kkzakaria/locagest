import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/entities/overdue_rent.dart';
import '../../../domain/entities/expiring_lease.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/dashboard/kpi_grid_section.dart';
import '../../widgets/dashboard/overdue_rents_section.dart';
import '../../widgets/dashboard/expiring_leases_section.dart';
import '../../widgets/dashboard/occupancy_rate_widget.dart';

/// Main dashboard page after login
/// Displays KPIs, overdue rents, expiring leases, and quick actions
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);
    final overdueAsync = ref.watch(overdueRentsProvider);
    final expiringAsync = ref.watch(expiringLeasesProvider);
    final totalOverdueAsync = ref.watch(totalOverdueCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('LocaGest'),
        actions: [
          // User menu
          PopupMenuButton<String>(
            icon: const CircleAvatar(
              child: Icon(Icons.person),
            ),
            onSelected: (value) async {
              switch (value) {
                case 'users':
                  context.go(AppRoutes.userManagement);
                  break;
                case 'logout':
                  await _handleLogout(context, ref);
                  break;
              }
            },
            itemBuilder: (context) => [
              // User info header
              PopupMenuItem<String>(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.fullName ?? 'Utilisateur',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      user?.email ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getRoleColor(user?.role),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        user?.role.displayName ?? '',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              // User management (admin only)
              if (user?.canManageUsers ?? false)
                const PopupMenuItem<String>(
                  value: 'users',
                  child: ListTile(
                    leading: Icon(Icons.people),
                    title: Text('Gestion des utilisateurs'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              // Logout
              const PopupMenuItem<String>(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title:
                      Text('Deconnexion', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Invalidate all dashboard providers
          ref.invalidate(dashboardStatsProvider);
          ref.invalidate(overdueRentsProvider);
          ref.invalidate(expiringLeasesProvider);
          ref.invalidate(totalOverdueCountProvider);
          // Wait for the main stats to reload
          await ref.read(dashboardStatsProvider.future);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome message
              Text(
                'Bonjour, ${user?.fullName ?? 'Utilisateur'}!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bienvenue sur votre tableau de bord',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 24),

              // KPI Cards Section (T022-T025)
              _buildKpiSection(context, ref, statsAsync, user),

              const SizedBox(height: 24),

              // Occupancy Rate Section (US4)
              statsAsync.when(
                data: (stats) => OccupancyRateWidget(
                  occupancyRate: stats.occupancyRate,
                  totalUnits: stats.totalUnitsCount,
                  occupiedUnits: stats.occupiedUnitsCount,
                ),
                loading: () => const OccupancyRateWidgetLoading(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 24),

              // Overdue Rents Section (US2)
              _buildOverdueSection(context, ref, overdueAsync, totalOverdueAsync),

              const SizedBox(height: 24),

              // Expiring Leases Section (US3)
              _buildExpiringSection(context, ref, expiringAsync),

              const SizedBox(height: 24),

              // Quick actions (US5)
              Text(
                'Actions rapides',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              _buildQuickActions(context, user),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Build KPI section with loading/error/empty states (T022-T025)
  Widget _buildKpiSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue statsAsync,
    User? user,
  ) {
    return statsAsync.when(
      data: (stats) {
        // Empty state (T025)
        if (stats.buildingsCount == 0) {
          return KpiGridSectionEmpty(
            onAddBuilding: (user?.canManageBuildings ?? false)
                ? () => context.push(AppRoutes.buildingNew)
                : null,
          );
        }
        // Normal display
        return KpiGridSection(stats: stats);
      },
      // Loading state (T023)
      loading: () => const KpiGridSectionLoading(),
      // Error state (T024)
      error: (error, _) => KpiGridSectionError(
        message: error.toString(),
        onRetry: () => ref.invalidate(dashboardStatsProvider),
      ),
    );
  }

  /// Build overdue rents section (US2)
  Widget _buildOverdueSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<OverdueRent>> overdueAsync,
    AsyncValue<int> totalOverdueAsync,
  ) {
    return overdueAsync.when(
      data: (overdueRents) {
        final totalCount = totalOverdueAsync.valueOrNull ?? overdueRents.length;
        return OverdueRentsSection(
          overdueRents: overdueRents,
          totalCount: totalCount,
          onSeeAll: totalCount > 5
              ? () => context.push(AppRoutes.payments)
              : null,
          onItemTap: (rent) => context.push('/leases/${rent.leaseId}'),
        );
      },
      loading: () => const OverdueRentsSectionLoading(),
      error: (error, _) => OverdueRentsSectionError(
        message: error.toString(),
        onRetry: () => ref.invalidate(overdueRentsProvider),
      ),
    );
  }

  /// Build expiring leases section (US3)
  Widget _buildExpiringSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<ExpiringLease>> expiringAsync,
  ) {
    return expiringAsync.when(
      data: (expiringLeases) => ExpiringLeasesSection(
        expiringLeases: expiringLeases,
        onItemTap: (lease) => context.push('/leases/${lease.leaseId}'),
      ),
      loading: () => const ExpiringLeasesSectionLoading(),
      error: (error, _) => ExpiringLeasesSectionError(
        message: error.toString(),
        onRetry: () => ref.invalidate(expiringLeasesProvider),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, User? user) {
    final actions = <Widget>[];

    // Building management (gestionnaire and admin)
    if (user?.canManageBuildings ?? false) {
      actions.add(_buildActionCard(
        context,
        icon: Icons.add_home_work,
        label: 'Ajouter un immeuble',
        onTap: () => context.push(AppRoutes.buildingNew),
      ));
    }

    // View buildings (all users)
    actions.add(_buildActionCard(
      context,
      icon: Icons.home_work,
      label: 'Voir les immeubles',
      onTap: () => context.push(AppRoutes.buildings),
    ));

    // View tenants (all users)
    actions.add(_buildActionCard(
      context,
      icon: Icons.people,
      label: 'Voir les locataires',
      onTap: () => context.push(AppRoutes.tenants),
    ));

    // View leases (all users)
    actions.add(_buildActionCard(
      context,
      icon: Icons.description,
      label: 'Voir les baux',
      onTap: () => context.push(AppRoutes.leases),
    ));

    // View payments (all users)
    actions.add(_buildActionCard(
      context,
      icon: Icons.payments,
      label: 'Paiements',
      onTap: () => context.push(AppRoutes.payments),
    ));

    // User management (admin only)
    if (user?.canManageUsers ?? false) {
      actions.add(_buildActionCard(
        context,
        icon: Icons.manage_accounts,
        label: 'Gerer les utilisateurs',
        onTap: () => context.go(AppRoutes.userManagement),
      ));
    }

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: actions,
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(UserRole? role) {
    switch (role) {
      case UserRole.admin:
        return Colors.red;
      case UserRole.gestionnaire:
        return Colors.blue;
      case UserRole.assistant:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deconnexion'),
        content: const Text('Voulez-vous vraiment vous deconnecter?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Deconnexion'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authProvider.notifier).signOut();
      // Navigation is handled by GoRouter redirect
    }
  }
}
