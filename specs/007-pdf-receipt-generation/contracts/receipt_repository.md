# Contract: ReceiptRepository

**Feature**: 007-pdf-receipt-generation
**Layer**: Domain (interface) / Data (implementation)

## Interface Definition

```dart
/// Repository interface for receipt operations
abstract class ReceiptRepository {
  /// Creates a new receipt record after PDF generation
  ///
  /// Returns the created Receipt entity
  /// Throws [ReceiptException] on failure
  Future<Receipt> createReceipt(CreateReceiptInput input);

  /// Retrieves a receipt by its ID
  ///
  /// Returns null if not found
  Future<Receipt?> getReceiptById(String id);

  /// Retrieves all receipts for a specific payment
  ///
  /// Returns list ordered by generated_at descending (newest first)
  Future<List<Receipt>> getReceiptsForPayment(String paymentId);

  /// Retrieves all receipts for a lease
  ///
  /// Queries through payments → rent_schedules → lease
  /// Returns list ordered by generated_at descending
  Future<List<Receipt>> getReceiptsForLease(String leaseId);

  /// Retrieves all receipts for a tenant
  ///
  /// Queries through payments → rent_schedules → leases → tenant
  /// Returns list ordered by generated_at descending
  Future<List<Receipt>> getReceiptsForTenant(String tenantId);

  /// Updates receipt status (e.g., mark as cancelled)
  ///
  /// Returns the updated Receipt entity
  Future<Receipt> updateReceiptStatus(String id, ReceiptStatus status);

  /// Uploads PDF file to Supabase Storage
  ///
  /// Returns the storage path (not signed URL)
  Future<String> uploadReceiptPdf({
    required String paymentId,
    required String receiptNumber,
    required Uint8List pdfBytes,
  });

  /// Generates a signed URL for PDF download
  ///
  /// URL valid for 1 hour
  Future<String> getReceiptDownloadUrl(String fileUrl);

  /// Deletes the PDF file from storage
  ///
  /// Used when cancelling a receipt
  Future<void> deleteReceiptFile(String fileUrl);
}
```

## Input/Output Types

### CreateReceiptInput

```dart
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
```

## Error Handling

```dart
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

// Specific error codes
class ReceiptErrorCodes {
  static const String paymentNotFound = 'PAYMENT_NOT_FOUND';
  static const String uploadFailed = 'UPLOAD_FAILED';
  static const String createFailed = 'CREATE_FAILED';
  static const String notFound = 'NOT_FOUND';
  static const String updateFailed = 'UPDATE_FAILED';
}
```

## Implementation Notes

### Storage Path Pattern

```
documents/receipts/{payment_id}/{receipt_number}.pdf
```

Example: `documents/receipts/abc-123/REC-2026-0001.pdf`

### Query Patterns

For `getReceiptsForLease`:
```sql
SELECT r.* FROM receipts r
JOIN payments p ON r.payment_id = p.id
JOIN rent_schedules rs ON p.rent_schedule_id = rs.id
WHERE rs.lease_id = $1
ORDER BY r.generated_at DESC;
```

For `getReceiptsForTenant`:
```sql
SELECT r.* FROM receipts r
JOIN payments p ON r.payment_id = p.id
JOIN rent_schedules rs ON p.rent_schedule_id = rs.id
JOIN leases l ON rs.lease_id = l.id
WHERE l.tenant_id = $1
ORDER BY r.generated_at DESC;
```

### Signed URL Generation

```dart
final signedUrl = await supabase.storage
    .from('documents')
    .createSignedUrl(fileUrl, 3600); // 1 hour
```

## Acceptance Criteria

- [ ] `createReceipt` persists receipt metadata to database
- [ ] `uploadReceiptPdf` stores file in correct storage path
- [ ] `getReceiptDownloadUrl` returns valid signed URL
- [ ] `getReceiptsForPayment` returns receipts for a specific payment
- [ ] `getReceiptsForLease` returns all receipts across all payments in lease
- [ ] `updateReceiptStatus` correctly updates status to 'cancelled'
- [ ] All methods handle errors and throw `ReceiptException`
