import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/tenant.dart';
import '../../providers/tenants_provider.dart';
import '../../widgets/tenants/tenant_form.dart';

/// Page for creating a new tenant
class TenantFormPage extends ConsumerWidget {
  const TenantFormPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau locataire'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _handleClose(context, ref),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: TenantForm(
                onSuccess: (tenant) => _handleSuccess(context, tenant),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleClose(BuildContext context, WidgetRef ref) {
    // Reset provider state when closing
    ref.read(createTenantProvider.notifier).reset();
    context.pop();
  }

  void _handleSuccess(BuildContext context, Tenant tenant) {
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Le locataire a ete cree avec succes'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Navigate back to the list
    context.pop();
  }
}
