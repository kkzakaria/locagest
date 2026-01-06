import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../providers/buildings_provider.dart';
import '../../widgets/buildings/building_card.dart';

/// Page displaying the list of buildings with pagination and empty state
class BuildingsListPage extends ConsumerStatefulWidget {
  const BuildingsListPage({super.key});

  @override
  ConsumerState<BuildingsListPage> createState() => _BuildingsListPageState();
}

class _BuildingsListPageState extends ConsumerState<BuildingsListPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Load buildings on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(buildingsProvider.notifier).loadBuildings();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      ref.read(buildingsProvider.notifier).loadMore();
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  Future<void> _refresh() async {
    await ref.read(buildingsProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final buildingsState = ref.watch(buildingsProvider);
    final canManage = ref.watch(canManageBuildingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Immeubles'),
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: buildingsState.isLoading ? null : _refresh,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _buildBody(buildingsState),
      floatingActionButton: canManage.maybeWhen(
        data: (canManage) => canManage
            ? FloatingActionButton.extended(
                onPressed: () => context.push(AppRoutes.buildingNew),
                icon: const Icon(Icons.add),
                label: const Text('Nouvel immeuble'),
              )
            : null,
        orElse: () => null,
      ),
    );
  }

  Widget _buildBody(BuildingsState state) {
    // Error state
    if (state.error != null && state.buildings.isEmpty) {
      return _buildErrorState(state.error!);
    }

    // Loading initial data
    if (state.isLoading && state.buildings.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Empty state
    if (state.buildings.isEmpty && !state.isLoading) {
      return _buildEmptyState();
    }

    // List with data
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: state.buildings.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Loading indicator at the end
          if (index == state.buildings.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final building = state.buildings[index];
          return BuildingCard(
            building: building,
            onTap: () => context.push('${AppRoutes.buildings}/${building.id}'),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final canManage = ref.watch(canManageBuildingsProvider);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.apartment_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Aucun immeuble',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[700],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Commencez par ajouter votre premier immeuble\npour gerer vos biens immobiliers.',
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
                      onPressed: () => context.push(AppRoutes.buildingNew),
                      icon: const Icon(Icons.add),
                      label: const Text('Ajouter un immeuble'),
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
              label: const Text('Reessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
