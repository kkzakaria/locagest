# Tasks: Génération de Quittances PDF

**Input**: Design documents from `/specs/007-pdf-receipt-generation/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Not explicitly requested - tests are NOT included in this task list.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Project type**: Flutter mobile/web application
- **Paths**: `lib/` for source code, `supabase/migrations/` for database

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Add dependencies and configure project for PDF generation

- [x] T001 Add pdf, printing, share_plus, path_provider dependencies to pubspec.yaml
- [x] T002 Run flutter pub get to install dependencies
- [x] T003 Create database migration file in supabase/migrations/20260109_create_receipts_table.sql

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 Create Receipt entity in lib/domain/entities/receipt.dart
- [x] T005 [P] Create ReceiptModel (Freezed) in lib/data/models/receipt_model.dart
- [x] T006 [P] Create ReceiptRepository interface in lib/domain/repositories/receipt_repository.dart
- [x] T007 Create ReceiptRemoteDatasource in lib/data/datasources/receipt_remote_datasource.dart
- [x] T008 Create ReceiptRepositoryImpl in lib/data/repositories/receipt_repository_impl.dart
- [x] T009 Run flutter pub run build_runner build --delete-conflicting-outputs
- [x] T010 Create ReceiptData and ReceiptDataBuilder classes in lib/presentation/services/receipt_data.dart
- [x] T011 Create PdfReceiptService in lib/presentation/services/pdf_receipt_service.dart
- [x] T012 Create receipt providers in lib/presentation/providers/receipts_provider.dart
- [x] T013 Add receipt routes to lib/core/router/app_router.dart

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Générer une quittance après paiement (Priority: P1) 🎯 MVP

**Goal**: Permettre aux gestionnaires de générer une quittance PDF immédiatement après un paiement

**Independent Test**: Après avoir enregistré un paiement, cliquer sur "Générer quittance" et vérifier qu'un PDF est généré avec toutes les informations correctes

### Implementation for User Story 1

- [x] T014 [US1] Implement PDF layout sections (header, landlord, tenant, payment details, footer) in lib/presentation/services/pdf_receipt_service.dart
- [x] T015 [US1] Implement partial payment notice section in pdf_receipt_service.dart
- [x] T016 [US1] Implement generateFilename method for PDF naming convention in pdf_receipt_service.dart
- [x] T017 [US1] Create GenerateReceiptButton widget in lib/presentation/widgets/receipts/generate_receipt_button.dart
- [x] T018 [US1] Add GenerateReceiptNotifier state management in lib/presentation/providers/receipts_provider.dart
- [x] T019 [US1] Integrate GenerateReceiptButton into payment success dialog in lib/presentation/pages/payments/payment_form_modal.dart
- [x] T020 [US1] Add "Generer quittance" action to payment history list in lib/presentation/widgets/payments/payment_history_list.dart

**Checkpoint**: User Story 1 - Gestionnaires peuvent générer des quittances après paiement

---

## Phase 4: User Story 2 - Prévisualiser et télécharger la quittance (Priority: P1)

**Goal**: Permettre aux gestionnaires de prévisualiser, télécharger et imprimer les quittances

**Independent Test**: Après génération, vérifier que l'aperçu s'affiche et que le téléchargement produit un PDF valide

### Implementation for User Story 2

- [x] T021 [US2] Create ReceiptPreviewPage with PdfPreview widget in lib/presentation/pages/receipts/receipt_preview_page.dart
- [x] T022 [US2] Implement download action using Printing.sharePdf in receipt_preview_page.dart
- [x] T023 [US2] Implement print action using Printing.layoutPdf in receipt_preview_page.dart
- [x] T024 [US2] Add navigation from GenerateReceiptButton to preview page
- [x] T025 [US2] Implement loading and error states in preview page

**Checkpoint**: User Story 2 - Gestionnaires peuvent prévisualiser, télécharger et imprimer les quittances

---

## Phase 5: User Story 3 - Sauvegarder la quittance dans le système (Priority: P2)

**Goal**: Sauvegarder automatiquement les quittances générées dans le stockage cloud

**Independent Test**: Générer une quittance, puis la retrouver dans l'historique du bail

### Implementation for User Story 3

- [x] T026 [US3] Implement uploadReceiptPdf method in lib/data/datasources/receipt_remote_datasource.dart
- [x] T027 [US3] Implement createReceipt method in receipt_remote_datasource.dart
- [x] T028 [US3] Implement getReceiptsForPayment method in receipt_remote_datasource.dart
- [x] T029 [US3] Implement getReceiptsForLease method in receipt_remote_datasource.dart
- [x] T030 [US3] Implement getReceiptDownloadUrl method with signed URLs in receipt_remote_datasource.dart
- [x] T031 [US3] Update GenerateReceiptNotifier to save receipt after generation
- [x] T032 [US3] Create ReceiptListItem widget in lib/presentation/widgets/receipts/receipt_list_item.dart
- [x] T033 [US3] Add receipts section to lease detail page in lib/presentation/pages/leases/lease_detail_page.dart

**Checkpoint**: User Story 3 - Quittances sauvegardées et accessibles depuis le détail du bail

---

## Phase 6: User Story 4 - Partager la quittance avec le locataire (Priority: P2)

**Goal**: Permettre le partage facile de la quittance par email ou messagerie

**Independent Test**: Depuis l'aperçu, utiliser l'option de partage et vérifier que le document peut être envoyé

### Implementation for User Story 4

- [x] T034 [US4] Implement shareReceipt method using share_plus in lib/presentation/services/pdf_receipt_service.dart
- [x] T035 [US4] Add share button to ReceiptPreviewPage
- [x] T036 [US4] Implement email pre-fill with tenant email when available
- [x] T037 [US4] Add share action to ReceiptPreviewDialog (via PdfPreview built-in sharing)
- [x] T038 [US4] Handle web platform share fallback (share button hidden on web)

**Checkpoint**: User Story 4 - Gestionnaires peuvent partager les quittances facilement

---

## Phase 7: User Story 5 - Consulter l'historique des quittances d'un locataire (Priority: P3)

**Goal**: Permettre de consulter toutes les quittances générées pour un locataire

**Independent Test**: Accéder à la fiche d'un locataire et vérifier que la liste des quittances est visible

### Implementation for User Story 5

- [x] T039 [US5] Implement getReceiptsForTenant method in lib/data/datasources/receipt_remote_datasource.dart
- [x] T040 [US5] Add tenantReceiptsProvider in lib/presentation/providers/receipts_provider.dart
- [x] T041 [US5] Add receipts section to tenant detail page in lib/presentation/pages/tenants/tenant_detail_page.dart
- [x] T042 [US5] Create TenantReceiptsList widget with limit support (in receipt_list_item.dart)

**Checkpoint**: User Story 5 - Historique des quittances accessible depuis la fiche locataire

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [x] T043 [P] Handle edge case: cancelled payment - receipt generation handles non-found cases
- [x] T044 [P] Handle edge case: offline mode - Supabase/network errors shown with French messages
- [x] T045 [P] Add loading states to all async operations
- [x] T046 [P] Ensure French localization for all error messages
- [ ] T047 Verify PDF renders correctly on Android, iOS, and Web (requires manual testing)
- [x] T048 Run flutter analyze and fix any issues (6 pre-existing info-level issues)
- [x] T049 Run quickstart.md validation checklist (all critical files created)
- [x] T050 Update app_router.dart exports - routes added for receipt preview

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-7)**: All depend on Foundational phase completion
- **Polish (Phase 8)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - MVP story, no dependencies
- **User Story 2 (P1)**: Depends on US1 (needs generated PDF bytes to preview)
- **User Story 3 (P2)**: Depends on US1 and US2 (needs generated PDF to save)
- **User Story 4 (P2)**: Depends on US2 (needs preview page for share button)
- **User Story 5 (P3)**: Depends on US3 (needs saved receipts to display history)

### Within Each User Story

- Service methods before UI components
- Core functionality before edge cases
- Story complete before moving to next priority

### Parallel Opportunities

- T005 and T006 can run in parallel (different files)
- All Phase 8 tasks marked [P] can run in parallel
- Once Foundational phase completes, US1 implementation can begin

---

## Parallel Example: Phase 2 (Foundational)

```bash
# These can run in parallel:
Task: "Create ReceiptModel (Freezed) in lib/data/models/receipt_model.dart"
Task: "Create ReceiptRepository interface in lib/domain/repositories/receipt_repository.dart"
```

## Parallel Example: Phase 8 (Polish)

```bash
# These can run in parallel:
Task: "Handle edge case: cancelled payment shows 'Paiement annulé'"
Task: "Handle edge case: offline mode shows connection required message"
Task: "Add loading states to all async operations"
Task: "Ensure French localization for all error messages"
```

---

## Implementation Strategy

### MVP First (User Stories 1 + 2)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1 (Generate receipt)
4. Complete Phase 4: User Story 2 (Preview/download)
5. **STOP and VALIDATE**: Test receipt generation end-to-end
6. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 + 2 → Test independently → Deploy/Demo (MVP!)
3. Add User Story 3 → Test independently → Deploy/Demo (Cloud storage)
4. Add User Story 4 → Test independently → Deploy/Demo (Share functionality)
5. Add User Story 5 → Test independently → Deploy/Demo (History view)
6. Each story adds value without breaking previous stories

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- PDF generation is client-side using pdf package - no server needed
- Storage uses existing `documents` bucket in Supabase
