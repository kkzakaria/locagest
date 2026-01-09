# Research: Génération de Quittances PDF

**Feature**: 007-pdf-receipt-generation
**Date**: 2026-01-09
**Status**: Complete

## Research Questions

### Q1: Which PDF generation package is best for Flutter?

**Answer**: The `pdf` package (dart-pdf) combined with `printing` package.

**Rationale**:
- `pdf` (v3.x): Pure Dart PDF generation, works on all platforms (Android, iOS, Web)
- `printing`: Provides preview, print, and share functionality
- Both maintained by DavBfr, well-documented, and widely used
- Already listed in constitution.md as the standard for LocaGest

**Alternatives Considered**:
- `syncfusion_flutter_pdf`: Feature-rich but requires license for commercial use
- `native_pdf_view`: Read-only, doesn't generate PDFs
- Server-side generation: Adds complexity, not needed for simple receipts

### Q2: How to structure the PDF content for a rent receipt (quittance)?

**Answer**: French legal receipt format with the following sections:

```
+------------------------------------------+
|           QUITTANCE DE LOYER             |
|           [Mois] [Année]                 |
+------------------------------------------+
| BAILLEUR                                 |
| [Nom du gestionnaire/propriétaire]       |
| [Coordonnées si disponibles]             |
+------------------------------------------+
| LOCATAIRE                                |
| [Nom complet du locataire]               |
| [Adresse du bien loué]                   |
| [Immeuble - Lot]                         |
| [Ville]                                  |
+------------------------------------------+
| DÉTAIL DU PAIEMENT                       |
| Loyer (hors charges): XXX XXX FCFA       |
| Charges: XXX XXX FCFA                    |
| TOTAL: XXX XXX FCFA                      |
+------------------------------------------+
| Date de paiement: DD/MM/YYYY             |
| Mode de paiement: [Espèces/Chèque/...]   |
| Numéro de reçu: [RECEIPT_NUMBER]         |
+------------------------------------------+
| [Si paiement partiel]                    |
| ACOMPTE - Solde restant: XXX XXX FCFA    |
+------------------------------------------+
| Pour valoir ce que de droit.             |
| Fait le [date de génération]             |
+------------------------------------------+
```

### Q3: Where to store generated PDFs?

**Answer**: Supabase Storage in the existing `documents` bucket.

**Path Pattern**: `receipts/{payment_id}/{receipt_number}.pdf`

**Rationale**:
- Bucket already exists and has RLS policies
- Consistent with tenant document storage pattern
- Signed URLs provide secure, time-limited access
- Payment ID as folder groups receipts for a payment (regenerations)

### Q4: What metadata to track for receipts?

**Answer**: New `receipts` table with:

| Column | Type | Description |
|--------|------|-------------|
| id | uuid | Primary key |
| payment_id | uuid | FK to payments |
| receipt_number | text | Copied from payment for quick access |
| file_url | text | Storage path (not signed URL) |
| status | text | 'valid' or 'cancelled' |
| generated_at | timestamp | When PDF was created |
| created_by | uuid | FK to profiles |

**Rationale**:
- Allows multiple receipts per payment (regeneration)
- Status tracks if payment was later deleted
- File URL stored, signed URL generated on demand

### Q5: How to handle the share functionality?

**Answer**: Use `share_plus` package for native sharing.

**Flow**:
1. Generate PDF bytes in memory
2. Save to temporary directory (path_provider)
3. Call Share.shareXFiles with the PDF path
4. Native share sheet appears with email, WhatsApp, etc.

**Email Pre-fill**:
- If tenant has email, include in share text
- Email apps will pick up the attachment and recipient

### Q6: How to integrate with payment success flow?

**Answer**: Add "Générer quittance" button in payment success dialog.

**Location**: After PaymentFormModal shows success message
**Action**: Navigate to ReceiptPreviewPage with payment ID
**Alternative**: Quick action from payment history list

### Q7: What fonts to use in PDF?

**Answer**: Use built-in PDF fonts (Helvetica) for reliability.

**Rationale**:
- Custom fonts require embedding, increases file size
- Helvetica supports French characters (é, è, à, etc.)
- Consistent rendering across all platforms
- Can add custom fonts later if branding needed

## Technical Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| PDF library | pdf + printing | Industry standard, cross-platform |
| Storage location | documents bucket | Existing, secured, consistent |
| Generation timing | On-demand | No background jobs needed |
| File naming | {receipt_number}.pdf | Unique, human-readable |
| Preview approach | PdfPreview widget | Built into printing package |
| Share method | share_plus | Native OS integration |

## Dependencies to Add

```yaml
dependencies:
  pdf: ^3.10.8
  printing: ^5.12.0
  share_plus: ^7.2.2
  path_provider: ^2.1.2
```

## Database Migration Required

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

-- RLS policies
ALTER TABLE receipts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own receipts"
  ON receipts FOR SELECT
  USING (created_by = auth.uid() OR
         EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

CREATE POLICY "Users can insert own receipts"
  ON receipts FOR INSERT
  WITH CHECK (created_by = auth.uid());
```

## Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| PDF generation slow on old devices | Medium | Medium | Show loading state, optimize content |
| Large PDF files | Low | Low | Keep content simple, no images |
| Storage quota exceeded | Low | Medium | Monitor usage, implement cleanup |
| Share fails on some devices | Low | Low | Fallback to download only |

## Open Questions (Resolved)

All questions resolved during research. No blockers for implementation.
