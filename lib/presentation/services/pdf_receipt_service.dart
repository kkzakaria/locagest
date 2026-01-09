import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'receipt_data.dart';

/// Service for generating PDF rent receipts (quittances)
class PdfReceiptService {
  /// Generates a PDF receipt document from receipt data
  Future<Uint8List> generateReceipt(ReceiptData data) async {
    final pdf = _buildDocument(data);
    return pdf.save();
  }

  /// Shares a receipt PDF using the native share functionality
  /// On web, this will trigger a download instead
  /// Returns true if sharing was successful
  Future<bool> shareReceipt({
    required Uint8List pdfBytes,
    required ReceiptData data,
    String? tenantEmail,
  }) async {
    if (kIsWeb) {
      // On web, we can't share files directly
      // The PDF preview widget handles download on web
      return false;
    }

    try {
      // Get temp directory
      final tempDir = await getTemporaryDirectory();
      final filename = generateFilename(data);
      final file = File('${tempDir.path}/$filename');

      // Write PDF to temp file
      await file.writeAsBytes(pdfBytes);

      // Build share text
      final shareText = _buildShareText(data, tenantEmail);

      // Share the file
      final result = await Share.shareXFiles(
        [XFile(file.path)],
        text: shareText,
        subject: 'Quittance de loyer - ${data.periodLabel}',
      );

      // Clean up temp file after sharing
      if (await file.exists()) {
        await file.delete();
      }

      return result.status == ShareResultStatus.success ||
          result.status == ShareResultStatus.dismissed;
    } catch (e) {
      return false;
    }
  }

  /// Builds the share text with optional email pre-fill
  String _buildShareText(ReceiptData data, String? tenantEmail) {
    final buffer = StringBuffer();
    buffer.writeln('Quittance de loyer - ${data.periodLabel}');
    buffer.writeln('');
    buffer.writeln('Montant: ${data.amountPaidFormatted}');
    buffer.writeln('Locataire: ${data.tenantFullName}');
    buffer.writeln('Lot: ${data.unitReference}');

    if (tenantEmail != null && tenantEmail.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('Destinataire: $tenantEmail');
    }

    return buffer.toString();
  }

  /// Generates filename for the receipt
  /// Format: "Quittance_{Period}_{TenantName}.pdf"
  String generateFilename(ReceiptData data) {
    // Clean tenant name (remove accents and special chars)
    final cleanTenantName = _cleanForFilename(data.tenantFullName);
    // Clean period (remove spaces)
    final cleanPeriod = _cleanForFilename(data.periodLabel);

    return 'Quittance_${cleanPeriod}_$cleanTenantName.pdf';
  }

  /// Clean string for use in filename
  String _cleanForFilename(String input) {
    return input
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[àâä]'), 'a')
        .replaceAll(RegExp(r'[ùûü]'), 'u')
        .replaceAll(RegExp(r'[ôö]'), 'o')
        .replaceAll(RegExp(r'[îï]'), 'i')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  /// Builds the PDF document structure
  pw.Document _buildDocument(ReceiptData data) {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(data),
              pw.SizedBox(height: 30),
              _buildLandlordSection(data),
              pw.SizedBox(height: 20),
              _buildTenantSection(data),
              pw.SizedBox(height: 20),
              _buildPaymentDetails(data),
              if (data.isPartialPayment) ...[
                pw.SizedBox(height: 20),
                _buildPartialPaymentNotice(data),
              ],
              pw.Spacer(),
              _buildFooter(data),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  /// Builds the header section with title and period
  pw.Widget _buildHeader(ReceiptData data) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        border: pw.Border.all(color: PdfColors.blue800),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'QUITTANCE DE LOYER',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            data.periodLabel,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the landlord/manager section
  pw.Widget _buildLandlordSection(ReceiptData data) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'BAILLEUR',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            data.managerName,
            style: const pw.TextStyle(fontSize: 14),
          ),
          if (data.managerContact != null && data.managerContact!.isNotEmpty)
            pw.Text(
              data.managerContact!,
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
            ),
        ],
      ),
    );
  }

  /// Builds the tenant section with address
  pw.Widget _buildTenantSection(ReceiptData data) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'LOCATAIRE',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            data.tenantFullName,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          if (data.buildingName.isNotEmpty)
            pw.Text(
              data.buildingName,
              style: const pw.TextStyle(fontSize: 12),
            ),
          if (data.unitReference.isNotEmpty)
            pw.Text(
              'Lot ${data.unitReference}',
              style: const pw.TextStyle(fontSize: 12),
            ),
          if (data.fullAddress.isNotEmpty)
            pw.Text(
              data.fullAddress,
              style: const pw.TextStyle(fontSize: 12),
            ),
          if (data.city.isNotEmpty)
            pw.Text(
              data.city,
              style: const pw.TextStyle(fontSize: 12),
            ),
        ],
      ),
    );
  }

  /// Builds the payment details section
  pw.Widget _buildPaymentDetails(ReceiptData data) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'DETAIL DU PAIEMENT',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 15),

          // Amounts table
          _buildAmountRow('Loyer (hors charges)', data.rentAmountFormatted),
          pw.SizedBox(height: 8),
          _buildAmountRow('Charges', data.chargesAmountFormatted),
          pw.Divider(color: PdfColors.grey400),
          _buildAmountRow(
            'TOTAL',
            data.amountPaidFormatted,
            isBold: true,
          ),

          pw.SizedBox(height: 20),

          // Payment info
          _buildInfoRow('Date de paiement', data.paymentDateFormatted),
          pw.SizedBox(height: 6),
          _buildInfoRow('Mode de paiement', data.paymentMethod),
          if (data.paymentReference != null &&
              data.paymentReference!.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            _buildInfoRow('Reference', data.paymentReference!),
          ],
          pw.SizedBox(height: 6),
          _buildInfoRow('Numero de recu', data.receiptNumber),
        ],
      ),
    );
  }

  /// Builds a row with label and amount (right-aligned)
  pw.Widget _buildAmountRow(String label, String amount, {bool isBold = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: isBold ? pw.FontWeight.bold : null,
          ),
        ),
        pw.Text(
          amount,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: isBold ? pw.FontWeight.bold : null,
          ),
        ),
      ],
    );
  }

  /// Builds a row with label and value
  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '$label: ',
          style: const pw.TextStyle(
            fontSize: 11,
            color: PdfColors.grey600,
          ),
        ),
        pw.Text(
          value,
          style: const pw.TextStyle(fontSize: 11),
        ),
      ],
    );
  }

  /// Builds the partial payment notice (if applicable)
  pw.Widget _buildPartialPaymentNotice(ReceiptData data) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.amber50,
        border: pw.Border.all(color: PdfColors.amber700),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Text(
                'ACOMPTE',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.amber900,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Ce paiement est un acompte.',
            style: const pw.TextStyle(fontSize: 11),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Solde restant du: ${data.remainingBalanceFormatted}',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.amber900,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the footer with legal mention and date
  pw.Widget _buildFooter(ReceiptData data) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.only(top: 20),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Pour valoir ce que de droit.',
            style: pw.TextStyle(
              fontSize: 12,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Fait le ${data.generationDateFormatted}',
            style: const pw.TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
