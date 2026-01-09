import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasources/receipt_remote_datasource.dart';
import '../../data/repositories/receipt_repository_impl.dart';
import '../../domain/entities/lease.dart';
import '../../domain/entities/receipt.dart';
import '../../domain/repositories/lease_repository.dart';
import '../../domain/repositories/payment_repository.dart';
import '../../domain/repositories/receipt_repository.dart';
import '../services/pdf_receipt_service.dart';
import '../services/receipt_data.dart';
import 'auth_provider.dart';
import 'leases_provider.dart';
import 'payments_provider.dart';

// =============================================================================
// DEPENDENCY PROVIDERS
// =============================================================================

/// Provider for ReceiptRemoteDatasource
final receiptDatasourceProvider = Provider<ReceiptRemoteDatasource>((ref) {
  return ReceiptRemoteDatasource(Supabase.instance.client);
});

/// Provider for ReceiptRepository
final receiptRepositoryProvider = Provider<ReceiptRepository>((ref) {
  return ReceiptRepositoryImpl(ref.read(receiptDatasourceProvider));
});

/// Provider for PdfReceiptService
final pdfReceiptServiceProvider = Provider<PdfReceiptService>((ref) {
  return PdfReceiptService();
});

// =============================================================================
// RECEIPT QUERY PROVIDERS
// =============================================================================

/// Receipts for a specific payment
final paymentReceiptsProvider =
    FutureProvider.family<List<Receipt>, String>((ref, paymentId) async {
  final repository = ref.watch(receiptRepositoryProvider);
  return repository.getReceiptsForPayment(paymentId);
});

/// Receipts for a specific lease
final leaseReceiptsProvider =
    FutureProvider.family<List<Receipt>, String>((ref, leaseId) async {
  final repository = ref.watch(receiptRepositoryProvider);
  return repository.getReceiptsForLease(leaseId);
});

/// Receipts for a specific tenant
final tenantReceiptsProvider =
    FutureProvider.family<List<Receipt>, String>((ref, tenantId) async {
  final repository = ref.watch(receiptRepositoryProvider);
  return repository.getReceiptsForTenant(tenantId);
});

/// Single receipt by ID
final receiptProvider =
    FutureProvider.family<Receipt?, String>((ref, receiptId) async {
  final repository = ref.watch(receiptRepositoryProvider);
  return repository.getReceiptById(receiptId);
});

/// Receipt download URL (signed URL)
final receiptDownloadUrlProvider =
    FutureProvider.family<String, String>((ref, fileUrl) async {
  final repository = ref.watch(receiptRepositoryProvider);
  return repository.getReceiptDownloadUrl(fileUrl);
});

// =============================================================================
// GENERATE RECEIPT STATE
// =============================================================================

/// State for receipt generation
class GenerateReceiptState {
  final bool isLoading;
  final String? error;
  final Receipt? receipt;
  final Uint8List? pdfBytes;
  final ReceiptData? receiptData;

  const GenerateReceiptState({
    this.isLoading = false,
    this.error,
    this.receipt,
    this.pdfBytes,
    this.receiptData,
  });

  GenerateReceiptState copyWith({
    bool? isLoading,
    String? error,
    Receipt? receipt,
    Uint8List? pdfBytes,
    ReceiptData? receiptData,
  }) {
    return GenerateReceiptState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      receipt: receipt ?? this.receipt,
      pdfBytes: pdfBytes ?? this.pdfBytes,
      receiptData: receiptData ?? this.receiptData,
    );
  }

  bool get isSuccess => receipt != null && pdfBytes != null;
  bool get hasError => error != null;
}

// =============================================================================
// GENERATE RECEIPT NOTIFIER
// =============================================================================

/// Notifier for generating receipts
class GenerateReceiptNotifier extends StateNotifier<GenerateReceiptState> {
  final ReceiptRepository _repository;
  final PdfReceiptService _pdfService;
  final PaymentRepository _paymentRepository;
  final LeaseRepository _leaseRepository;
  final String? _currentUserName;
  final String? _currentUserEmail;

  GenerateReceiptNotifier({
    required ReceiptRepository repository,
    required PdfReceiptService pdfService,
    required PaymentRepository paymentRepository,
    required LeaseRepository leaseRepository,
    String? currentUserName,
    String? currentUserEmail,
  })  : _repository = repository,
        _pdfService = pdfService,
        _paymentRepository = paymentRepository,
        _leaseRepository = leaseRepository,
        _currentUserName = currentUserName,
        _currentUserEmail = currentUserEmail,
        super(const GenerateReceiptState());

  /// Generates a receipt for the given payment
  Future<void> generateReceipt(String paymentId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // 1. Fetch payment
      final payment = await _paymentRepository.getPaymentById(paymentId);
      if (payment == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Paiement introuvable',
        );
        return;
      }

      // 2. Fetch rent schedule
      final schedule =
          await _paymentRepository.getRentScheduleById(payment.rentScheduleId);
      if (schedule == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Echeance introuvable',
        );
        return;
      }

      // 3. Fetch lease with tenant and unit
      Lease lease;
      try {
        lease = await _leaseRepository.getLeaseById(schedule.leaseId);
      } catch (_) {
        state = state.copyWith(
          isLoading: false,
          error: 'Bail introuvable',
        );
        return;
      }

      // 4. Build receipt data
      final receiptData = ReceiptDataBuilder.fromPayment(
        payment: payment,
        schedule: schedule,
        lease: lease,
        managerName: _currentUserName ?? 'Gestionnaire',
        managerContact: _currentUserEmail,
      );

      // 5. Generate PDF
      final pdfBytes = await _pdfService.generateReceipt(receiptData);

      // 6. Upload to storage
      final fileUrl = await _repository.uploadReceiptPdf(
        paymentId: paymentId,
        receiptNumber: payment.receiptNumber,
        pdfBytes: pdfBytes,
      );

      // 7. Create receipt record
      final receipt = await _repository.createReceipt(
        CreateReceiptInput(
          paymentId: paymentId,
          receiptNumber: payment.receiptNumber,
          fileUrl: fileUrl,
        ),
      );

      state = state.copyWith(
        isLoading: false,
        receipt: receipt,
        pdfBytes: pdfBytes,
        receiptData: receiptData,
      );
    } on ReceiptException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la generation de la quittance',
      );
    }
  }

  /// Generate PDF only (without saving to storage)
  Future<void> generatePdfOnly(String paymentId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // 1. Fetch payment
      final payment = await _paymentRepository.getPaymentById(paymentId);
      if (payment == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Paiement introuvable',
        );
        return;
      }

      // 2. Fetch rent schedule
      final schedule =
          await _paymentRepository.getRentScheduleById(payment.rentScheduleId);
      if (schedule == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Echeance introuvable',
        );
        return;
      }

      // 3. Fetch lease with tenant and unit
      Lease lease;
      try {
        lease = await _leaseRepository.getLeaseById(schedule.leaseId);
      } catch (_) {
        state = state.copyWith(
          isLoading: false,
          error: 'Bail introuvable',
        );
        return;
      }

      // 4. Build receipt data
      final receiptData = ReceiptDataBuilder.fromPayment(
        payment: payment,
        schedule: schedule,
        lease: lease,
        managerName: _currentUserName ?? 'Gestionnaire',
        managerContact: _currentUserEmail,
      );

      // 5. Generate PDF (no save)
      final pdfBytes = await _pdfService.generateReceipt(receiptData);

      state = state.copyWith(
        isLoading: false,
        pdfBytes: pdfBytes,
        receiptData: receiptData,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la generation du PDF',
      );
    }
  }

  /// Resets state to initial
  void reset() {
    state = const GenerateReceiptState();
  }
}

/// Provider for the generate receipt notifier
final generateReceiptProvider =
    StateNotifierProvider.autoDispose<GenerateReceiptNotifier, GenerateReceiptState>(
        (ref) {
  final currentUser = ref.watch(currentUserProvider);

  return GenerateReceiptNotifier(
    repository: ref.watch(receiptRepositoryProvider),
    pdfService: ref.watch(pdfReceiptServiceProvider),
    paymentRepository: ref.watch(paymentRepositoryProvider),
    leaseRepository: ref.watch(leaseRepositoryProvider),
    currentUserName: currentUser?.fullName,
    currentUserEmail: currentUser?.email,
  );
});
