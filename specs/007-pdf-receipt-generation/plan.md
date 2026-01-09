# Implementation Plan: Génération de Quittances PDF

**Branch**: `007-pdf-receipt-generation` | **Date**: 2026-01-09 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/007-pdf-receipt-generation/spec.md`

## Summary

Cette fonctionnalité permet aux gestionnaires de générer, prévisualiser, télécharger, sauvegarder et partager des quittances de loyer au format PDF après chaque paiement. Le système utilise les packages Flutter `pdf` et `printing` pour la génération côté client, avec stockage dans Supabase Storage (bucket `documents`) et une nouvelle table `receipts` pour le suivi des métadonnées.

## Technical Context

**Language/Version**: Dart 3.x (Flutter SDK stable)
**Primary Dependencies**: flutter_riverpod 2.6.x, go_router 14.x, freezed 2.5.x, supabase_flutter 2.8.x, pdf 3.x, printing 5.x, share_plus 7.x, path_provider 2.x
**Storage**: Supabase PostgreSQL (receipts table) + Supabase Storage (documents bucket)
**Testing**: flutter test
**Target Platform**: Android, iOS, Web
**Project Type**: Mobile/Web Flutter application
**Performance Goals**: PDF generation < 5 seconds, PDF file size < 500KB
**Constraints**: Offline mode requires connection for generation, French localization required
**Scale/Scope**: ~50-150 receipts/month per manager

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Clean Architecture | ✅ Pass | ReceiptService in Data layer, ReceiptRepository interface in Domain, UI in Presentation |
| II. Mobile-First UX | ✅ Pass | Share via native apps, touch-friendly buttons, loading states |
| III. Supabase-First Data | ✅ Pass | Storage in `documents` bucket, RLS on `receipts` table |
| IV. French Localization | ✅ Pass | PDF content in French, FCFA currency, DD/MM/YYYY dates |
| V. Security by Design | ✅ Pass | Signed URLs for PDF access, RLS policies, created_by audit |

## Project Structure

### Documentation (this feature)

```text
specs/007-pdf-receipt-generation/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
lib/
├── core/
│   └── utils/
│       └── formatters.dart          # Existing - FCFA/date formatting
├── data/
│   ├── datasources/
│   │   └── receipt_remote_datasource.dart    # NEW: Supabase operations
│   ├── models/
│   │   └── receipt_model.dart                # NEW: Freezed model
│   └── repositories/
│       └── receipt_repository_impl.dart      # NEW: Repository impl
├── domain/
│   ├── entities/
│   │   └── receipt.dart                      # NEW: Receipt entity
│   └── repositories/
│       └── receipt_repository.dart           # NEW: Repository interface
├── presentation/
│   ├── pages/
│   │   └── receipts/
│   │       ├── receipt_preview_page.dart     # NEW: Full-screen PDF preview
│   │       └── receipt_history_page.dart     # NEW: Receipt list by lease
│   ├── providers/
│   │   └── receipt_provider.dart             # NEW: Riverpod providers
│   ├── services/
│   │   └── pdf_receipt_service.dart          # NEW: PDF generation logic
│   └── widgets/
│       └── receipts/
│           ├── generate_receipt_button.dart  # NEW: Action button
│           └── receipt_list_item.dart        # NEW: List item widget

supabase/
└── migrations/
    └── 20260109_create_receipts_table.sql    # NEW: Database migration
```

**Structure Decision**: Single project structure following existing LocaGest patterns. PDF generation service is placed in `presentation/services/` as it's UI-specific (uses printing package), while data operations follow the established Clean Architecture layers.

## Complexity Tracking

> No violations - implementation follows existing patterns.

| Aspect | Complexity | Justification |
|--------|------------|---------------|
| New table (receipts) | Low | Simple metadata table, follows existing patterns |
| PDF generation | Medium | Client-side generation using pdf package, no server code |
| Share functionality | Low | Uses native share_plus, platform-handled |
| Storage | Low | Reuses existing `documents` bucket and patterns |
