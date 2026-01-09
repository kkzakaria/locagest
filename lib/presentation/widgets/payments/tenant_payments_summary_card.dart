import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../domain/entities/payment.dart';
import '../../../domain/repositories/payment_repository.dart';
import '../../providers/payments_provider.dart';

/// Widget displaying a summary of tenant payments with recent payments list
class TenantPaymentsSummaryCard extends ConsumerWidget {
  final String tenantId;
  final String? tenantName;

  const TenantPaymentsSummaryCard({
    super.key,
    required this.tenantId,
    this.tenantName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(tenantPaymentSummaryProvider(tenantId));

    return summaryAsync.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.error_outline, color: Colors.red[400], size: 32),
              const SizedBox(height: 8),
              Text(
                'Erreur de chargement',
                style: TextStyle(color: Colors.red[700]),
              ),
            ],
          ),
        ),
      ),
      data: (summary) => _buildContent(context, ref, summary),
    );
  }

  Widget _buildContent(
      BuildContext context, WidgetRef ref, TenantPaymentSummary summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.payments,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Historique des paiements',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // View all button
                TextButton.icon(
                  onPressed: () => _navigateToPayments(context),
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: const Text('Voir tout'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Summary stats
            _buildSummaryStats(context, summary),

            // Recent payments
            if (summary.recentPayments.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                'Derniers paiements',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              ...summary.recentPayments
                  .take(5)
                  .map((payment) => _buildPaymentItem(context, payment)),
              if (summary.recentPayments.length > 5) ...[
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () => _navigateToPayments(context),
                    child: Text(
                      'Voir les ${summary.recentPayments.length - 5} autres paiements',
                    ),
                  ),
                ),
              ],
            ] else ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey[500], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Aucun paiement enregistré pour ce locataire',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStats(BuildContext context, TenantPaymentSummary summary) {
    return Row(
      children: [
        // Total paid all time
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.check_circle,
            label: 'Total payé',
            value: _formatFCFA(summary.totalPaidAllTime),
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        // Current month
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.calendar_today,
            label: 'Ce mois',
            value: _formatFCFA(summary.currentMonthPaid),
            subtitle: 'sur ${_formatFCFA(summary.currentMonthDue)}',
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        // Overdue
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.warning,
            label: 'Impayés',
            value: _formatFCFA(summary.overdueTotal),
            subtitle:
                summary.overdueCount > 0 ? '${summary.overdueCount} échéance(s)' : null,
            color: summary.overdueCount > 0 ? Colors.red : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    String? subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentItem(BuildContext context, Payment payment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Method icon
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              payment.methodIcon,
              size: 16,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: 10),
          // Date and method
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.paymentDateFormatted,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                Text(
                  payment.methodLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // Amount
          Text(
            payment.amountFormatted,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToPayments(BuildContext context) {
    // Navigate to payments page filtered by tenant
    // For now, just go to the general payments page
    context.push(AppRoutes.payments);
  }

  String _formatFCFA(double amount) {
    final formatter = NumberFormat('#,###', 'fr_FR');
    return '${formatter.format(amount.round())} FCFA';
  }
}

/// Compact version for displaying in a list or smaller space
class TenantPaymentsSummaryCompact extends ConsumerWidget {
  final String tenantId;

  const TenantPaymentsSummaryCompact({
    super.key,
    required this.tenantId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(tenantPaymentSummaryProvider(tenantId));

    return summaryAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
      data: (summary) {
        if (summary.totalPaidAllTime == 0 && summary.overdueCount == 0) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: summary.overdueCount > 0
                ? Colors.red.withValues(alpha: 0.1)
                : Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                summary.overdueCount > 0 ? Icons.warning : Icons.check_circle,
                size: 16,
                color: summary.overdueCount > 0 ? Colors.red[700] : Colors.green[700],
              ),
              const SizedBox(width: 6),
              Text(
                summary.overdueCount > 0
                    ? '${summary.overdueCount} impayé(s)'
                    : 'À jour',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: summary.overdueCount > 0 ? Colors.red[700] : Colors.green[700],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
