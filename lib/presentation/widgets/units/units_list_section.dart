import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/unit.dart';
import '../../providers/units_provider.dart';
import 'unit_card.dart';

/// Section widget displaying units list for a building
/// Includes loading, error, and empty states with French text
class UnitsListSection extends ConsumerStatefulWidget {
  final String buildingId;
  final bool canManage;

  const UnitsListSection({
    super.key,
    required this.buildingId,
    required this.canManage,
  });

  @override
  ConsumerState<UnitsListSection> createState() => _UnitsListSectionState();
}

class _UnitsListSectionState extends ConsumerState<UnitsListSection> {
  @override
  void initState() {
    super.initState();
    // Load units when widget initializes
    Future.microtask(() {
      ref.read(unitsByBuildingProvider(widget.buildingId).notifier).loadUnits();
    });
  }

  @override
  Widget build(BuildContext context) {
    final unitsState = ref.watch(unitsByBuildingProvider(widget.buildingId));

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.door_front_door,
                  size: 20,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Lots',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                // Add unit button (for gestionnaire/admin)
                if (widget.canManage)
                  TextButton.icon(
                    onPressed: () => _navigateToCreateUnit(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Ajouter'),
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content based on state
          _buildContent(context, unitsState),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, UnitsState state) {
    // Error state
    if (state.error != null && state.units.isEmpty) {
      return _buildErrorState(context, state.error!);
    }

    // Loading state (initial load)
    if (state.isLoading && state.units.isEmpty) {
      return _buildLoadingState();
    }

    // Empty state
    if (state.units.isEmpty) {
      return _buildEmptyState(context);
    }

    // Units list
    return _buildUnitsList(context, state);
  }

  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Chargement des lots...',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red[400],
            ),
            const SizedBox(height: 12),
            Text(
              'Erreur lors du chargement des lots',
              style: TextStyle(
                color: Colors.red[700],
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getErrorMessage(error),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                ref.read(unitsByBuildingProvider(widget.buildingId).notifier).refresh();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.door_front_door_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'Aucun lot dans cet immeuble',
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez votre premier lot pour commencer',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
            if (widget.canManage) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _navigateToCreateUnit(context),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter un lot'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUnitsList(BuildContext context, UnitsState state) {
    return Column(
      children: [
        // Units count summary
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                state.units.length == 1
                    ? '1 lot'
                    : '${state.units.length} lots',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              // Status summary
              _buildStatusSummary(state.units),
            ],
          ),
        ),

        // Units list
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 8),
          itemCount: state.units.length + (state.isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            // Loading indicator at the end
            if (index >= state.units.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final unit = state.units[index];
            return UnitCard(
              unit: unit,
              onTap: () => _navigateToUnitDetail(context, unit),
            );
          },
        ),

        // Load more button
        if (state.hasMore && !state.isLoading)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: TextButton(
              onPressed: () {
                ref.read(unitsByBuildingProvider(widget.buildingId).notifier).loadMore();
              },
              child: const Text('Charger plus'),
            ),
          ),

        // Error message (for pagination errors)
        if (state.error != null && state.units.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning, size: 16, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Text(
                  _getErrorMessage(state.error!),
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStatusSummary(List<Unit> units) {
    final vacant = units.where((u) => u.status == UnitStatus.vacant).length;
    final occupied = units.where((u) => u.status == UnitStatus.occupied).length;
    final maintenance = units.where((u) => u.status == UnitStatus.maintenance).length;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (occupied > 0) _buildStatusChip(Colors.green, '$occupied'),
        if (vacant > 0) _buildStatusChip(Colors.red, '$vacant'),
        if (maintenance > 0) _buildStatusChip(Colors.orange, '$maintenance'),
      ],
    );
  }

  Widget _buildStatusChip(Color color, String count) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            count,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getErrorMessage(String error) {
    // Map technical errors to French user-friendly messages
    if (error.contains('UnitUnauthorizedException')) {
      return 'Vous n\'avez pas les droits pour voir ces lots';
    }
    if (error.contains('network') || error.contains('Connection')) {
      return 'Erreur de connexion. Vérifiez votre connexion internet.';
    }
    return 'Une erreur est survenue. Veuillez réessayer.';
  }

  void _navigateToCreateUnit(BuildContext context) {
    context.push('/buildings/${widget.buildingId}/units/create');
  }

  void _navigateToUnitDetail(BuildContext context, Unit unit) {
    context.push('/buildings/${widget.buildingId}/units/${unit.id}');
  }
}
