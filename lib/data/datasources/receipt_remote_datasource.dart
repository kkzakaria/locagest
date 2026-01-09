import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/receipt.dart';
import '../models/receipt_model.dart';

/// Exception for receipt operations
class ReceiptException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const ReceiptException(
    this.message, {
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'ReceiptException: $message';
}

/// Error codes for receipt operations
class ReceiptErrorCodes {
  static const String paymentNotFound = 'PAYMENT_NOT_FOUND';
  static const String uploadFailed = 'UPLOAD_FAILED';
  static const String createFailed = 'CREATE_FAILED';
  static const String notFound = 'NOT_FOUND';
  static const String updateFailed = 'UPDATE_FAILED';
}

/// Remote datasource for receipt operations via Supabase
class ReceiptRemoteDatasource {
  final SupabaseClient _supabase;

  ReceiptRemoteDatasource(this._supabase);

  /// Create a new receipt record
  Future<ReceiptModel> createReceipt({
    required String paymentId,
    required String receiptNumber,
    required String fileUrl,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      final response = await _supabase
          .from('receipts')
          .insert({
            'payment_id': paymentId,
            'receipt_number': receiptNumber,
            'file_url': fileUrl,
            'created_by': userId,
          })
          .select()
          .single();

      return ReceiptModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ReceiptException(
        'Erreur lors de la creation de la quittance',
        code: ReceiptErrorCodes.createFailed,
        originalError: e,
      );
    }
  }

  /// Get receipt by ID
  Future<ReceiptModel?> getReceiptById(String id) async {
    try {
      final response = await _supabase
          .from('receipts')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return ReceiptModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ReceiptException(
        'Erreur lors de la recuperation de la quittance',
        code: ReceiptErrorCodes.notFound,
        originalError: e,
      );
    }
  }

  /// Get all receipts for a payment
  Future<List<ReceiptModel>> getReceiptsForPayment(String paymentId) async {
    try {
      final response = await _supabase
          .from('receipts')
          .select()
          .eq('payment_id', paymentId)
          .order('generated_at', ascending: false);

      return (response as List)
          .map((json) => ReceiptModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw ReceiptException(
        'Erreur lors de la recuperation des quittances',
        originalError: e,
      );
    }
  }

  /// Get all receipts for a lease (through payments and rent_schedules)
  Future<List<ReceiptModel>> getReceiptsForLease(String leaseId) async {
    try {
      // Query receipts through the payment -> rent_schedule -> lease chain
      final response = await _supabase.rpc(
        'get_receipts_for_lease',
        params: {'p_lease_id': leaseId},
      );

      // If RPC doesn't exist, fall back to manual query
      if (response == null) {
        return _getReceiptsForLeaseManual(leaseId);
      }

      return (response as List)
          .map((json) => ReceiptModel.fromJson(json))
          .toList();
    } on PostgrestException {
      // RPC might not exist, use manual query
      return _getReceiptsForLeaseManual(leaseId);
    }
  }

  /// Manual query for receipts by lease
  Future<List<ReceiptModel>> _getReceiptsForLeaseManual(String leaseId) async {
    try {
      // First get all rent_schedule IDs for this lease
      final schedules = await _supabase
          .from('rent_schedules')
          .select('id')
          .eq('lease_id', leaseId);

      if ((schedules as List).isEmpty) return [];

      final scheduleIds = schedules.map((s) => s['id'] as String).toList();

      // Then get all payment IDs for these schedules
      final payments = await _supabase
          .from('payments')
          .select('id')
          .inFilter('rent_schedule_id', scheduleIds);

      if ((payments as List).isEmpty) return [];

      final paymentIds = payments.map((p) => p['id'] as String).toList();

      // Finally get all receipts for these payments
      final response = await _supabase
          .from('receipts')
          .select()
          .inFilter('payment_id', paymentIds)
          .order('generated_at', ascending: false);

      return (response as List)
          .map((json) => ReceiptModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw ReceiptException(
        'Erreur lors de la recuperation des quittances du bail',
        originalError: e,
      );
    }
  }

  /// Get all receipts for a tenant
  Future<List<ReceiptModel>> getReceiptsForTenant(String tenantId) async {
    try {
      // Query through: leases -> rent_schedules -> payments -> receipts
      final leases = await _supabase
          .from('leases')
          .select('id')
          .eq('tenant_id', tenantId);

      if ((leases as List).isEmpty) return [];

      final leaseIds = leases.map((l) => l['id'] as String).toList();

      final schedules = await _supabase
          .from('rent_schedules')
          .select('id')
          .inFilter('lease_id', leaseIds);

      if ((schedules as List).isEmpty) return [];

      final scheduleIds = schedules.map((s) => s['id'] as String).toList();

      final payments = await _supabase
          .from('payments')
          .select('id')
          .inFilter('rent_schedule_id', scheduleIds);

      if ((payments as List).isEmpty) return [];

      final paymentIds = payments.map((p) => p['id'] as String).toList();

      final response = await _supabase
          .from('receipts')
          .select()
          .inFilter('payment_id', paymentIds)
          .order('generated_at', ascending: false);

      return (response as List)
          .map((json) => ReceiptModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw ReceiptException(
        'Erreur lors de la recuperation des quittances du locataire',
        originalError: e,
      );
    }
  }

  /// Update receipt status
  Future<ReceiptModel> updateReceiptStatus(
    String id,
    ReceiptStatus status,
  ) async {
    try {
      final response = await _supabase
          .from('receipts')
          .update({'status': status.name})
          .eq('id', id)
          .select()
          .single();

      return ReceiptModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ReceiptException(
        'Erreur lors de la mise a jour du statut',
        code: ReceiptErrorCodes.updateFailed,
        originalError: e,
      );
    }
  }

  /// Upload PDF file to Supabase Storage
  Future<String> uploadReceiptPdf({
    required String paymentId,
    required String receiptNumber,
    required Uint8List pdfBytes,
  }) async {
    try {
      // Clean receipt number for filename (remove special chars)
      final cleanReceiptNumber = receiptNumber.replaceAll(RegExp(r'[^\w-]'), '_');
      final filePath = 'receipts/$paymentId/$cleanReceiptNumber.pdf';

      await _supabase.storage.from('documents').uploadBinary(
            filePath,
            pdfBytes,
            fileOptions: const FileOptions(
              contentType: 'application/pdf',
              upsert: true,
            ),
          );

      return filePath;
    } on StorageException catch (e) {
      throw ReceiptException(
        'Erreur lors du telechargement du PDF',
        code: ReceiptErrorCodes.uploadFailed,
        originalError: e,
      );
    }
  }

  /// Generate signed URL for PDF download (valid for 1 hour)
  Future<String> getReceiptDownloadUrl(String fileUrl) async {
    try {
      final signedUrl = await _supabase.storage
          .from('documents')
          .createSignedUrl(fileUrl, 3600); // 1 hour

      return signedUrl;
    } on StorageException catch (e) {
      throw ReceiptException(
        'Erreur lors de la generation du lien de telechargement',
        originalError: e,
      );
    }
  }

  /// Delete PDF file from storage
  Future<void> deleteReceiptFile(String fileUrl) async {
    try {
      await _supabase.storage.from('documents').remove([fileUrl]);
    } on StorageException catch (e) {
      throw ReceiptException(
        'Erreur lors de la suppression du fichier',
        originalError: e,
      );
    }
  }
}
