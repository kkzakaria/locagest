import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/payment.dart';
import '../../../domain/entities/rent_schedule.dart';
import '../../providers/payments_provider.dart';

/// Modal bottom sheet for recording a new payment
class PaymentFormModal extends ConsumerStatefulWidget {
  final RentSchedule schedule;
  final String? tenantName;
  final VoidCallback? onPaymentCreated;

  const PaymentFormModal({
    super.key,
    required this.schedule,
    this.tenantName,
    this.onPaymentCreated,
  });

  /// Show the payment form modal
  static Future<void> show({
    required BuildContext context,
    required RentSchedule schedule,
    String? tenantName,
    VoidCallback? onPaymentCreated,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => PaymentFormModal(
        schedule: schedule,
        tenantName: tenantName,
        onPaymentCreated: onPaymentCreated,
      ),
    );
  }

  @override
  ConsumerState<PaymentFormModal> createState() => _PaymentFormModalState();
}

class _PaymentFormModalState extends ConsumerState<PaymentFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _checkNumberController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _notesController = TextEditingController();

  PaymentMethod _selectedMethod = PaymentMethod.cash;
  DateTime _paymentDate = DateTime.now();
  bool _showOverpaymentWarning = false;

  @override
  void initState() {
    super.initState();
    // Default to remaining balance
    _amountController.text = widget.schedule.remainingBalance.toStringAsFixed(0);
    _amountController.addListener(_checkOverpayment);
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

  void _checkOverpayment() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final isOverpaying = amount > widget.schedule.remainingBalance;
    if (isOverpaying != _showOverpaymentWarning) {
      setState(() => _showOverpaymentWarning = isOverpaying);
    }
  }

  bool get _needsCheckFields => _selectedMethod == PaymentMethod.check;

  bool get _needsReference =>
      _selectedMethod == PaymentMethod.transfer ||
      _selectedMethod == PaymentMethod.mobileMoney;

  @override
  Widget build(BuildContext context) {
    final createState = ref.watch(createPaymentProvider);

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
                          'Enregistrer un paiement',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.schedule.periodLabel,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        if (widget.tenantName != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.tenantName!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
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
                      // Balance info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Solde restant'),
                            Text(
                              widget.schedule.remainingBalanceFormatted,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
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

                      // Overpayment warning
                      if (_showOverpaymentWarning) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.orange.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber, color: Colors.orange[700], size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Le montant dépasse le solde restant',
                                  style: TextStyle(
                                    color: Colors.orange[700],
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

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
            if (createState.error != null)
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
                          createState.error!,
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
                    onPressed: createState.isLoading ? null : _submitPayment,
                    child: createState.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Enregistrer le paiement'),
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

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text);
    final notifier = ref.read(createPaymentProvider.notifier);

    final payment = await notifier.createPayment(
      rentScheduleId: widget.schedule.id,
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
      ref.read(createPaymentProvider.notifier).reset();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Paiement enregistré - Reçu: ${payment.receiptNumber}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );

      // Close modal
      Navigator.pop(context);

      // Notify callback
      widget.onPaymentCreated?.call();
    }
  }
}
