import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/lease.dart';
import '../../providers/leases_provider.dart';
import '../../widgets/leases/lease_form.dart';

/// Page for editing an existing lease
class LeaseEditPage extends ConsumerWidget {
  final String leaseId;

  const LeaseEditPage({
    super.key,
    required this.leaseId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaseAsync = ref.watch(leaseByIdProvider(leaseId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le bail'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _handleClose(context, ref),
        ),
      ),
      body: leaseAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text('Erreur: $error'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(leaseByIdProvider(leaseId)),
                icon: const Icon(Icons.refresh),
                label: const Text('Reessayer'),
              ),
            ],
          ),
        ),
        data: (lease) {
          // Check if lease can be edited
          if (!lease.canBeEdited) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Ce bail ne peut pas etre modifie',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Seuls les baux en attente ou actifs peuvent etre modifies.',
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Retour'),
                    ),
                  ],
                ),
              ),
            );
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: LeaseForm(
                    lease: lease,
                    onSuccess: (updatedLease) => _handleSuccess(context, updatedLease),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleClose(BuildContext context, WidgetRef ref) {
    // Reset provider state when closing
    ref.read(editLeaseProvider.notifier).reset();
    context.pop();
  }

  void _handleSuccess(BuildContext context, Lease lease) {
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Le bail a ete modifie avec succes'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Navigate back
    context.pop();
  }
}
