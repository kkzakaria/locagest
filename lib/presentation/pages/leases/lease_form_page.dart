import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/lease.dart';
import '../../providers/leases_provider.dart';
import '../../widgets/leases/lease_form.dart';

/// Page for creating a new lease
class LeaseFormPage extends ConsumerWidget {
  /// Pre-selected unit ID (when creating from unit detail)
  final String? unitId;

  /// Pre-selected tenant ID (when creating from tenant detail)
  final String? tenantId;

  const LeaseFormPage({
    super.key,
    this.unitId,
    this.tenantId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau bail'),
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
              child: LeaseForm(
                preselectedUnitId: unitId,
                preselectedTenantId: tenantId,
                onSuccess: (lease) => _handleSuccess(context, lease),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleClose(BuildContext context, WidgetRef ref) {
    // Reset provider state when closing
    ref.read(createLeaseProvider.notifier).reset();
    context.pop();
  }

  void _handleSuccess(BuildContext context, Lease lease) {
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Le bail a ete cree avec succes'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Navigate back to the list
    context.pop();
  }
}
