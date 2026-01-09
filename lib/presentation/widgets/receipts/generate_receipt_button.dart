import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../pages/receipts/receipt_preview_page.dart';
import '../../providers/receipts_provider.dart';

/// Button to generate a receipt for a payment.
/// Can be used as a standalone button or icon button.
class GenerateReceiptButton extends ConsumerWidget {
  final String paymentId;
  final bool iconOnly;
  final VoidCallback? onSuccess;
  final VoidCallback? onError;

  const GenerateReceiptButton({
    super.key,
    required this.paymentId,
    this.iconOnly = false,
    this.onSuccess,
    this.onError,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(generateReceiptProvider);

    // Listen for state changes
    ref.listen<GenerateReceiptState>(generateReceiptProvider, (previous, next) {
      if (next.isSuccess && previous?.isSuccess != true) {
        onSuccess?.call();
        // Show preview dialog
        _showPreviewDialog(context, ref);
      } else if (next.hasError && previous?.hasError != true) {
        onError?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error ?? 'Erreur lors de la generation'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    if (iconOnly) {
      return IconButton(
        icon: state.isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.receipt_long),
        tooltip: 'Generer quittance',
        onPressed: state.isLoading ? null : () => _generateReceipt(ref),
      );
    }

    return ElevatedButton.icon(
      onPressed: state.isLoading ? null : () => _generateReceipt(ref),
      icon: state.isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.receipt_long),
      label: Text(state.isLoading ? 'Generation...' : 'Generer quittance'),
    );
  }

  void _generateReceipt(WidgetRef ref) {
    ref.read(generateReceiptProvider.notifier).generatePdfOnly(paymentId);
  }

  void _showPreviewDialog(BuildContext context, WidgetRef ref) {
    final state = ref.read(generateReceiptProvider);
    if (state.pdfBytes == null) return;

    showDialog(
      context: context,
      builder: (context) => ReceiptPreviewDialog(
        pdfBytes: state.pdfBytes!,
        receiptData: state.receiptData,
        paymentId: paymentId,
      ),
    );
  }
}

/// Compact version of the generate button for use in lists
class GenerateReceiptIconButton extends ConsumerWidget {
  final String paymentId;
  final double size;

  const GenerateReceiptIconButton({
    super.key,
    required this.paymentId,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GenerateReceiptButton(
      paymentId: paymentId,
      iconOnly: true,
    );
  }
}
