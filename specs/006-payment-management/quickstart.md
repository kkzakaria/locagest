# Quickstart: Module Echeances et Paiements

**Feature**: 006-payment-management
**Date**: 2026-01-08

## Prerequisites

Before starting implementation, ensure:

1. LocaGest development environment is set up (Flutter SDK, VS Code/Android Studio)
2. Supabase project is running with existing tables (profiles, buildings, units, tenants, leases, rent_schedules)
3. Phase 7 (Lease Management) is complete and working
4. You have admin access to the Supabase dashboard

## Quick Setup

### 1. Run Database Migration

Apply the payments table migration:

```bash
# Navigate to project root
cd /home/superz/development/locagest

# Copy migration to supabase folder
cp specs/006-payment-management/contracts/006_payments.sql supabase/migrations/

# Apply migration via Supabase dashboard or CLI
# Option A: Supabase Dashboard
# Go to SQL Editor > paste contents of 006_payments.sql > Run

# Option B: Supabase CLI (if configured)
supabase db push
```

### 2. Verify Migration

Run this SQL query to verify the payments table exists:

```sql
SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_name = 'payments'
ORDER BY ordinal_position;
```

Expected output should show: id, rent_schedule_id, amount, payment_date, payment_method, reference, check_number, bank_name, receipt_number, notes, created_by, created_at

### 3. Create Domain Entity

Create `lib/domain/entities/payment.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum PaymentMethod {
  cash,
  check,
  transfer,
  mobileMoney;

  static PaymentMethod fromString(String value) {
    switch (value) {
      case 'cash': return PaymentMethod.cash;
      case 'check': return PaymentMethod.check;
      case 'transfer': return PaymentMethod.transfer;
      case 'mobile_money': return PaymentMethod.mobileMoney;
      default: return PaymentMethod.cash;
    }
  }

  String toJson() {
    switch (this) {
      case PaymentMethod.cash: return 'cash';
      case PaymentMethod.check: return 'check';
      case PaymentMethod.transfer: return 'transfer';
      case PaymentMethod.mobileMoney: return 'mobile_money';
    }
  }

  String get label {
    switch (this) {
      case PaymentMethod.cash: return 'Especes';
      case PaymentMethod.check: return 'Cheque';
      case PaymentMethod.transfer: return 'Virement bancaire';
      case PaymentMethod.mobileMoney: return 'Mobile Money';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMethod.cash: return Icons.money;
      case PaymentMethod.check: return Icons.receipt_long;
      case PaymentMethod.transfer: return Icons.account_balance;
      case PaymentMethod.mobileMoney: return Icons.phone_android;
    }
  }
}

class Payment {
  final String id;
  final String rentScheduleId;
  final double amount;
  final DateTime paymentDate;
  final PaymentMethod paymentMethod;
  final String? reference;
  final String? checkNumber;
  final String? bankName;
  final String receiptNumber;
  final String? notes;
  final String? createdBy;
  final DateTime createdAt;

  const Payment({
    required this.id,
    required this.rentScheduleId,
    required this.amount,
    required this.paymentDate,
    required this.paymentMethod,
    this.reference,
    this.checkNumber,
    this.bankName,
    required this.receiptNumber,
    this.notes,
    this.createdBy,
    required this.createdAt,
  });

  String get amountFormatted {
    final formatter = NumberFormat('#,###', 'fr_FR');
    return '${formatter.format(amount.round())} FCFA';
  }

  String get paymentDateFormatted {
    return DateFormat('dd/MM/yyyy').format(paymentDate);
  }

  String get methodLabel => paymentMethod.label;
}
```

### 4. Create Freezed Model

Create `lib/data/models/payment_model.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/payment.dart';

part 'payment_model.freezed.dart';
part 'payment_model.g.dart';

@freezed
class PaymentModel with _$PaymentModel {
  const PaymentModel._();

  const factory PaymentModel({
    required String id,
    @JsonKey(name: 'rent_schedule_id') required String rentScheduleId,
    required double amount,
    @JsonKey(name: 'payment_date') required DateTime paymentDate,
    @JsonKey(name: 'payment_method') required String paymentMethod,
    String? reference,
    @JsonKey(name: 'check_number') String? checkNumber,
    @JsonKey(name: 'bank_name') String? bankName,
    @JsonKey(name: 'receipt_number') required String receiptNumber,
    String? notes,
    @JsonKey(name: 'created_by') String? createdBy,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _PaymentModel;

  factory PaymentModel.fromJson(Map<String, dynamic> json) =>
      _$PaymentModelFromJson(json);

  Payment toEntity() => Payment(
    id: id,
    rentScheduleId: rentScheduleId,
    amount: amount,
    paymentDate: paymentDate,
    paymentMethod: PaymentMethod.fromString(paymentMethod),
    reference: reference,
    checkNumber: checkNumber,
    bankName: bankName,
    receiptNumber: receiptNumber,
    notes: notes,
    createdBy: createdBy,
    createdAt: createdAt,
  );
}
```

### 5. Generate Freezed Code

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 6. Verify Setup

Create a simple test to verify the payment can be created:

```dart
// In lease_detail_page.dart or a test file
final testPayment = Payment(
  id: 'test-id',
  rentScheduleId: 'schedule-id',
  amount: 150000,
  paymentDate: DateTime.now(),
  paymentMethod: PaymentMethod.cash,
  receiptNumber: 'QUI-202601-0001',
  createdAt: DateTime.now(),
);

print('Amount: ${testPayment.amountFormatted}'); // "150 000 FCFA"
print('Method: ${testPayment.methodLabel}'); // "Especes"
```

## Development Order

Follow this sequence for implementation:

1. **Database** (Migration 006_payments.sql)
2. **Domain Layer** (Payment entity, PaymentRepository interface)
3. **Data Layer** (PaymentModel, PaymentRemoteDatasource, PaymentRepositoryImpl)
4. **Presentation Layer** (PaymentsProvider, PaymentsPage, PaymentFormModal)
5. **Integration** (Update app_router.dart, lease_detail_page.dart, tenant_detail_page.dart)
6. **Testing** (Unit tests, E2E tests)

## Key Files to Create

| Layer | File | Purpose |
|-------|------|---------|
| Domain | `lib/domain/entities/payment.dart` | Payment entity + PaymentMethod enum |
| Domain | `lib/domain/repositories/payment_repository.dart` | Repository interface |
| Data | `lib/data/models/payment_model.dart` | Freezed model |
| Data | `lib/data/datasources/payment_remote_datasource.dart` | Supabase CRUD |
| Data | `lib/data/repositories/payment_repository_impl.dart` | Repository impl |
| Presentation | `lib/presentation/providers/payments_provider.dart` | Riverpod providers |
| Presentation | `lib/presentation/pages/payments/payments_page.dart` | Main page |
| Presentation | `lib/presentation/pages/payments/payment_form_modal.dart` | Payment form |
| Presentation | `lib/presentation/widgets/payments/rent_schedule_card.dart` | List item widget |

## Key Files to Modify

| File | Change |
|------|--------|
| `lib/core/router/app_router.dart` | Add `/payments` route |
| `lib/presentation/pages/leases/lease_detail_page.dart` | Use new PaymentFormModal |
| `lib/presentation/pages/tenants/tenant_detail_page.dart` | Add payment summary section |
| `lib/presentation/pages/home/dashboard_page.dart` | Add payments navigation |

## Testing Checklist

Before marking complete, verify:

- [ ] Can create a full payment (amount = balance)
- [ ] Can create a partial payment
- [ ] Can create a second partial payment to complete
- [ ] Schedule status updates correctly (pending → partial → paid)
- [ ] Receipt number is auto-generated
- [ ] Overdue schedules display correctly
- [ ] Filters work on payments page
- [ ] Tenant payment summary displays correctly
- [ ] Admin can delete payments
- [ ] Gestionnaire can only see their payments
- [ ] Assistant can record but not delete payments

## Common Issues

### Receipt number generation fails
Check that the `generate_receipt_number()` function exists and has correct permissions.

### RLS blocks payment insert
Verify the assistant_insert_payments policy allows INSERT for assistant role.

### Schedule status not updating
Check the `update_rent_schedule_on_payment` trigger is active.

### Freezed generation fails
Run `flutter clean` then `flutter pub get` before build_runner.
