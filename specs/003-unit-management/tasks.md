# Tasks: Module Lots/Unités (Unit Management)

**Input**: Design documents from `/specs/003-unit-management/`
**Prerequisites**: plan.md, spec.md, data-model.md, contracts/unit-api.md, research.md

**Tests**: Not explicitly requested - test tasks omitted.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

Based on plan.md, this is a Flutter mobile project with Clean Architecture:
- **Domain**: `lib/domain/` (entities, repository interfaces, use cases)
- **Data**: `lib/data/` (models, datasources, repository implementations)
- **Presentation**: `lib/presentation/` (providers, pages, widgets)
- **Core**: `lib/core/` (errors, utils)
- **Migrations**: `supabase/migrations/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Database migration and core exceptions/utilities needed by all user stories

- [x] T001 Create database migration file in `supabase/migrations/003_units.sql` with units table, constraints, indexes, RLS policies, triggers per contracts/unit-api.md
- [x] T002 [P] Create unit exceptions in `lib/core/errors/unit_exceptions.dart` per contracts/unit-api.md (UnitNotFoundException, UnitDuplicateReferenceException, etc.)
- [x] T003 [P] Add unit validators to `lib/core/utils/validators.dart` (validateReference, validateBaseRent, validateSurfaceArea, validateRoomsCount, validateChargesAmount)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Domain and Data layer components that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 Create Unit entity with enums (UnitType, UnitStatus) in `lib/domain/entities/unit.dart` per data-model.md including computed properties (totalMonthlyRent, typeLabel, statusLabel, statusColor, floorDisplay, surfaceDisplay)
- [x] T005 Create UnitModel with Freezed, CreateUnitInput, UpdateUnitInput in `lib/data/models/unit_model.dart` per data-model.md
- [x] T006 Run `flutter pub run build_runner build --delete-conflicting-outputs` to generate unit_model.freezed.dart and unit_model.g.dart
- [x] T007 Create UnitRepository interface in `lib/domain/repositories/unit_repository.dart` per contracts/unit-api.md
- [x] T008 Create UnitRemoteDatasource in `lib/data/datasources/unit_remote_datasource.dart` with Supabase CRUD operations per contracts/unit-api.md
- [x] T009 Create UnitRepositoryImpl in `lib/data/repositories/unit_repository_impl.dart` implementing UnitRepository interface
- [x] T010 Create Riverpod providers in `lib/presentation/providers/units_provider.dart` (unitRepositoryProvider, unitsByBuildingProvider, unitByIdProvider, canManageUnitsProvider)

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - View Units List (Priority: P1) 🎯 MVP

**Goal**: Display all units within a building with status badges in a scrollable list

**Independent Test**: Navigate to a building detail page and verify units list displays with reference, type, floor, rent, and status badge

### Implementation for User Story 1

- [x] T011 [P] [US1] Create GetUnitsByBuilding use case in `lib/domain/usecases/get_units_by_building.dart`
- [x] T012 [P] [US1] Create UnitStatusBadge widget in `lib/presentation/widgets/units/unit_status_badge.dart` with Constitution colors (🔴 vacant, 🟢 occupied, 🟠 maintenance)
- [x] T013 [US1] Create UnitCard widget in `lib/presentation/widgets/units/unit_card.dart` displaying reference, type, floor, rent (FCFA format), and status badge
- [x] T014 [US1] Create units list section in `lib/presentation/pages/buildings/building_detail_page.dart` - add units tab/section with lazy loading list of UnitCard widgets
- [x] T015 [US1] Add empty state widget for buildings with no units (French text: "Aucun lot dans cet immeuble")
- [x] T016 [US1] Add loading state for units list fetch operation
- [x] T017 [US1] Add error handling with French error messages for units list

**Checkpoint**: User Story 1 complete - can view units list in building detail

---

## Phase 4: User Story 2 - Create a New Unit (Priority: P1) 🎯 MVP

**Goal**: Register new rental units within a building with form validation

**Independent Test**: Click "Add Unit" on building detail, fill form with valid data, submit, and verify unit appears in list with correct data

### Implementation for User Story 2

- [x] T018 [P] [US2] Create CreateUnit use case in `lib/domain/usecases/create_unit.dart`
- [x] T019 [P] [US2] Create UnitForm widget in `lib/presentation/widgets/units/unit_form.dart` with fields: reference, type dropdown, floor, surface area, rooms count, base rent, charges amount, charges included toggle, description
- [x] T020 [US2] Create UnitFormPage in `lib/presentation/pages/units/unit_form_page.dart` for creating new units
- [x] T021 [US2] Add form validation with French error messages per data-model.md validators
- [x] T022 [US2] Add "Ajouter un lot" FAB or button in building_detail_page.dart (visible only for gestionnaire/admin via canManageUnits)
- [x] T023 [US2] Add route for unit form page in `lib/core/router/app_router.dart` (/buildings/:id/units/new)
- [x] T024 [US2] Add success snackbar in French ("Lot créé avec succès") and navigate back to building detail
- [x] T025 [US2] Invalidate unitsByBuildingProvider cache after creation to refresh list
- [x] T026 [US2] Handle duplicate reference error with French message ("Cette référence existe déjà dans cet immeuble")

**Checkpoint**: User Stories 1 AND 2 complete - can view and create units (MVP)

---

## Phase 5: User Story 3 - View Unit Details (Priority: P2)

**Goal**: Display complete unit information including photos and equipment

**Independent Test**: Tap on a unit card and verify all unit fields are displayed correctly with FCFA currency formatting

### Implementation for User Story 3

- [x] T027 [P] [US3] Create GetUnitById use case in `lib/domain/usecases/get_unit_by_id.dart`
- [x] T028 [US3] Create UnitDetailPage in `lib/presentation/pages/units/unit_detail_page.dart` showing all unit fields per data-model.md
- [x] T029 [US3] Add FCFA currency formatting for rent and charges display (e.g., "150 000 FCFA")
- [x] T030 [US3] Add floor display logic (RDC for 0, Sous-sol X for negative, Étage X for positive)
- [x] T031 [US3] Display equipment list if present (simple chips or list)
- [x] T032 [US3] Display photos gallery placeholder (full implementation in US6)
- [x] T033 [US3] Add route for unit detail page in `lib/core/router/app_router.dart` (/units/:id)
- [x] T034 [US3] Make UnitCard tappable to navigate to unit detail page
- [x] T035 [US3] Add loading and error states for unit detail fetch

**Checkpoint**: User Story 3 complete - can view full unit details

---

## Phase 6: User Story 4 - Edit Unit Information (Priority: P2)

**Goal**: Update unit details with pre-filled form and validation

**Independent Test**: Click Edit on unit detail page, modify fields, save, and verify changes persist across sessions

### Implementation for User Story 4

- [x] T036 [P] [US4] Create UpdateUnit use case in `lib/domain/usecases/update_unit.dart`
- [x] T037 [US4] Create UnitEditPage in `lib/presentation/pages/units/unit_edit_page.dart` with pre-filled UnitForm
- [x] T038 [US4] Add "Modifier" button/icon in unit_detail_page.dart (visible only for gestionnaire/admin)
- [x] T039 [US4] Add route for unit edit page in `lib/core/router/app_router.dart` (/units/:id/edit)
- [x] T040 [US4] Handle status change validation (prevent occupied→maintenance if lease exists - for future)
- [x] T041 [US4] Add success snackbar in French ("Lot modifié avec succès")
- [x] T042 [US4] Invalidate unitByIdProvider and unitsByBuildingProvider caches after update
- [x] T043 [US4] Handle duplicate reference error on edit

**Checkpoint**: User Story 4 complete - can edit units

---

## Phase 7: User Story 5 - Delete a Unit (Priority: P3)

**Goal**: Remove units with confirmation dialog and proper validation

**Independent Test**: Click Delete on a vacant unit, confirm deletion, verify unit removed from building list and count decremented

### Implementation for User Story 5

- [x] T044 [P] [US5] Create DeleteUnit use case in `lib/domain/usecases/delete_unit.dart`
- [x] T045 [US5] Add delete button/icon in unit_detail_page.dart (visible only for gestionnaire/admin)
- [x] T046 [US5] Create confirmation dialog with French text ("Êtes-vous sûr de vouloir supprimer ce lot ? Cette action est irréversible.")
- [x] T047 [US5] Add pre-delete validation (check for active leases - stub for future)
- [x] T048 [US5] Handle UnitHasActiveLeaseException with French error message
- [x] T049 [US5] Add success snackbar ("Lot supprimé avec succès") and navigate back to building detail
- [x] T050 [US5] Invalidate caches after deletion

**Checkpoint**: User Story 5 complete - can delete units

---

## Phase 8: User Story 6 - Manage Unit Photos (Priority: P3)

**Goal**: Upload, view, and delete unit photos with compression

**Independent Test**: Upload a photo from device, verify it appears in gallery, delete it and verify removal

### Implementation for User Story 6

- [x] T051 [P] [US6] Create UploadUnitPhoto use case in `lib/domain/usecases/upload_unit_photo.dart` with image compression logic
- [x] T052 [US6] Create UnitPhotosGallery widget in `lib/presentation/widgets/units/unit_photos_gallery.dart` displaying photos in grid/carousel
- [x] T053 [US6] Add photo upload button to unit edit page using image_picker package
- [x] T054 [US6] Implement image compression before upload (max 1MB)
- [x] T055 [US6] Show upload progress indicator during photo upload
- [x] T056 [US6] Add photo delete functionality with confirmation dialog
- [x] T057 [US6] Update photos array in unit after upload/delete
- [x] T058 [US6] Handle UnitPhotoUploadException and UnitPhotoTooLargeException with French messages
- [x] T059 [US6] Add storage policy for units folder to migration if not present

**Checkpoint**: User Story 6 complete - can manage photos

---

## Phase 9: User Story 7 - Manage Unit Equipment List (Priority: P3)

**Goal**: Add, edit, and remove equipment items for units

**Independent Test**: Add equipment items to a unit, verify they appear in unit details, edit and delete items

### Implementation for User Story 7

- [x] T060 [US7] Create EquipmentListEditor widget in `lib/presentation/widgets/units/equipment_list_editor.dart` with add/edit/remove functionality
- [x] T061 [US7] Add EquipmentListEditor to UnitForm and UnitEditPage
- [x] T062 [US7] Implement add equipment item with text input
- [x] T063 [US7] Implement remove equipment item with confirmation
- [x] T064 [US7] Display equipment list in UnitDetailPage as chips or bullet list
- [x] T065 [US7] Save equipment array as part of unit create/update

**Checkpoint**: User Story 7 complete - can manage equipment

---

## Phase 10: Polish & Cross-Cutting Concerns

**Purpose**: Final validation, role-based access, and cross-cutting improvements

- [ ] T066 Apply database migration to Supabase (`supabase db push` or run SQL)
- [ ] T067 Verify RLS policies work correctly for admin, gestionnaire, and assistant roles
- [ ] T068 Verify building total_units trigger updates count on unit create/delete
- [x] T069 Add role-based UI visibility throughout (hide CRUD buttons for assistant role)
- [x] T070 [P] Run `flutter analyze` and fix any warnings/errors
- [ ] T071 [P] Test pagination/lazy loading with 50+ units
- [ ] T072 Run quickstart.md validation checklist
- [ ] T073 Manual end-to-end testing of all user stories

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies - can start immediately
- **Phase 2 (Foundational)**: Depends on Phase 1 (migration for DB, exceptions for error handling)
- **Phases 3-9 (User Stories)**: All depend on Phase 2 completion
  - Can proceed sequentially (P1 → P2 → P3) for solo developer
  - Or in parallel for team
- **Phase 10 (Polish)**: Depends on all user stories being complete

### User Story Dependencies

| Story | Priority | Can Start After | Dependencies on Other Stories |
|-------|----------|-----------------|-------------------------------|
| US1 (View List) | P1 | Phase 2 | None |
| US2 (Create) | P1 | Phase 2 | None (US1 integration in same phase) |
| US3 (View Detail) | P2 | Phase 2 | Uses UnitCard from US1 |
| US4 (Edit) | P2 | Phase 2 | Uses UnitForm from US2, UnitDetailPage from US3 |
| US5 (Delete) | P3 | Phase 2 | Uses UnitDetailPage from US3 |
| US6 (Photos) | P3 | Phase 2 | Integrates with US3 (detail) and US4 (edit) |
| US7 (Equipment) | P3 | Phase 2 | Integrates with US2 (form) and US4 (edit) |

### Within Each User Story

1. Use cases before widgets
2. Widgets before pages
3. Pages before routes
4. Routes before integration
5. Error handling last

### Parallel Opportunities

**Phase 1 (3 tasks, 2 parallel)**:
- T001 (migration) → sequential first
- T002, T003 can run in parallel after T001

**Phase 2 (7 tasks, limited parallel)**:
- T004, T005 can run in parallel
- T006 must wait for T005
- T007, T008 can run in parallel after T004
- T009 depends on T007, T008
- T010 depends on T009

**User Stories (P1 can run in parallel)**:
- US1: T011, T012 can run in parallel
- US2: T018, T019 can run in parallel
- US3: T027 can run parallel with earlier US3 tasks
- US4: T036 can run parallel
- US5: T044 can run parallel
- US6: T051 can run parallel

---

## Parallel Example: Phase 2 (Foundational)

```bash
# Batch 1 - Run in parallel:
Task: "T004 - Create Unit entity in lib/domain/entities/unit.dart"
Task: "T005 - Create UnitModel in lib/data/models/unit_model.dart"

# Batch 2 - After batch 1:
Task: "T006 - Run build_runner"

# Batch 3 - Run in parallel:
Task: "T007 - Create UnitRepository interface"
Task: "T008 - Create UnitRemoteDatasource"

# Batch 4 - After batch 3:
Task: "T009 - Create UnitRepositoryImpl"

# Batch 5 - After batch 4:
Task: "T010 - Create Riverpod providers"
```

---

## Implementation Strategy

### MVP First (User Stories 1 & 2 Only)

1. Complete Phase 1: Setup (migration, exceptions, validators)
2. Complete Phase 2: Foundational (entity, model, repository, providers)
3. Complete Phase 3: User Story 1 (View Units List)
4. Complete Phase 4: User Story 2 (Create Unit)
5. **STOP and VALIDATE**: Test viewing and creating units
6. Deploy/demo if ready - **THIS IS MVP**

### Incremental Delivery

1. MVP: Setup + Foundational + US1 + US2 → Can view and create units
2. Add US3 (View Detail) → Full unit visibility
3. Add US4 (Edit) → Complete CRUD for core operations
4. Add US5 (Delete) → Full CRUD
5. Add US6 (Photos) → Enhanced unit documentation
6. Add US7 (Equipment) → Complete feature set
7. Polish phase → Production ready

### Solo Developer Recommended Order

1. Phase 1 → Phase 2 → Phase 3 → Phase 4 → **MVP Done**
2. Phase 5 → Phase 6 → Core CRUD complete
3. Phase 7 → Phase 8 → Phase 9 → Full feature set
4. Phase 10 → Production ready

---

## Summary

| Metric | Count |
|--------|-------|
| **Total Tasks** | 73 |
| **Setup Phase** | 3 |
| **Foundational Phase** | 7 |
| **User Story 1 (P1)** | 7 |
| **User Story 2 (P1)** | 9 |
| **User Story 3 (P2)** | 9 |
| **User Story 4 (P2)** | 8 |
| **User Story 5 (P3)** | 7 |
| **User Story 6 (P3)** | 9 |
| **User Story 7 (P3)** | 6 |
| **Polish Phase** | 8 |
| **Parallel Opportunities** | 16 tasks marked [P] |
| **MVP Scope** | Phases 1-4 (26 tasks) |

---

## Notes

- All French text must use proper accents (é, è, ê, etc.)
- Currency format: "150 000 FCFA" (space thousands separator)
- Date format: DD/MM/YYYY throughout
- Status colors per Constitution: 🔴 vacant, 🟢 occupied, 🟠 maintenance
- RLS policies check building ownership for gestionnaire role
- Trigger auto-updates building.total_units count
