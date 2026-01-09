import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/payment.dart';
import '../../providers/payments_provider.dart';

/// Modal bottom sheet for editing an existing payment
class PaymentEditModal extends ConsumerStatefulWidget {
  final Payment payment;
  final VoidCallback? onPaymentUpdated;
  final VoidCallback? onPaymentDeleted;

  const PaymentEditModal({
    super.key,
    required this.payment,
    this.onPaymentUpdated,
    this.onPaymentDeleted,
  });

  /// Show the payment edit modal
  static Future<void> show({
    required BuildContext context,
    required Payment payment,
    VoidCallback? onPaymentUpdated,
    VoidCallback? onPaymentDeleted,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => PaymentEditModal(
        payment: payment,
        onPaymentUpdated: onPaymentUpdated,
        onPaymentDeleted: onPaymentDeleted,
      ),
    );
  }

  @override
  ConsumerState<PaymentEditModal> createState() => _PaymentEditModalState();
}

class _PaymentEditModalState extends ConsumerState<PaymentEditModal> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _checkNumberController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _notesController = TextEditingController();

  late PaymentMethod _selectedMethod;
  late DateTime _paymentDate;

  @override
  void initState() {
    super.initState();
    // Pre-fill with existing values
    _amountController.text = widget.payment.amount.toStringAsFixed(0);
    _selectedMethod = widget.payment.paymentMethod;
    _paymentDate = widget.payment.paymentDate;
    _referenceController.text = widget.payment.reference ?? '';
    _checkNumberController.text = widget.payment.checkNumber ?? '';
    _bankNameController.text = widget.payment.bankName ?? '';
    _notesController.text = widget.payment.notes ?? '';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _checkNumberController.dispose();
    _bankNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _needsCheckFields => _selectedMethod == PaymentMethod.check;

  bool get _needsReference =>
      _selectedMethod == PaymentMethod.transfer ||
      _selectedMethod == PaymentMethod.mobileMoney;

  @override
  Widget build(BuildContext context) {
    final updateState = ref.watch(updatePaymentProvider);
    final deleteState = ref.watch(deletePaymentProvider);
    final isLoading = updateState.isLoading || deleteState.isLoading;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Modifier le paiement',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Reçu: ${widget.payment.receiptNumber}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Delete button
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red[400]),
                    onPressed: isLoading ? null : _confirmDelete,
                    tooltip: 'Supprimer',
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Form
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Original info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Date originale',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            Text(
                              widget.payment.paymentDateFormatted,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Amount field
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          labelText: 'Montant *',
                          hintText: 'Montant du paiement',
                          prefixIcon: Icon(Icons.payments),
                          suffixText: 'FCFA',
                        ),
                        validator: (value) {
                          final amount = double.tryParse(value ?? '');
                          if (amount == null || amount <= 0) {
                            return 'Le montant doit être supérieur à 0';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Payment method
                      Text(
                        'Méthode de paiement *',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: PaymentMethod.values.map((method) {
                          final isSelected = _selectedMethod == method;
                          return ChoiceChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  method.icon,
                                  size: 18,
                                  color: isSelected ? Colors.white : null,
                                ),
                                const SizedBox(width: 6),
                                Text(method.label),
                              ],
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedMethod = method);
                              }
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 16),

                      // Payment date
                      InkWell(
                        onTap: _selectDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date de paiement *',
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            DateFormat('dd/MM/yyyy').format(_paymentDate),
                          ),
                        ),
                      ),

                      // Conditional: Check fields
                      if (_needsCheckFields) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _checkNumberController,
                          decoration: const InputDecoration(
                            labelText: 'Numéro de chèque *',
                            hintText: 'Ex: 1234567',
                            prefixIcon: Icon(Icons.numbers),
                          ),
                          validator: (value) {
                            if (_needsCheckFields && (value == null || value.isEmpty)) {
                              return 'Le numéro de chèque est requis';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _bankNameController,
                          decoration: const InputDecoration(
                            labelText: 'Nom de la banque',
                            hintText: 'Ex: BIAO, SIB, SGBCI...',
                            prefixIcon: Icon(Icons.account_balance),
                          ),
                        ),
                      ],

                      // Conditional: Reference field
                      if (_needsReference) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _referenceController,
                          decoration: InputDecoration(
                            labelText: _selectedMethod == PaymentMethod.mobileMoney
                                ? 'Référence transaction *'
                                : 'Référence virement *',
                            hintText: _selectedMethod == PaymentMethod.mobileMoney
                                ? 'Ex: TXN123456789'
                                : 'Ex: VIR-2026-01-001',
                            prefixIcon: const Icon(Icons.tag),
                          ),
                          validator: (value) {
                            if (_needsReference && (value == null || value.isEmpty)) {
                              return 'La référence est requise';
                            }
                            return null;
                          },
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Notes
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                          hintText: 'Notes optionnelles...',
                          prefixIcon: Icon(Icons.notes),
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),

            // Error message
            if (updateState.error != null || deleteState.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          updateState.error ?? deleteState.error ?? '',
                          style: TextStyle(color: Colors.red[700], fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Submit button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _submitUpdate,
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Enregistrer les modifications'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('fr', 'FR'),
    );

    if (picked != null) {
      setState(() => _paymentDate = picked);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le paiement'),
        content: const Text(
          'Voulez-vous vraiment supprimer ce paiement ? '
          'Cette action est irréversible et le statut de l\'échéance sera recalculé.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deletePayment();
    }
  }

  Future<void> _deletePayment() async {
    final notifier = ref.read(deletePaymentProvider.notifier);
    final success = await notifier.deletePayment(widget.payment.id);

    if (success && mounted) {
      // Reset the provider state
      ref.read(deletePaymentProvider.notifier).reset();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paiement supprimé avec succès'),
          backgroundColor: Colors.green,
        ),
      );

      // Close modal
      Navigator.pop(context);

      // Notify callback
      widget.onPaymentDeleted?.call();
    }
  }

  Future<void> _submitUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text);
    final notifier = ref.read(updatePaymentProvider.notifier);

    final payment = await notifier.updatePayment(
      id: widget.payment.id,
      amount: amount,
      paymentDate: _paymentDate,
      paymentMethod: _selectedMethod.toJson(),
      reference: _needsReference ? _referenceController.text.trim() : null,
      checkNumber: _needsCheckFields ? _checkNumberController.text.trim() : null,
      bankName: _needsCheckFields && _bankNameController.text.isNotEmpty
          ? _bankNameController.text.trim()
          : null,
      notes: _notesController.text.isNotEmpty ? _notesController.text.trim() : null,
    );

    if (payment != null && mounted) {
      // Reset the provider state
      ref.read(updatePaymentProvider.notifier).reset();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paiement modifié avec succès'),
          backgroundColor: Colors.green,
        ),
      );

      // Close modal
      Navigator.pop(context);

      // Notify callback
      widget.onPaymentUpdated?.call();
    }
  }
}
