import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../domain/entities/dashboard_stats.dart';
import 'kpi_card.dart';

/// KPI Grid Section widget for dashboard
/// Displays 4 KPI cards in a 2x2 grid layout
class KpiGridSection extends StatelessWidget {
  final DashboardStats stats;
  final VoidCallback? onBuildingsTap;
  final VoidCallback? onTenantsTap;
  final VoidCallback? onRevenueTap;
  final VoidCallback? onOverdueTap;

  const KpiGridSection({
    super.key,
    required this.stats,
    this.onBuildingsTap,
    this.onTenantsTap,
    this.onRevenueTap,
    this.onOverdueTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        KpiCard.buildingsCount(
          stats.buildingsCount,
          onTap: onBuildingsTap ?? () => context.push(AppRoutes.buildings),
        ),
        KpiCard.activeTenants(
          stats.activeTenantsCount,
          onTap: onTenantsTap ?? () => context.push(AppRoutes.tenants),
        ),
        KpiCard.monthlyRevenue(
          stats.monthlyRevenueCollected,
          onTap: onRevenueTap ?? () => context.push(AppRoutes.payments),
        ),
        KpiCard.overdueCount(
          stats.overdueCount,
          onTap: onOverdueTap ?? () => context.push(AppRoutes.payments),
        ),
      ],
    );
  }
}

/// Loading state for KPI Grid Section
/// Shows 4 shimmer placeholders
class KpiGridSectionLoading extends StatelessWidget {
  const KpiGridSectionLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: const [
        KpiCardShimmer(),
        KpiCardShimmer(),
        KpiCardShimmer(),
        KpiCardShimmer(),
      ],
    );
  }
}

/// Empty state for KPI Grid Section
/// Shows when portfolio is empty (no buildings)
class KpiGridSectionEmpty extends StatelessWidget {
  final VoidCallback? onAddBuilding;

  const KpiGridSectionEmpty({
    super.key,
    this.onAddBuilding,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.home_work_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Commencez par ajouter des immeubles',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Votre tableau de bord se remplira automatiquement',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            if (onAddBuilding != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onAddBuilding,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter un immeuble'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error state for KPI Grid Section
/// Shows error message with retry button
class KpiGridSectionError extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const KpiGridSectionError({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.red[700],
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: Colors.red[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Reessayer'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red[700],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
