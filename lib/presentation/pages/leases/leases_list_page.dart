import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../domain/entities/lease.dart';
import '../../providers/leases_provider.dart';
import '../../widgets/leases/lease_card.dart';

/// Page displaying the list of leases with filtering, pagination, and empty state
class LeasesListPage extends ConsumerStatefulWidget {
  const LeasesListPage({super.key});

  @override
  ConsumerState<LeasesListPage> createState() => _LeasesListPageState();
}

class _LeasesListPageState extends ConsumerState<LeasesListPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Load leases on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(leasesProvider.notifier).loadLeases();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      ref.read(leasesProvider.notifier).loadMore();
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  Future<void> _refresh() async {
    await ref.read(leasesProvider.notifier).refresh();
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _FilterBottomSheet(
        currentFilter: ref.read(leasesProvider).statusFilter,
        onFilterChanged: (status) {
          ref.read(leasesProvider.notifier).setStatusFilter(status);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final leasesState = ref.watch(leasesProvider);
    final canManage = ref.watch(canManageLeasesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Baux'),
        actions: [
          // Filter button
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showFilterDialog,
                tooltip: 'Filtrer',
              ),
              if (leasesState.statusFilter != null)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: leasesState.isLoading ? null : _refresh,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          // Active filter chip
          if (leasesState.statusFilter != null) _buildActiveFilterChip(leasesState),

          // List
          Expanded(
            child: _buildBody(leasesState),
          ),
        ],
      ),
      floatingActionButton: canManage.maybeWhen(
        data: (canManage) => canManage
            ? FloatingActionButton.extended(
                onPressed: () => context.push(AppRoutes.leaseNew),
                icon: const Icon(Icons.add),
                label: const Text('Nouveau bail'),
              )
            : null,
        orElse: () => null,
      ),
    );
  }

  Widget _buildActiveFilterChip(LeasesState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[100],
      child: Row(
        children: [
          const Text(
            'Filtre actif: ',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
          Chip(
            label: Text(_getStatusLabel(state.statusFilter!)),
            deleteIcon: const Icon(Icons.close, size: 16),
            onDeleted: () {
              ref.read(leasesProvider.notifier).setStatusFilter(null);
            },
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  String _getStatusLabel(LeaseStatus status) {
    switch (status) {
      case LeaseStatus.pending:
        return 'En attente';
      case LeaseStatus.active:
        return 'Actif';
      case LeaseStatus.terminated:
        return 'Résilié';
      case LeaseStatus.expired:
        return 'Expiré';
    }
  }

  Widget _buildBody(LeasesState state) {
    // Error state
    if (state.error != null && state.leases.isEmpty) {
      return _buildErrorState(state.error!);
    }

    // Loading initial data
    if (state.isLoading && state.leases.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Empty state (no leases at all)
    if (state.leases.isEmpty && !state.isLoading) {
      return _buildEmptyState(state.statusFilter != null);
    }

    // List with data
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: state.leases.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Loading indicator at the end
          if (index == state.leases.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final lease = state.leases[index];
          return LeaseCard(
            lease: lease,
            onTap: () => context.push('${AppRoutes.leases}/${lease.id}'),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool hasFilter) {
    final canManage = ref.watch(canManageLeasesProvider);

    if (hasFilter) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.filter_list_off,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Aucun bail correspondant',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.grey[700],
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Aucun bail ne correspond aux filtres sélectionnés.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: () {
                  ref.read(leasesProvider.notifier).clearFilters();
                },
                icon: const Icon(Icons.clear),
                label: const Text('Effacer les filtres'),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Aucun bail',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[700],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Commencez par creer votre premier bail\npour gerer vos locations.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            canManage.maybeWhen(
              data: (canManage) => canManage
                  ? ElevatedButton.icon(
                      onPressed: () => context.push(AppRoutes.leaseNew),
                      icon: const Icon(Icons.add),
                      label: const Text('Creer un bail'),
                    )
                  : const SizedBox.shrink(),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.red[700],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet for filtering leases by status
class _FilterBottomSheet extends StatelessWidget {
  final LeaseStatus? currentFilter;
  final void Function(LeaseStatus?) onFilterChanged;

  const _FilterBottomSheet({
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              'Filtrer par statut',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),

            // All option
            _buildFilterOption(
              context,
              label: 'Tous les baux',
              isSelected: currentFilter == null,
              onTap: () => onFilterChanged(null),
            ),

            const Divider(height: 1),

            // Status options
            _buildFilterOption(
              context,
              label: 'Actifs',
              icon: Icons.check_circle_outline,
              color: Colors.green,
              isSelected: currentFilter == LeaseStatus.active,
              onTap: () => onFilterChanged(LeaseStatus.active),
            ),

            _buildFilterOption(
              context,
              label: 'En attente',
              icon: Icons.schedule_outlined,
              color: Colors.orange,
              isSelected: currentFilter == LeaseStatus.pending,
              onTap: () => onFilterChanged(LeaseStatus.pending),
            ),

            _buildFilterOption(
              context,
              label: 'Résiliés',
              icon: Icons.cancel_outlined,
              color: Colors.red,
              isSelected: currentFilter == LeaseStatus.terminated,
              onTap: () => onFilterChanged(LeaseStatus.terminated),
            ),

            _buildFilterOption(
              context,
              label: 'Expirés',
              icon: Icons.event_busy_outlined,
              color: Colors.grey,
              isSelected: currentFilter == LeaseStatus.expired,
              onTap: () => onFilterChanged(LeaseStatus.expired),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(
    BuildContext context, {
    required String label,
    IconData? icon,
    Color? color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: icon != null
          ? Icon(icon, color: color)
          : const Icon(Icons.list, color: Colors.grey),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check, color: Theme.of(context).primaryColor)
          : null,
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      selectedTileColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
      selected: isSelected,
    );
  }
}
