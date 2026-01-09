import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/payment.dart';
import '../../pages/payments/payment_edit_modal.dart';
import '../../providers/payments_provider.dart';

/// Widget displaying payment history for a rent schedule
class PaymentHistoryList extends ConsumerWidget {
  final String scheduleId;
  final bool showHeader;
  final bool compact;
  final VoidCallback? onPaymentChanged;

  const PaymentHistoryList({
    super.key,
    required this.scheduleId,
    this.showHeader = true,
    this.compact = false,
    this.onPaymentChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(paymentsForScheduleProvider(scheduleId));
    final canManageAsync = ref.watch(canManagePaymentsProvider);

    return paymentsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Erreur: $error',
            style: TextStyle(color: Colors.red[700]),
          ),
        ),
      ),
      data: (payments) {
        if (payments.isEmpty) {
          return _buildEmptyState(context);
        }

        final canManage = canManageAsync.valueOrNull ?? false;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader) ...[
              _buildHeader(context, payments.length),
              const SizedBox(height: 8),
            ],
            ...payments.map((payment) => _PaymentTile(
                  payment: payment,
                  canManage: canManage,
                  compact: compact,
                  onPaymentChanged: () {
                    // Invalidate the provider to refresh the list
                    ref.invalidate(paymentsForScheduleProvider(scheduleId));
                    onPaymentChanged?.call();
                  },
                )),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Icon(
            Icons.history,
            size: 18,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Text(
            'Historique des paiements ($count)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    if (compact) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          'Aucun paiement enregistré',
          style: TextStyle(
            color: Colors.grey[500],
            fontStyle: FontStyle.italic,
            fontSize: 13,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.payments_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            'Aucun paiement enregistré',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Les paiements apparaîtront ici',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual payment tile with edit/delete actions
class _PaymentTile extends StatelessWidget {
  final Payment payment;
  final bool canManage;
  final bool compact;
  final VoidCallback? onPaymentChanged;

  const _PaymentTile({
    required this.payment,
    required this.canManage,
    this.compact = false,
    this.onPaymentChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Date, amount, and actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    payment.methodIcon,
                    size: 18,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    payment.paymentDateFormatted,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    payment.amountFormatted,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  // Edit/Delete actions (only for admin/gestionnaire)
                  if (canManage && !compact) ...[
                    const SizedBox(width: 8),
                    _buildActionMenu(context),
                  ],
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Method label
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  payment.methodLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Receipt number
              Expanded(
                child: Text(
                  'Reçu: ${payment.receiptNumber}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),

          // Check-specific fields
          if (payment.isCheckPayment && payment.checkNumber != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.receipt_long, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  'Chèque n° ${payment.checkNumber}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (payment.bankName != null) ...[
                  Text(
                    ' - ${payment.bankName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ],

          // Reference for transfer/mobile money
          if (payment.needsReference && payment.reference != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.tag, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Réf: ${payment.reference}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          // Notes
          if (payment.notes != null && payment.notes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.notes, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    payment.notes!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, size: 20, color: Colors.grey[600]),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            _showEditModal(context);
            break;
          case 'delete':
            _confirmDelete(context);
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit, size: 20),
            title: Text('Modifier'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete, size: 20, color: Colors.red[400]),
            title: Text('Supprimer', style: TextStyle(color: Colors.red[400])),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
      ],
    );
  }

  void _showEditModal(BuildContext context) {
    PaymentEditModal.show(
      context: context,
      payment: payment,
      onPaymentUpdated: onPaymentChanged,
      onPaymentDeleted: onPaymentChanged,
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le paiement'),
        content: const Text(
          'Voulez-vous vraiment supprimer ce paiement ? '
          'Cette action est irréversible et le statut de l\'échéance sera recalculé.',
        ),
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
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      _showEditModal(context);
    }
  }
}

/// Compact inline payment history for schedule rows
class PaymentHistoryInline extends ConsumerWidget {
  final String scheduleId;

  const PaymentHistoryInline({
    super.key,
    required this.scheduleId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(paymentsForScheduleProvider(scheduleId));

    return paymentsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
      data: (payments) {
        if (payments.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, size: 12, color: Colors.green[600]),
              const SizedBox(width: 4),
              Text(
                '${payments.length} paiement${payments.length > 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
