import 'package:flutter/material.dart';
import '../../../domain/entities/expiring_lease.dart';
import 'expiring_lease_card.dart';

/// Section widget displaying expiring leases list on dashboard
class ExpiringLeasesSection extends StatelessWidget {
  final List<ExpiringLease> expiringLeases;
  final VoidCallback? onSeeAll;
  final void Function(ExpiringLease)? onItemTap;

  const ExpiringLeasesSection({
    super.key,
    required this.expiringLeases,
    this.onSeeAll,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.event, color: Colors.orange[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Baux a renouveler',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (expiringLeases.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange[700],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${expiringLeases.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (onSeeAll != null && expiringLeases.length > 5)
              TextButton(
                onPressed: onSeeAll,
                child: const Text('Voir tout'),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Content
        if (expiringLeases.isEmpty)
          _buildEmptyState(context)
        else
          _buildList(context),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_available,
                color: Colors.blue[700],
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aucun bail a renouveler',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Aucun bail n\'expire dans les 30 prochains jours.',
                    style: TextStyle(
                      color: Colors.blue[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    return Column(
      children: expiringLeases
          .map((lease) => ExpiringLeaseCard(
                expiringLease: lease,
                onTap: onItemTap != null ? () => onItemTap!(lease) : null,
              ))
          .toList(),
    );
  }
}

/// Loading state for expiring leases section
class ExpiringLeasesSectionLoading extends StatelessWidget {
  const ExpiringLeasesSectionLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 140,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Card shimmer placeholders
        const ExpiringLeaseCardShimmer(),
        const ExpiringLeaseCardShimmer(),
      ],
    );
  }
}

/// Error state for expiring leases section
class ExpiringLeasesSectionError extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ExpiringLeasesSectionError({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.event, color: Colors.orange[700], size: 20),
            const SizedBox(width: 8),
            Text(
              'Baux a renouveler',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          color: Colors.orange[50],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.orange[400]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Erreur de chargement',
                    style: TextStyle(color: Colors.orange[700]),
                  ),
                ),
                if (onRetry != null)
                  TextButton(
                    onPressed: onRetry,
                    child: const Text('Reessayer'),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
