# Quickstart: Génération de Quittances PDF

**Feature**: 007-pdf-receipt-generation
**Date**: 2026-01-09

## Overview

Cette fonctionnalité permet de générer des quittances de loyer au format PDF après chaque paiement. Le flux est entièrement côté client (pas de serveur backend pour la génération PDF).

## Prerequisites

1. Modules existants fonctionnels:
   - Payment Management (Phase 8)
   - Lease Management (Phase 6)
   - Tenant Management (Phase 4)
   - Building/Unit Management (Phases 2-3)

2. Supabase configuré:
   - Bucket `documents` existant
   - RLS policies en place

## Quick Setup

### 1. Add Dependencies

```bash
flutter pub add pdf printing share_plus path_provider
```

Vérifier dans `pubspec.yaml`:
```yaml
dependencies:
  pdf: ^3.10.8
  printing: ^5.12.0
  share_plus: ^7.2.2
  path_provider: ^2.1.2
```

### 2. Run Database Migration

Exécuter dans Supabase SQL Editor:

```sql
CREATE TABLE receipts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  payment_id UUID NOT NULL REFERENCES payments(id) ON DELETE SET NULL,
  receipt_number TEXT NOT NULL,
  file_url TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'valid' CHECK (status IN ('valid', 'cancelled')),
  generated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_receipts_payment_id ON receipts(payment_id);
ALTER TABLE receipts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "receipts_select_policy" ON receipts FOR SELECT
  USING (created_by = auth.uid() OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

CREATE POLICY "receipts_insert_policy" ON receipts FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL AND created_by = auth.uid());
```

### 3. Regenerate Models

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. Add Routes

Dans `lib/core/router/app_router.dart`:

```dart
static const receiptPreview = '/receipts/preview';
static const leaseReceipts = '/leases/:id/receipts';

// Dans le GoRouter
GoRoute(
  path: '/receipts/preview',
  builder: (context, state) => ReceiptPreviewPage(
    pdfBytes: state.extra as Uint8List,
  ),
),
```

## Key Files to Create

| File | Purpose |
|------|---------|
| `lib/domain/entities/receipt.dart` | Receipt entity |
| `lib/data/models/receipt_model.dart` | Freezed model |
| `lib/data/datasources/receipt_remote_datasource.dart` | Supabase operations |
| `lib/data/repositories/receipt_repository_impl.dart` | Repository implementation |
| `lib/domain/repositories/receipt_repository.dart` | Repository interface |
| `lib/presentation/services/pdf_receipt_service.dart` | PDF generation |
| `lib/presentation/providers/receipt_provider.dart` | Riverpod providers |
| `lib/presentation/pages/receipts/receipt_preview_page.dart` | PDF preview |
| `lib/presentation/widgets/receipts/generate_receipt_button.dart` | Action button |

## Integration Points

### 1. After Payment Success (PaymentFormModal)

```dart
// In payment success dialog
ElevatedButton.icon(
  onPressed: () => context.push('/receipts/preview', extra: pdfBytes),
  icon: const Icon(Icons.receipt_long),
  label: const Text('Générer quittance'),
),
```

### 2. In Payment History List

```dart
// Add action button to each payment row
IconButton(
  icon: const Icon(Icons.receipt_long),
  onPressed: () => _generateReceipt(context, ref, payment.id),
),
```

### 3. In Lease Detail Page

```dart
// Add receipts section
ExpansionTile(
  title: const Text('Quittances'),
  children: [
    LeaseReceiptsList(leaseId: lease.id),
  ],
),
```

## Testing Checklist

- [ ] Generate receipt after new payment
- [ ] Preview PDF displays correctly
- [ ] Download saves file to device
- [ ] Share opens native share sheet
- [ ] Partial payment shows "Acompte" notice
- [ ] Receipt list appears in lease detail
- [ ] Receipt persists after app restart
- [ ] French formatting correct (dates, currency)

## Common Issues

### PDF not rendering French characters

Use built-in Helvetica font (supports Latin characters).

### Share not working on web

Web uses different share mechanism - fallback to download.

### Storage upload fails

Check RLS policies on `documents` bucket allow authenticated users.

## Next Steps

After implementation, run:
- `flutter analyze` - fix any issues
- `flutter test` - run all tests
- Manual testing on Android/iOS/Web
