# Contract: Receipt Providers

**Feature**: 007-pdf-receipt-generation
**Layer**: Presentation (Riverpod Providers)

## Provider Definitions

### Core Providers

```dart
/// Repository provider
final receiptRepositoryProvider = Provider<ReceiptRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final datasource = ReceiptRemoteDatasource(supabase);
  return ReceiptRepositoryImpl(datasource);
});

/// PDF service provider
final pdfReceiptServiceProvider = Provider<PdfReceiptService>((ref) {
  return PdfReceiptService();
});
```

### State Providers

```dart
/// Receipts for a specific payment
final paymentReceiptsProvider = FutureProvider.family<List<Receipt>, String>(
  (ref, paymentId) async {
    final repository = ref.watch(receiptRepositoryProvider);
    return repository.getReceiptsForPayment(paymentId);
  },
);

/// Receipts for a specific lease
final leaseReceiptsProvider = FutureProvider.family<List<Receipt>, String>(
  (ref, leaseId) async {
    final repository = ref.watch(receiptRepositoryProvider);
    return repository.getReceiptsForLease(leaseId);
  },
);

/// Receipts for a specific tenant
final tenantReceiptsProvider = FutureProvider.family<List<Receipt>, String>(
  (ref, tenantId) async {
    final repository = ref.watch(receiptRepositoryProvider);
    return repository.getReceiptsForTenant(tenantId);
  },
);

/// Single receipt by ID
final receiptProvider = FutureProvider.family<Receipt?, String>(
  (ref, receiptId) async {
    final repository = ref.watch(receiptRepositoryProvider);
    return repository.getReceiptById(receiptId);
  },
);
```

### Action Notifier

```dart
/// State for receipt generation
@freezed
class GenerateReceiptState with _$GenerateReceiptState {
  const factory GenerateReceiptState.initial() = _Initial;
  const factory GenerateReceiptState.loading() = _Loading;
  const factory GenerateReceiptState.success(Receipt receipt, Uint8List pdfBytes) = _Success;
  const factory GenerateReceiptState.error(String message) = _Error;
}

/// Notifier for generating receipts
class GenerateReceiptNotifier extends StateNotifier<GenerateReceiptState> {
  final ReceiptRepository _repository;
  final PdfReceiptService _pdfService;
  final PaymentRepository _paymentRepository;
  final RentScheduleRepository _scheduleRepository;
  final LeaseRepository _leaseRepository;
  final User? _currentUser;

  GenerateReceiptNotifier({
    required ReceiptRepository repository,
    required PdfReceiptService pdfService,
    required PaymentRepository paymentRepository,
    required RentScheduleRepository scheduleRepository,
    required LeaseRepository leaseRepository,
    required User? currentUser,
  }) : _repository = repository,
       _pdfService = pdfService,
       _paymentRepository = paymentRepository,
       _scheduleRepository = scheduleRepository,
       _leaseRepository = leaseRepository,
       _currentUser = currentUser,
       super(const GenerateReceiptState.initial());

  /// Generates a receipt for the given payment
  Future<void> generateReceipt(String paymentId) async {
    state = const GenerateReceiptState.loading();

    try {
      // 1. Fetch payment with related data
      final payment = await _paymentRepository.getPaymentById(paymentId);
      if (payment == null) {
        state = const GenerateReceiptState.error('Paiement introuvable');
        return;
      }

      // 2. Fetch rent schedule
      final schedule = await _scheduleRepository.getScheduleById(payment.rentScheduleId);
      if (schedule == null) {
        state = const GenerateReceiptState.error('Échéance introuvable');
        return;
      }

      // 3. Fetch lease with tenant and unit
      final lease = await _leaseRepository.getLeaseById(schedule.leaseId);
      if (lease == null) {
        state = const GenerateReceiptState.error('Bail introuvable');
        return;
      }

      // 4. Build receipt data
      final receiptData = ReceiptDataBuilder.fromPayment(
        payment: payment,
        schedule: schedule,
        lease: lease,
        managerName: _currentUser?.fullName ?? 'Gestionnaire',
        managerContact: _currentUser?.email,
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

      state = GenerateReceiptState.success(receipt, pdfBytes);
    } catch (e) {
      state = GenerateReceiptState.error(
        e is ReceiptException ? e.message : 'Erreur lors de la génération',
      );
    }
  }

  /// Resets state to initial
  void reset() {
    state = const GenerateReceiptState.initial();
  }
}

/// Provider for the generate receipt notifier
final generateReceiptProvider = StateNotifierProvider.autoDispose<
    GenerateReceiptNotifier, GenerateReceiptState>((ref) {
  return GenerateReceiptNotifier(
    repository: ref.watch(receiptRepositoryProvider),
    pdfService: ref.watch(pdfReceiptServiceProvider),
    paymentRepository: ref.watch(paymentRepositoryProvider),
    scheduleRepository: ref.watch(rentScheduleRepositoryProvider),
    leaseRepository: ref.watch(leaseRepositoryProvider),
    currentUser: ref.watch(currentUserProvider),
  );
});
```

### Download/Share Helpers

```dart
/// Provider for getting signed download URL
final receiptDownloadUrlProvider = FutureProvider.family<String, String>(
  (ref, fileUrl) async {
    final repository = ref.watch(receiptRepositoryProvider);
    return repository.getReceiptDownloadUrl(fileUrl);
  },
);
```

## Usage Examples

### Generate Receipt Button

```dart
class GenerateReceiptButton extends ConsumerWidget {
  final String paymentId;

  const GenerateReceiptButton({required this.paymentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(generateReceiptProvider);

    return state.when(
      initial: () => ElevatedButton.icon(
        onPressed: () => ref.read(generateReceiptProvider.notifier)
            .generateReceipt(paymentId),
        icon: const Icon(Icons.receipt_long),
        label: const Text('Générer quittance'),
      ),
      loading: () => const ElevatedButton(
        onPressed: null,
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      success: (receipt, pdfBytes) => ElevatedButton.icon(
        onPressed: () => context.push('/receipts/preview', extra: pdfBytes),
        icon: const Icon(Icons.visibility),
        label: const Text('Voir la quittance'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
        ),
      ),
      error: (message) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: const TextStyle(color: Colors.red)),
          TextButton(
            onPressed: () => ref.read(generateReceiptProvider.notifier)
                .generateReceipt(paymentId),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}
```

### Receipt List in Lease Detail

```dart
class LeaseReceiptsList extends ConsumerWidget {
  final String leaseId;

  const LeaseReceiptsList({required this.leaseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptsAsync = ref.watch(leaseReceiptsProvider(leaseId));

    return receiptsAsync.when(
      data: (receipts) => receipts.isEmpty
          ? const Text('Aucune quittance générée')
          : ListView.builder(
              shrinkWrap: true,
              itemCount: receipts.length,
              itemBuilder: (context, index) => ReceiptListItem(
                receipt: receipts[index],
              ),
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Erreur: $e'),
    );
  }
}
```

## Acceptance Criteria

- [ ] `generateReceiptProvider` handles loading, success, and error states
- [ ] PDF bytes are available in success state for preview
- [ ] `paymentReceiptsProvider` correctly fetches receipts for a payment
- [ ] `leaseReceiptsProvider` fetches all receipts across lease payments
- [ ] Providers auto-refresh when new receipt is created
- [ ] Error messages are user-friendly and in French
