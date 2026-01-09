# Data Model: Génération de Quittances PDF

**Feature**: 007-pdf-receipt-generation
**Date**: 2026-01-09

## Entity Relationship Diagram

```
┌─────────────┐       ┌──────────────┐       ┌─────────────┐
│   leases    │───────│ rent_schedules│───────│  payments   │
│             │  1:N  │              │  1:N  │             │
│ - tenant_id │       │ - period     │       │ - amount    │
│ - unit_id   │       │ - amount_due │       │ - method    │
│ - rent_amt  │       │              │       │ - receipt_# │
└─────────────┘       └──────────────┘       └──────┬──────┘
      │                                              │
      │                                         1:N  │
      ▼                                              ▼
┌─────────────┐                             ┌──────────────┐
│   tenants   │                             │   receipts   │ ◄── NEW
│             │                             │              │
│ - firstName │                             │ - payment_id │
│ - lastName  │                             │ - file_url   │
│ - email     │                             │ - status     │
│ - phone     │                             │ - receipt_#  │
└─────────────┘                             └──────────────┘
      │
      │                                     ┌──────────────┐
      ▼                                     │    units     │
┌─────────────┐                             │              │
│  buildings  │◄────────────────────────────│ - building_id│
│             │           1:N               │ - reference  │
│ - name      │                             │ - address    │
│ - address   │                             └──────────────┘
└─────────────┘
```

## New Entity: Receipt

### Domain Entity (`lib/domain/entities/receipt.dart`)

```dart
enum ReceiptStatus { valid, cancelled }

class Receipt {
  final String id;
  final String paymentId;
  final String receiptNumber;
  final String fileUrl;           // Storage path, not signed URL
  final ReceiptStatus status;
  final DateTime generatedAt;
  final String? createdBy;
  final DateTime createdAt;

  // Computed properties
  bool get isValid => status == ReceiptStatus.valid;
  bool get isCancelled => status == ReceiptStatus.cancelled;

  String get statusLabel {
    switch (status) {
      case ReceiptStatus.valid:
        return 'Valide';
      case ReceiptStatus.cancelled:
        return 'Annulée';
    }
  }

  String get generatedAtFormatted {
    return DateFormat('dd/MM/yyyy HH:mm').format(generatedAt);
  }
}
```

### Data Model (`lib/data/models/receipt_model.dart`)

```dart
@freezed
class ReceiptModel with _$ReceiptModel {
  const factory ReceiptModel({
    required String id,
    @JsonKey(name: 'payment_id') required String paymentId,
    @JsonKey(name: 'receipt_number') required String receiptNumber,
    @JsonKey(name: 'file_url') required String fileUrl,
    required String status,
    @JsonKey(name: 'generated_at') required DateTime generatedAt,
    @JsonKey(name: 'created_by') String? createdBy,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _ReceiptModel;

  factory ReceiptModel.fromJson(Map<String, dynamic> json) =>
      _$ReceiptModelFromJson(json);
}

extension ReceiptModelX on ReceiptModel {
  Receipt toEntity() => Receipt(
    id: id,
    paymentId: paymentId,
    receiptNumber: receiptNumber,
    fileUrl: fileUrl,
    status: ReceiptStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => ReceiptStatus.valid,
    ),
    generatedAt: generatedAt,
    createdBy: createdBy,
    createdAt: createdAt,
  );
}
```

## Database Schema

### Table: receipts

```sql
CREATE TABLE receipts (
  -- Primary key
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Foreign keys
  payment_id UUID NOT NULL REFERENCES payments(id) ON DELETE SET NULL,
  created_by UUID REFERENCES profiles(id),

  -- Receipt data
  receipt_number TEXT NOT NULL,
  file_url TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'valid' CHECK (status IN ('valid', 'cancelled')),

  -- Timestamps
  generated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX idx_receipts_payment_id ON receipts(payment_id);
CREATE INDEX idx_receipts_created_by ON receipts(created_by);
CREATE INDEX idx_receipts_status ON receipts(status);

-- RLS
ALTER TABLE receipts ENABLE ROW LEVEL SECURITY;

-- Select policy: users see their own receipts, admins see all
CREATE POLICY "receipts_select_policy"
  ON receipts FOR SELECT
  USING (
    created_by = auth.uid() OR
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- Insert policy: authenticated users can create receipts
CREATE POLICY "receipts_insert_policy"
  ON receipts FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL AND created_by = auth.uid());

-- Update policy: owner can update status
CREATE POLICY "receipts_update_policy"
  ON receipts FOR UPDATE
  USING (created_by = auth.uid())
  WITH CHECK (created_by = auth.uid());
```

## Existing Entities (Referenced)

### Payment Entity (existing, relevant fields)

```dart
class Payment {
  final String id;
  final String rentScheduleId;
  final double amount;
  final DateTime paymentDate;
  final PaymentMethod paymentMethod;
  final String? reference;
  final String? checkNumber;
  final String? bankName;
  final String receiptNumber;      // ← Used in PDF
  final String? notes;
  final String? createdBy;
  final DateTime createdAt;
}
```

### RentSchedule Entity (existing, relevant fields)

```dart
class RentSchedule {
  final String id;
  final String leaseId;
  final DateTime dueDate;
  final DateTime periodStart;       // ← Period for quittance
  final DateTime periodEnd;         // ← Period for quittance
  final double amountDue;           // ← Total rent + charges
  final double amountPaid;
  final double balance;
}
```

### Lease Entity (existing, relevant fields)

```dart
class Lease {
  final String id;
  final String unitId;
  final String tenantId;
  final double rentAmount;          // ← Loyer hors charges
  final double chargesAmount;       // ← Charges
  final Tenant? tenant;             // ← Joined for receipt
  final Unit? unit;                 // ← Joined for address
}
```

### Tenant Entity (existing, relevant fields)

```dart
class Tenant {
  final String id;
  final String firstName;           // ← Nom locataire
  final String lastName;            // ← Prénom locataire
  final String? email;              // ← For sharing
  final String phone;
}
```

### Unit Entity (existing, relevant fields)

```dart
class Unit {
  final String id;
  final String buildingId;
  final String reference;           // ← Lot number
  final String? address;            // ← Unit address
  final Building? building;         // ← Joined for building name
}
```

### Building Entity (existing, relevant fields)

```dart
class Building {
  final String id;
  final String name;                // ← Building name
  final String address;             // ← Building address
  final String city;                // ← City
}
```

## Data Flow for Receipt Generation

```
1. User clicks "Générer quittance" on payment

2. System queries payment with related data:
   payments
     → rent_schedules (period info)
       → leases (rent/charges breakdown)
         → tenants (locataire name)
         → units (lot info)
           → buildings (address)

3. PdfReceiptService.generateReceipt(payment, schedule, lease)
   → Creates PDF document with all required fields
   → Returns Uint8List (PDF bytes)

4. Receipt saved to Supabase Storage:
   documents/receipts/{payment_id}/{receipt_number}.pdf

5. Receipt metadata inserted into receipts table:
   - payment_id
   - receipt_number
   - file_url (storage path)
   - status = 'valid'
   - generated_at = now()
   - created_by = current user

6. PDF displayed in preview → user can download/share
```

## Storage Structure

```
documents/                    # Existing bucket
├── tenants/                  # Existing: tenant documents
│   └── {tenant_id}/
│       ├── id_document_*.pdf
│       └── guarantor_id_*.pdf
└── receipts/                 # NEW: rent receipts
    └── {payment_id}/
        └── {receipt_number}.pdf
```

## Validation Rules

| Field | Rule | Error Message |
|-------|------|---------------|
| payment_id | Must reference valid payment | "Paiement introuvable" |
| receipt_number | Required, from payment | "Numéro de reçu requis" |
| file_url | Required, valid storage path | "Fichier PDF requis" |
| status | Must be 'valid' or 'cancelled' | "Statut invalide" |

## Migration Strategy

1. Create `receipts` table with RLS policies
2. No data migration needed (new table)
3. Add indexes for performance
4. Storage folder created on first upload
