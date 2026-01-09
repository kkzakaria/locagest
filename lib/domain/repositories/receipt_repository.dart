import 'dart:typed_data';

import '../entities/receipt.dart';

/// Input for creating a receipt
class CreateReceiptInput {
  final String paymentId;
  final String receiptNumber;
  final String fileUrl;

  const CreateReceiptInput({
    required this.paymentId,
    required this.receiptNumber,
    required this.fileUrl,
  });
}

/// Repository interface for receipt operations
abstract class ReceiptRepository {
  /// Creates a new receipt record after PDF generation
  Future<Receipt> createReceipt(CreateReceiptInput input);

  /// Retrieves a receipt by its ID
  Future<Receipt?> getReceiptById(String id);

  /// Retrieves all receipts for a specific payment
  Future<List<Receipt>> getReceiptsForPayment(String paymentId);

  /// Retrieves all receipts for a lease
  Future<List<Receipt>> getReceiptsForLease(String leaseId);

  /// Retrieves all receipts for a tenant
  Future<List<Receipt>> getReceiptsForTenant(String tenantId);

  /// Updates receipt status (e.g., mark as cancelled)
  Future<Receipt> updateReceiptStatus(String id, ReceiptStatus status);

  /// Uploads PDF file to Supabase Storage
  Future<String> uploadReceiptPdf({
    required String paymentId,
    required String receiptNumber,
    required Uint8List pdfBytes,
  });

  /// Generates a signed URL for PDF download
  Future<String> getReceiptDownloadUrl(String fileUrl);

  /// Deletes the PDF file from storage
  Future<void> deleteReceiptFile(String fileUrl);
}
