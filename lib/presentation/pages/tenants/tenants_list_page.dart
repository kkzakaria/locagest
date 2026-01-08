import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../providers/tenants_provider.dart';
import '../../widgets/tenants/tenant_card.dart';

/// Page displaying the list of tenants with search functionality, pagination, and empty state
class TenantsListPage extends ConsumerStatefulWidget {
  const TenantsListPage({super.key});

  @override
  ConsumerState<TenantsListPage> createState() => _TenantsListPageState();
}

class _TenantsListPageState extends ConsumerState<TenantsListPage> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Load tenants on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tenantsProvider.notifier).loadTenants();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      ref.read(tenantsProvider.notifier).loadMore();
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  Future<void> _refresh() async {
    _searchController.clear();
    await ref.read(tenantsProvider.notifier).refresh();
  }

  void _onSearchChanged(String query) {
    ref.read(tenantsProvider.notifier).searchTenants(query);
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(tenantsProvider.notifier).searchTenants('');
  }

  @override
  Widget build(BuildContext context) {
    final tenantsState = ref.watch(tenantsProvider);
    final canManage = ref.watch(canManageTenantsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Locataires'),
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: tenantsState.isLoading ? null : _refresh,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          _buildSearchBar(tenantsState),

          // List
          Expanded(
            child: _buildBody(tenantsState),
          ),
        ],
      ),
      floatingActionButton: canManage.maybeWhen(
        data: (canManage) => canManage
            ? FloatingActionButton.extended(
                onPressed: () => context.push(AppRoutes.tenantNew),
                icon: const Icon(Icons.person_add),
                label: const Text('Ajouter'),
              )
            : null,
        orElse: () => null,
      ),
    );
  }

  Widget _buildSearchBar(TenantsState state) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Rechercher par nom ou telephone...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: state.searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _clearSearch,
                  tooltip: 'Effacer',
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildBody(TenantsState state) {
    // Error state
    if (state.error != null && state.tenants.isEmpty) {
      return _buildErrorState(state.error!);
    }

    // Loading initial data
    if (state.isLoading && state.tenants.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Empty state (no tenants at all)
    if (state.tenants.isEmpty && !state.isLoading && state.searchQuery.isEmpty) {
      return _buildEmptyState();
    }

    // No search results
    if (state.tenants.isEmpty && !state.isLoading && state.searchQuery.isNotEmpty) {
      return _buildNoResultsState(state.searchQuery);
    }

    // List with data
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: state.tenants.length + (state.hasMore && state.searchQuery.isEmpty ? 1 : 0),
        itemBuilder: (context, index) {
          // Loading indicator at the end
          if (index == state.tenants.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final tenant = state.tenants[index];
          return TenantCard(
            tenant: tenant,
            onTap: () => context.push('${AppRoutes.tenants}/${tenant.id}'),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final canManage = ref.watch(canManageTenantsProvider);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Aucun locataire',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[700],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Commencez par ajouter votre premier locataire\npour gerer vos locations.',
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
                      onPressed: () => context.push(AppRoutes.tenantNew),
                      icon: const Icon(Icons.person_add),
                      label: const Text('Ajouter un locataire'),
                    )
                  : const SizedBox.shrink(),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState(String query) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun resultat',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[700],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aucun locataire ne correspond a\n"$query"',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: _clearSearch,
              icon: const Icon(Icons.clear),
              label: const Text('Effacer la recherche'),
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
