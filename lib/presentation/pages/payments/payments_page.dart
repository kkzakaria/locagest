import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../domain/repositories/payment_repository.dart';
import '../../providers/payments_provider.dart';
import '../../widgets/payments/rent_schedule_card.dart';
import 'payment_form_modal.dart';

/// Main payments page showing all rent schedules with filtering
class PaymentsPage extends ConsumerStatefulWidget {
  const PaymentsPage({super.key});

  @override
  ConsumerState<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends ConsumerState<PaymentsPage> {
  final _scrollController = ScrollController();
  String? _selectedStatus;
  DateTime? _selectedPeriod;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Load schedules on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(allSchedulesProvider.notifier).loadSchedules();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(allSchedulesProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final schedulesState = ref.watch(allSchedulesProvider);
    final summaryAsync = ref.watch(paymentsSummaryProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Paiements',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => ref.read(allSchedulesProvider.notifier).refresh(),
                  tooltip: 'Actualiser',
                ),
              ],
            ),
          ),
          // Summary cards
          summaryAsync.when(
            loading: () => const SizedBox(height: 100),
            error: (error, stack) => const SizedBox.shrink(),
            data: (summary) => _buildSummarySection(context, summary),
          ),

          // Filters
          _buildFiltersSection(context),

          // Schedules list
          Expanded(
            child: schedulesState.isLoading && schedulesState.schedules.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : schedulesState.error != null && schedulesState.schedules.isEmpty
                    ? _buildErrorState(context, schedulesState.error!)
                    : schedulesState.schedules.isEmpty
                        ? _buildEmptyState(context)
                        : _buildSchedulesList(context, schedulesState),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(BuildContext context, PaymentsSummary summary) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              context,
              icon: Icons.account_balance_wallet,
              label: 'Dû ce mois',
              value: _formatFCFA(summary.totalDueThisMonth),
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSummaryCard(
              context,
              icon: Icons.check_circle,
              label: 'Collecté',
              value: _formatFCFA(summary.totalPaidThisMonth),
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSummaryCard(
              context,
              icon: Icons.warning,
              label: 'Impayés',
              value: _formatFCFA(summary.totalOverdue),
              color: Colors.red,
              badge: summary.overdueCount > 0 ? summary.overdueCount.toString() : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    String? badge,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const Spacer(),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
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
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Status filter
          Expanded(
            child: _buildStatusFilter(context),
          ),
          const SizedBox(width: 8),
          // Period filter
          _buildPeriodFilter(context),
        ],
      ),
    );
  }

  Widget _buildStatusFilter(BuildContext context) {
    final statuses = [
      (null, 'Tous'),
      ('pending', 'En attente'),
      ('partial', 'Partiel'),
      ('paid', 'Payé'),
      ('overdue', 'En retard'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: statuses.map((status) {
          final isSelected = _selectedStatus == status.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(status.$2),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedStatus = selected ? status.$1 : null);
                ref.read(allSchedulesProvider.notifier).setStatusFilter(
                      selected ? status.$1 : null,
                    );
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPeriodFilter(BuildContext context) {
    return InkWell(
      onTap: _showPeriodPicker,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_month, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              _selectedPeriod != null
                  ? DateFormat('MMM yyyy', 'fr_FR').format(_selectedPeriod!)
                  : 'Période',
              style: TextStyle(
                fontSize: 13,
                color: _selectedPeriod != null ? Colors.black : Colors.grey[600],
              ),
            ),
            if (_selectedPeriod != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  setState(() => _selectedPeriod = null);
                  ref.read(allSchedulesProvider.notifier).setPeriodFilter(null, null);
                },
                child: Icon(Icons.close, size: 16, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showPeriodPicker() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedPeriod ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
      locale: const Locale('fr', 'FR'),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null) {
      final monthStart = DateTime(picked.year, picked.month, 1);
      final monthEnd = DateTime(picked.year, picked.month + 1, 0);

      setState(() => _selectedPeriod = picked);
      ref.read(allSchedulesProvider.notifier).setPeriodFilter(monthStart, monthEnd);
    }
  }

  Widget _buildSchedulesList(BuildContext context, AllSchedulesState state) {
    return RefreshIndicator(
      onRefresh: () => ref.read(allSchedulesProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: state.schedules.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.schedules.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final schedule = state.schedules[index];
          return RentScheduleCard(
            scheduleWithDetails: schedule,
            onTap: () => _navigateToLease(schedule),
            onRecordPayment: schedule.schedule.canRecordPayment
                ? () => _showPaymentModal(schedule)
                : null,
          );
        },
      ),
    );
  }

  void _navigateToLease(RentScheduleWithDetails schedule) {
    if (schedule.leaseId != null) {
      context.push('${AppRoutes.leases}/${schedule.leaseId}');
    }
  }

  void _showPaymentModal(RentScheduleWithDetails schedule) {
    PaymentFormModal.show(
      context: context,
      schedule: schedule.schedule,
      tenantName: schedule.tenantName,
      onPaymentCreated: () {
        // Refresh the schedules list and summary
        ref.invalidate(allSchedulesProvider);
        ref.invalidate(paymentsSummaryProvider);
        ref.read(allSchedulesProvider.notifier).refresh();
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune échéance trouvée',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[700],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Les échéances de loyer apparaîtront ici',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.red[700],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.read(allSchedulesProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
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
}
