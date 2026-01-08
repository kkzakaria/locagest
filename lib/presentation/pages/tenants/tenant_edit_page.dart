import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/tenant.dart';
import '../../providers/tenants_provider.dart';
import '../../widgets/tenants/tenant_form.dart';

/// Page for editing an existing tenant
class TenantEditPage extends ConsumerWidget {
  final String tenantId;

  const TenantEditPage({
    super.key,
    required this.tenantId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenantAsync = ref.watch(tenantByIdProvider(tenantId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le locataire'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _handleClose(context, ref),
        ),
      ),
      body: tenantAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(context, error.toString(), ref),
        data: (tenant) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: TenantForm(
                  tenant: tenant,
                  onSuccess: (updatedTenant) => _handleSuccess(context, updatedTenant),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleClose(BuildContext context, WidgetRef ref) {
    // Reset provider state when closing
    ref.read(editTenantProvider.notifier).reset();
    context.pop();
  }

  void _handleSuccess(BuildContext context, Tenant tenant) {
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Le locataire a ete modifie avec succes'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Navigate back to detail page
    context.pop();
  }

  Widget _buildErrorState(BuildContext context, String error, WidgetRef ref) {
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
              onPressed: () => ref.invalidate(tenantByIdProvider(tenantId)),
              icon: const Icon(Icons.refresh),
              label: const Text('Reessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
