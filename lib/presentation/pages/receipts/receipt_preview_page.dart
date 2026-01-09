import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../providers/receipts_provider.dart';
import '../../services/receipt_data.dart';

/// Full page for previewing, downloading, and printing a receipt
class ReceiptPreviewPage extends ConsumerStatefulWidget {
  final String paymentId;

  const ReceiptPreviewPage({
    super.key,
    required this.paymentId,
  });

  @override
  ConsumerState<ReceiptPreviewPage> createState() => _ReceiptPreviewPageState();
}

class _ReceiptPreviewPageState extends ConsumerState<ReceiptPreviewPage> {
  @override
  void initState() {
    super.initState();
    // Generate the PDF when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(generateReceiptProvider.notifier).generatePdfOnly(widget.paymentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(generateReceiptProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Apercu de la quittance'),
        actions: [
          if (state.isSuccess) ...[
            // Share button (not on web)
            if (!kIsWeb)
              IconButton(
                icon: const Icon(Icons.share),
                tooltip: 'Partager',
                onPressed: () => _shareReceipt(state),
              ),
            // Save to cloud
            IconButton(
              icon: const Icon(Icons.cloud_upload),
              tooltip: 'Sauvegarder dans le cloud',
              onPressed: () => _saveToCloud(),
            ),
          ],
        ],
      ),
      body: _buildBody(state),
    );
  }

  Future<void> _shareReceipt(GenerateReceiptState state) async {
    if (state.pdfBytes == null || state.receiptData == null) return;

    final pdfService = ref.read(pdfReceiptServiceProvider);
    final success = await pdfService.shareReceipt(
      pdfBytes: state.pdfBytes!,
      data: state.receiptData!,
      tenantEmail: state.receiptData!.tenantEmail,
    );

    if (mounted && !success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le partage n\'est pas disponible sur cette plateforme'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Widget _buildBody(GenerateReceiptState state) {
    if (state.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Generation de la quittance...'),
          ],
        ),
      );
    }

    if (state.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                state.error ?? 'Erreur inconnue',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red[700], fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _retry(),
                icon: const Icon(Icons.refresh),
                label: const Text('Reessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.pdfBytes == null) {
      return const Center(
        child: Text('Aucune quittance disponible'),
      );
    }

    final pdfService = ref.read(pdfReceiptServiceProvider);
    final filename = state.receiptData != null
        ? pdfService.generateFilename(state.receiptData!)
        : 'Quittance.pdf';

    return PdfPreview(
      build: (_) => state.pdfBytes!,
      canChangePageFormat: false,
      canChangeOrientation: false,
      allowSharing: true,
      allowPrinting: true,
      pdfFileName: filename,
      loadingWidget: const Center(child: CircularProgressIndicator()),
      onError: (context, error) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 12),
            Text(
              'Erreur d\'affichage: $error',
              style: TextStyle(color: Colors.red[700]),
            ),
          ],
        ),
      ),
    );
  }

  void _retry() {
    ref.read(generateReceiptProvider.notifier).generatePdfOnly(widget.paymentId);
  }

  Future<void> _saveToCloud() async {
    await ref.read(generateReceiptProvider.notifier).generateReceipt(widget.paymentId);
    final state = ref.read(generateReceiptProvider);

    if (mounted) {
      if (state.isSuccess && state.receipt != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quittance sauvegardee avec succes'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (state.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.error ?? 'Erreur lors de la sauvegarde'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Widget to show receipt preview in a dialog (alternative to full page)
class ReceiptPreviewDialog extends ConsumerWidget {
  final Uint8List pdfBytes;
  final ReceiptData? receiptData;
  final String paymentId;

  const ReceiptPreviewDialog({
    super.key,
    required this.pdfBytes,
    this.receiptData,
    required this.paymentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pdfService = ref.read(pdfReceiptServiceProvider);
    final filename = receiptData != null
        ? pdfService.generateFilename(receiptData!)
        : 'Quittance.pdf';

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 900),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Apercu de la quittance',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // PDF Preview
            Expanded(
              child: PdfPreview(
                build: (_) => pdfBytes,
                canChangePageFormat: false,
                canChangeOrientation: false,
                allowSharing: true,
                allowPrinting: true,
                pdfFileName: filename,
                actions: [
                  // Share button (mobile only)
                  if (!kIsWeb)
                    PdfPreviewAction(
                      icon: const Icon(Icons.share),
                      onPressed: (context, build, pageFormat) =>
                          _shareReceipt(context, ref),
                    ),
                  // Save to cloud button
                  PdfPreviewAction(
                    icon: const Icon(Icons.cloud_upload),
                    onPressed: (context, build, pageFormat) =>
                        _saveToCloud(context, ref),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareReceipt(BuildContext context, WidgetRef ref) async {
    if (receiptData == null) return;

    final pdfService = ref.read(pdfReceiptServiceProvider);
    final success = await pdfService.shareReceipt(
      pdfBytes: pdfBytes,
      data: receiptData!,
      tenantEmail: receiptData!.tenantEmail,
    );

    if (context.mounted && !success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le partage n\'est pas disponible sur cette plateforme'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _saveToCloud(BuildContext context, WidgetRef ref) async {
    // Generate and save to cloud
    await ref.read(generateReceiptProvider.notifier).generateReceipt(paymentId);
    final state = ref.read(generateReceiptProvider);

    if (context.mounted) {
      if (state.isSuccess && state.receipt != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quittance sauvegardee avec succes'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (state.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.error ?? 'Erreur lors de la sauvegarde'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
