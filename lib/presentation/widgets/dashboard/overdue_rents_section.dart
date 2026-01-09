import 'package:flutter/material.dart';
import '../../../domain/entities/overdue_rent.dart';
import 'overdue_rent_card.dart';

/// Section widget displaying overdue rents list on dashboard
class OverdueRentsSection extends StatelessWidget {
  final List<OverdueRent> overdueRents;
  final int totalCount;
  final VoidCallback? onSeeAll;
  final void Function(OverdueRent)? onItemTap;

  const OverdueRentsSection({
    super.key,
    required this.overdueRents,
    this.totalCount = 0,
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
                const Icon(Icons.warning_amber, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Impayes',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (totalCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$totalCount',
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
            if (onSeeAll != null && totalCount > 5)
              TextButton(
                onPressed: onSeeAll,
                child: Text('Voir tous ($totalCount)'),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Content
        if (overdueRents.isEmpty)
          _buildEmptyState(context)
        else
          _buildList(context),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green[700],
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aucun impaye',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Felicitations ! Tous les loyers sont a jour.',
                    style: TextStyle(
                      color: Colors.green[600],
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
      children: overdueRents
          .map((rent) => OverdueRentCard(
                overdueRent: rent,
                onTap: onItemTap != null ? () => onItemTap!(rent) : null,
              ))
          .toList(),
    );
  }
}

/// Loading state for overdue rents section
class OverdueRentsSectionLoading extends StatelessWidget {
  const OverdueRentsSectionLoading({super.key});

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
              width: 80,
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
        const OverdueRentCardShimmer(),
        const OverdueRentCardShimmer(),
        const OverdueRentCardShimmer(),
      ],
    );
  }
}

/// Error state for overdue rents section
class OverdueRentsSectionError extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const OverdueRentsSectionError({
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
            const Icon(Icons.warning_amber, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            Text(
              'Impayes',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          color: Colors.red[50],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[400]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Erreur de chargement',
                    style: TextStyle(color: Colors.red[700]),
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
