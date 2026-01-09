import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../domain/entities/lease.dart';
import '../../../domain/entities/rent_schedule.dart';
import '../../providers/leases_provider.dart';
import '../../widgets/leases/lease_status_badge.dart';
import '../../widgets/payments/payment_history_list.dart';
import '../../widgets/receipts/receipt_list_item.dart';
import '../payments/payment_form_modal.dart';

/// Page displaying full lease details including tenant, unit, amounts,
/// dates, and rent schedules
class LeaseDetailPage extends ConsumerWidget {
  final String leaseId;

  const LeaseDetailPage({
    super.key,
    required this.leaseId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaseAsync = ref.watch(leaseByIdProvider(leaseId));
    final canManage = ref.watch(canManageLeasesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail du bail'),
        actions: canManage.maybeWhen(
          data: (canManage) => canManage
              ? [
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleMenuAction(context, ref, value),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Modifier'),
                          ],
                        ),
                      ),
                      if (leaseAsync.valueOrNull?.canBeTerminated == true)
                        const PopupMenuItem(
                          value: 'terminate',
                          child: Row(
                            children: [
                              Icon(Icons.cancel_outlined, color: Colors.orange),
                              SizedBox(width: 8),
                              Text('Resilier', style: TextStyle(color: Colors.orange)),
                            ],
                          ),
                        ),
                      if (leaseAsync.valueOrNull?.canBeDeleted == true)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Supprimer', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ]
              : null,
          orElse: () => null,
        ),
      ),
      body: leaseAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(context, error.toString(), ref),
        data: (lease) => _buildContent(context, ref, lease),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, WidgetRef ref, String action) {
    switch (action) {
      case 'edit':
        context.push('${AppRoutes.leases}/$leaseId/edit');
        break;
      case 'terminate':
        _showTerminateDialog(context, ref);
        break;
      case 'delete':
        _showDeleteDialog(context, ref);
        break;
    }
  }

  void _showTerminateDialog(BuildContext context, WidgetRef ref) {
    DateTime terminationDate = DateTime.now();
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Resilier le bail'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Cette action est irreversible. Les echeances futures seront annulees.'),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: terminationDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                    locale: const Locale('fr', 'FR'),
                  );
                  if (picked != null) {
                    setState(() => terminationDate = picked);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date de resiliation',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(DateFormat('dd/MM/yyyy').format(terminationDate)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Motif de resiliation *',
                  hintText: 'Ex: Fin de contrat, depart du locataire...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (reasonController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Le motif est obligatoire')),
                  );
                  return;
                }

                Navigator.pop(context);
                await _handleTerminate(context, ref, terminationDate, reasonController.text.trim());
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Resilier'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleTerminate(
    BuildContext context,
    WidgetRef ref,
    DateTime terminationDate,
    String reason,
  ) async {
    final notifier = ref.read(terminateLeaseProvider.notifier);
    final lease = await notifier.terminateLease(
      id: leaseId,
      terminationDate: terminationDate,
      terminationReason: reason,
    );

    if (lease != null && context.mounted) {
      ref.read(leasesProvider.notifier).updateLease(lease);
      ref.invalidate(leaseByIdProvider(leaseId));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le bail a ete resilie'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le bail'),
        content: const Text(
          'Voulez-vous vraiment supprimer ce bail?\n'
          'Cette action est irreversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleDelete(context, ref);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(deleteLeaseProvider.notifier);
    final success = await notifier.deleteLease(leaseId);

    if (success && context.mounted) {
      ref.read(leasesProvider.notifier).removeLease(leaseId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le bail a ete supprime'),
          backgroundColor: Colors.green,
        ),
      );

      context.pop();
    } else if (context.mounted) {
      final error = ref.read(deleteLeaseProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Erreur lors de la suppression'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, Lease lease) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card with status and basic info
          _buildHeaderCard(context, lease),

          const SizedBox(height: 24),

          // Tenant information
          _buildSection(
            context,
            title: 'Locataire',
            icon: Icons.person,
            children: [
              _buildInfoRow(context, Icons.person, 'Nom', lease.tenantFullName),
              if (lease.tenant?.phone != null)
                _buildInfoRow(context, Icons.phone, 'Telephone', lease.tenant!.phoneDisplay),
            ],
          ),

          const SizedBox(height: 24),

          // Unit information
          _buildSection(
            context,
            title: 'Lot',
            icon: Icons.home,
            children: [
              _buildInfoRow(context, Icons.home, 'Reference', lease.unitReference),
              _buildInfoRow(context, Icons.business, 'Immeuble', lease.buildingName),
              if (lease.unit?.typeLabel != null)
                _buildInfoRow(context, Icons.category, 'Type', lease.unit!.typeLabel),
            ],
          ),

          const SizedBox(height: 24),

          // Financial information
          _buildSection(
            context,
            title: 'Montants',
            icon: Icons.payments,
            children: [
              _buildInfoRow(
                context,
                Icons.payments,
                'Loyer',
                _formatFCFA(lease.rentAmount),
                highlight: true,
              ),
              if (lease.chargesAmount > 0)
                _buildInfoRow(
                  context,
                  Icons.receipt_long,
                  'Charges',
                  _formatFCFA(lease.chargesAmount),
                ),
              _buildInfoRow(
                context,
                Icons.account_balance_wallet,
                'Total mensuel',
                _formatFCFA(lease.totalMonthlyAmount),
                highlight: true,
              ),
              if (lease.depositAmount != null && lease.depositAmount! > 0) ...[
                const Divider(height: 24),
                _buildInfoRow(
                  context,
                  Icons.savings,
                  'Caution',
                  _formatFCFA(lease.depositAmount!),
                ),
                _buildInfoRow(
                  context,
                  lease.depositPaid ? Icons.check_circle : Icons.pending,
                  'Statut caution',
                  lease.depositStatusLabel,
                  color: lease.depositStatusColor,
                ),
              ],
            ],
          ),

          const SizedBox(height: 24),

          // Dates section
          _buildSection(
            context,
            title: 'Duree',
            icon: Icons.date_range,
            children: [
              _buildInfoRow(
                context,
                Icons.play_arrow,
                'Debut',
                _formatDate(lease.startDate),
              ),
              if (lease.endDate != null)
                _buildInfoRow(
                  context,
                  Icons.stop,
                  'Fin prevue',
                  _formatDate(lease.endDate!),
                ),
              _buildInfoRow(
                context,
                Icons.schedule,
                'Duree',
                lease.durationLabel,
              ),
              _buildInfoRow(
                context,
                Icons.calendar_month,
                'Jour de paiement',
                'Le ${lease.paymentDay} du mois',
              ),
              if (lease.terminationDate != null) ...[
                const Divider(height: 24),
                _buildInfoRow(
                  context,
                  Icons.event_busy,
                  'Resiliation',
                  _formatDate(lease.terminationDate!),
                  color: Colors.red,
                ),
                if (lease.terminationReason != null)
                  _buildInfoRow(
                    context,
                    Icons.info_outline,
                    'Motif',
                    lease.terminationReason!,
                  ),
              ],
            ],
          ),

          const SizedBox(height: 24),

          // Revision settings
          if (lease.annualRevision)
            ...[
              _buildSection(
                context,
                title: 'Revision annuelle',
                icon: Icons.trending_up,
                children: [
                  _buildInfoRow(context, Icons.check, 'Active', 'Oui'),
                  if (lease.revisionRate != null)
                    _buildInfoRow(
                      context,
                      Icons.percent,
                      'Taux',
                      '${lease.revisionRate}%',
                    ),
                ],
              ),
              const SizedBox(height: 24),
            ],

          // Notes section
          if (lease.notes != null && lease.notes!.isNotEmpty)
            ...[
              _buildSection(
                context,
                title: 'Notes',
                icon: Icons.notes,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      lease.notes!,
                      style: TextStyle(color: Colors.grey[800]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

          // Rent schedules section
          _buildRentSchedulesSection(context, ref),

          const SizedBox(height: 24),

          // Receipts section
          _buildReceiptsSection(context, ref),
        ],
      ),
    );
  }

  Widget _buildReceiptsSection(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.picture_as_pdf, color: Theme.of(context).primaryColor, size: 20),
            const SizedBox(width: 8),
            Text(
              'Quittances',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: LeaseReceiptsList(
              leaseId: leaseId,
              showHeader: false,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCard(BuildContext context, Lease lease) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Icon and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: lease.statusColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.description,
                      color: lease.statusColor,
                      size: 32,
                    ),
                  ),
                ),
                LeaseStatusBadge(status: lease.status),
              ],
            ),

            const SizedBox(height: 16),

            // Tenant name
            Text(
              lease.tenantFullName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 4),

            // Unit reference
            Text(
              lease.fullAddress,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Total monthly amount
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_formatFCFA(lease.totalMonthlyAmount)} / mois',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: children,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    bool highlight = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
                color: color ?? (highlight ? Theme.of(context).primaryColor : Colors.black87),
                fontSize: 14,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRentSchedulesSection(BuildContext context, WidgetRef ref) {
    final schedulesAsync = ref.watch(rentSchedulesProvider(leaseId));
    final summaryAsync = ref.watch(rentSchedulesSummaryProvider(leaseId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.receipt_long, color: Theme.of(context).primaryColor, size: 20),
            const SizedBox(width: 8),
            Text(
              'Echeances',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Summary card
        summaryAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (error, stack) => const SizedBox.shrink(),
          data: (summary) => Card(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem(
                    context,
                    label: 'Payees',
                    value: summary.paidCount.toString(),
                    color: Colors.green,
                  ),
                  _buildSummaryItem(
                    context,
                    label: 'En attente',
                    value: summary.pendingCount.toString(),
                    color: Colors.orange,
                  ),
                  _buildSummaryItem(
                    context,
                    label: 'En retard',
                    value: summary.overdueCount.toString(),
                    color: Colors.red,
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Schedules list
        schedulesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text('Erreur: $error'),
          data: (schedules) {
            if (schedules.isEmpty) {
              return Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: Text('Aucune echeance')),
                ),
              );
            }

            // Show only last 6 schedules
            final displaySchedules = schedules.take(6).toList();

            return Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  ...displaySchedules.map((schedule) => _buildScheduleRow(context, ref, schedule)),
                  if (schedules.length > 6)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: TextButton(
                        onPressed: () {
                          // TODO: Navigate to full schedules page
                        },
                        child: Text('Voir toutes les ${schedules.length} echeances'),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSummaryItem(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleRow(BuildContext context, WidgetRef ref, RentSchedule schedule) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        leading: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: schedule.statusColor,
            shape: BoxShape.circle,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                schedule.periodLabel,
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              ),
            ),
            Text(
              schedule.isPaid ? schedule.amountDueFormatted : schedule.balanceFormatted,
              style: TextStyle(
                color: schedule.isPaid ? Colors.green : null,
                fontWeight: schedule.isOverdue ? FontWeight.w600 : null,
                fontSize: 14,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: schedule.statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  schedule.statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    color: schedule.statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (schedule.amountPaid > 0) ...[
                const SizedBox(width: 8),
                PaymentHistoryInline(scheduleId: schedule.id),
              ],
            ],
          ),
        ),
        children: [
          // Payment history
          PaymentHistoryList(
            scheduleId: schedule.id,
            showHeader: true,
            compact: true,
          ),

          // Record payment button
          if (schedule.canRecordPayment) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showRecordPaymentDialog(context, ref, schedule),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Enregistrer un paiement'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showRecordPaymentDialog(
    BuildContext context,
    WidgetRef ref,
    RentSchedule schedule,
  ) {
    // Get tenant name from lease if available
    final leaseAsync = ref.read(leaseByIdProvider(leaseId));
    final tenantName = leaseAsync.valueOrNull?.tenantFullName;

    PaymentFormModal.show(
      context: context,
      schedule: schedule,
      tenantName: tenantName,
      onPaymentCreated: () {
        // Refresh schedules after payment
        ref.invalidate(rentSchedulesProvider(leaseId));
        ref.invalidate(rentSchedulesSummaryProvider(leaseId));
      },
    );
  }

  Widget _buildErrorState(BuildContext context, String error, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.red[700],
                  ),
            ),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(leaseByIdProvider(leaseId)),
              icon: const Icon(Icons.refresh),
              label: const Text('Reessayer'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatFCFA(double amount) {
    final formatter = NumberFormat('#,###', 'fr_FR');
    return '${formatter.format(amount.round())} FCFA';
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
}
