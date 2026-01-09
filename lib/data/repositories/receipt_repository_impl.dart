import 'dart:typed_data';

import '../../domain/entities/receipt.dart';
import '../../domain/repositories/receipt_repository.dart';
import '../datasources/receipt_remote_datasource.dart';

/// Implementation of ReceiptRepository using Supabase
class ReceiptRepositoryImpl implements ReceiptRepository {
  final ReceiptRemoteDatasource _datasource;

  ReceiptRepositoryImpl(this._datasource);

  @override
  Future<Receipt> createReceipt(CreateReceiptInput input) async {
    final model = await _datasource.createReceipt(
      paymentId: input.paymentId,
      receiptNumber: input.receiptNumber,
      fileUrl: input.fileUrl,
    );
    return model.toEntity();
  }

  @override
  Future<Receipt?> getReceiptById(String id) async {
    final model = await _datasource.getReceiptById(id);
    return model?.toEntity();
  }

  @override
  Future<List<Receipt>> getReceiptsForPayment(String paymentId) async {
    final models = await _datasource.getReceiptsForPayment(paymentId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<Receipt>> getReceiptsForLease(String leaseId) async {
    final models = await _datasource.getReceiptsForLease(leaseId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<Receipt>> getReceiptsForTenant(String tenantId) async {
    final models = await _datasource.getReceiptsForTenant(tenantId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Receipt> updateReceiptStatus(String id, ReceiptStatus status) async {
    final model = await _datasource.updateReceiptStatus(id, status);
    return model.toEntity();
  }

  @override
  Future<String> uploadReceiptPdf({
    required String paymentId,
    required String receiptNumber,
    required Uint8List pdfBytes,
  }) async {
    return _datasource.uploadReceiptPdf(
      paymentId: paymentId,
      receiptNumber: receiptNumber,
      pdfBytes: pdfBytes,
    );
  }

  @override
  Future<String> getReceiptDownloadUrl(String fileUrl) async {
    return _datasource.getReceiptDownloadUrl(fileUrl);
  }

  @override
  Future<void> deleteReceiptFile(String fileUrl) async {
    return _datasource.deleteReceiptFile(fileUrl);
  }
}
