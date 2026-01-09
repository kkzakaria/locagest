import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// KPI Card widget for dashboard display
/// Shows a single metric with icon, value, and label
class KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const KpiCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  /// Factory constructor for building count KPI
  factory KpiCard.buildingsCount(int count, {VoidCallback? onTap}) {
    return KpiCard(
      icon: Icons.home_work,
      label: 'Immeubles',
      value: count.toString(),
      color: Colors.blue,
      onTap: onTap,
    );
  }

  /// Factory constructor for active tenants KPI
  factory KpiCard.activeTenants(int count, {VoidCallback? onTap}) {
    return KpiCard(
      icon: Icons.people,
      label: 'Locataires actifs',
      value: count.toString(),
      color: Colors.green,
      onTap: onTap,
    );
  }

  /// Factory constructor for monthly revenue KPI
  factory KpiCard.monthlyRevenue(double amount, {VoidCallback? onTap}) {
    final formatter = NumberFormat('#,###', 'fr_FR');
    final formatted = '${formatter.format(amount.round())} FCFA';
    return KpiCard(
      icon: Icons.payments,
      label: 'Revenus du mois',
      value: formatted,
      color: Colors.orange,
      onTap: onTap,
    );
  }

  /// Factory constructor for overdue count KPI
  factory KpiCard.overdueCount(int count, {VoidCallback? onTap}) {
    return KpiCard(
      icon: Icons.warning,
      label: 'Impayes',
      value: count.toString(),
      color: count > 0 ? Colors.red : Colors.green,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              // Value and label
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shimmer loading placeholder for KPI card
class KpiCardShimmer extends StatelessWidget {
  const KpiCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Icon placeholder
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 12),
            // Value placeholder
            Container(
              width: 80,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),
            // Label placeholder
            Container(
              width: 60,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
