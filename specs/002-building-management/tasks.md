# Tasks: Building Management (Gestion des Immeubles)

**Input**: Design documents from `/specs/002-building-management/`
**Prerequisites**: plan.md, spec.md, data-model.md, contracts/building-api.md, research.md, quickstart.md

**Tests**: Not explicitly requested - test tasks not included.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

Based on plan.md, this project uses Flutter Clean Architecture:
- **Core**: `lib/core/` (constants, errors, utils)
- **Data**: `lib/data/` (models, datasources, repositories)
- **Domain**: `lib/domain/` (entities, repositories, usecases)
- **Presentation**: `lib/presentation/` (pages, providers, widgets)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and dependencies

- [x] T001 Add flutter_image_compress and cached_network_image to pubspec.yaml
- [x] T002 Run `flutter pub get` to install new dependencies
- [x] T003 [P] Create SQL migration file in supabase/migrations/002_buildings.sql with table, RLS, and storage policies per data-model.md
- [x] T004 Execute SQL migration in Supabase dashboard or via CLI (Applied via `supabase db reset`)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T005 [P] Create building exceptions in lib/core/errors/building_exceptions.dart per contracts/building-api.md
- [x] T006 [P] Add building validation rules to lib/core/utils/validators.dart per data-model.md validation rules
- [x] T007 [P] Create Building domain entity in lib/domain/entities/building.dart per data-model.md
- [x] T008 [P] Create BuildingModel with Freezed in lib/data/models/building_model.dart per data-model.md
- [x] T009 Run `flutter pub run build_runner build --delete-conflicting-outputs` to generate Freezed code
- [x] T010 Create BuildingRepository interface in lib/domain/repositories/building_repository.dart per contracts/building-api.md
- [x] T011 Create BuildingRemoteDatasource in lib/data/datasources/building_remote_datasource.dart with Supabase operations per contracts/building-api.md
- [x] T012 Create BuildingRepositoryImpl in lib/data/repositories/building_repository_impl.dart implementing repository interface

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Add New Building (Priority: P1) 🎯 MVP

**Goal**: Property managers can register new buildings in the system with name, address, city, and optional photo.

**Independent Test**: Create a building via the form and verify it appears in the buildings list. Test form validation with missing fields. Test photo upload compression.

### Implementation for User Story 1

- [x] T013 [P] [US1] Create CreateBuilding use case in lib/domain/usecases/create_building.dart
- [x] T014 [P] [US1] Create photo upload method in BuildingRemoteDatasource for image compression and Supabase Storage upload
- [x] T015 [US1] Create BuildingsProvider (AsyncNotifier) in lib/presentation/providers/buildings_provider.dart with createBuilding method
- [x] T016 [US1] Create BuildingForm widget in lib/presentation/widgets/buildings/building_form.dart with French validation messages
- [x] T017 [US1] Create BuildingFormPage in lib/presentation/pages/buildings/building_form_page.dart for create mode
- [x] T018 [US1] Add GoRouter route `/buildings/new` in lib/core/router/app_router.dart

**Checkpoint**: At this point, users can create buildings. Move to User Story 2 for list view to see created buildings.

---

## Phase 4: User Story 2 - View Buildings List (Priority: P1) 🎯 MVP

**Goal**: Property managers can see all their buildings with name, address, city, and unit count. Empty state encourages adding first building.

**Independent Test**: Navigate to buildings list and verify all buildings display. Test empty state message. Test pagination with 20+ buildings.

### Implementation for User Story 2

- [x] T019 [P] [US2] Create GetBuildings use case in lib/domain/usecases/get_buildings.dart with pagination support
- [x] T020 [US2] Add getBuildings method to BuildingsProvider with pagination and loading states
- [x] T021 [US2] Create BuildingCard widget in lib/presentation/widgets/buildings/building_card.dart showing name, address, city, unit count, and thumbnail
- [x] T022 [US2] Create BuildingsListPage in lib/presentation/pages/buildings/buildings_list_page.dart with empty state, FAB for create, and lazy loading
- [x] T023 [US2] Add GoRouter route `/buildings` in lib/core/router/app_router.dart
- [x] T024 [US2] Add "Immeubles" tab to bottom navigation in lib/presentation/pages/home/dashboard_page.dart

**Checkpoint**: At this point, User Stories 1 AND 2 are complete. Users can create buildings and see them in a list. This is MVP!

---

## Phase 5: User Story 3 - View Building Details (Priority: P2)

**Goal**: Property managers can view complete building information including photo, full address, notes, timestamps, and unit summary.

**Independent Test**: Tap a building from list and verify all fields display correctly including photo and timestamps.

### Implementation for User Story 3

- [x] T025 [P] [US3] Create GetBuildingById use case in lib/domain/usecases/get_building_by_id.dart
- [x] T026 [US3] Add getBuildingById method to BuildingsProvider
- [x] T027 [US3] Create BuildingDetailPage in lib/presentation/pages/buildings/building_detail_page.dart with full info display, edit/delete buttons (based on role), and "Voir les lots" link
- [x] T028 [US3] Add GoRouter route `/buildings/:id` in lib/core/router/app_router.dart

**Checkpoint**: Users can now create, list, and view building details.

---

## Phase 6: User Story 4 - Edit Building Information (Priority: P2)

**Goal**: Property managers can update building information including replacing photos.

**Independent Test**: Edit a building's name and verify the change persists. Test photo replacement. Test validation on edit.

### Implementation for User Story 4

- [x] T029 [P] [US4] Create UpdateBuilding use case in lib/domain/usecases/update_building.dart
- [x] T030 [US4] Add updateBuilding method to BuildingsProvider with optimistic UI update
- [x] T031 [US4] Extend BuildingFormPage to support edit mode with pre-populated fields in lib/presentation/pages/buildings/building_form_page.dart
- [x] T032 [US4] Add GoRouter route `/buildings/:id/edit` in lib/core/router/app_router.dart
- [x] T033 [US4] Add edit button to BuildingDetailPage with role check (hide for assistant)

**Checkpoint**: Users can now create, list, view, and edit buildings.

---

## Phase 7: User Story 5 - Delete Building (Priority: P3)

**Goal**: Property managers can delete buildings they no longer manage. Deletion is prevented if building has units.

**Independent Test**: Delete a building without units and verify it disappears. Test that buildings with units cannot be deleted. Test confirmation dialog cancel.

### Implementation for User Story 5

- [x] T034 [P] [US5] Create DeleteBuilding use case in lib/domain/usecases/delete_building.dart with unit count check
- [x] T035 [US5] Add deleteBuilding method to BuildingsProvider with confirmation handling
- [x] T036 [US5] Create delete confirmation dialog in BuildingDetailPage with French text ("Supprimer cet immeuble ?", "Annuler", "Supprimer")
- [x] T037 [US5] Add delete button to BuildingDetailPage with role check (hide for assistant) and disabled state for buildings with units

**Checkpoint**: All CRUD operations complete. Full building management functionality available.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [x] T038 [P] Add role-based UI guards to hide create/edit/delete for assistant role across all building pages
- [x] T039 [P] Implement error handling with French messages for network failures across all building operations
- [x] T040 Add loading indicators (shimmer/skeleton) to BuildingsListPage and BuildingDetailPage
- [x] T041 [P] Add date formatting helper for DD/MM/YYYY display in lib/core/utils/formatters.dart
- [x] T042 Verify all French labels and messages per constitution (review all building UI text)
- [x] T043 Run `flutter analyze` and fix any issues
- [x] T044 Run quickstart.md verification checklist (Tested with Playwright: create, list, detail, edit, delete - all working)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - US1 + US2 together form MVP
  - US3, US4, US5 can proceed after MVP
- **Polish (Phase 8)**: Depends on all user stories being complete

### User Story Dependencies

| Story | Depends On | Can Parallelize After |
|-------|------------|----------------------|
| US1 (Add Building) | Foundational (Phase 2) | Phase 2 complete |
| US2 (View List) | Foundational (Phase 2) | Phase 2 complete |
| US3 (View Details) | US1 + US2 (needs buildings to exist) | US1 + US2 complete |
| US4 (Edit Building) | US3 (needs detail page) | US3 complete |
| US5 (Delete Building) | US3 (needs detail page) | US3 complete |

### Within Each User Story

- Use cases before provider methods
- Provider methods before widgets
- Widgets before pages
- Pages before routes

### Parallel Opportunities

**Phase 1 (Setup)**:
```
T001 (pubspec.yaml) → T002 (pub get)
T003 (SQL file) [P]
T004 (execute SQL) - after T003
```

**Phase 2 (Foundational)**:
```
T005, T006, T007, T008 - all [P], can run simultaneously
T009 (build_runner) - after T008
T010 (repository interface) [P]
T011 (datasource) - can start with T010
T012 (repository impl) - after T010, T011
```

**Phase 3-4 (MVP - US1 + US2)**:
```
T013, T014, T019 - all [P], can run simultaneously
Then: T015-T018 (US1) and T020-T024 (US2) can run in parallel tracks
```

**Phase 5-7 (US3, US4, US5)**:
```
US3 first (detail page needed by US4 and US5)
Then US4 and US5 can run in parallel
```

---

## Parallel Example: Phase 2 Foundational

```bash
# Launch all foundational components together:
Task: "Create building exceptions in lib/core/errors/building_exceptions.dart"
Task: "Add building validation rules to lib/core/utils/validators.dart"
Task: "Create Building domain entity in lib/domain/entities/building.dart"
Task: "Create BuildingModel with Freezed in lib/data/models/building_model.dart"

# Then after Freezed model is done:
Task: "Run flutter pub run build_runner build"

# Then repository layer:
Task: "Create BuildingRepository interface"
Task: "Create BuildingRemoteDatasource"
# Finally:
Task: "Create BuildingRepositoryImpl"
```

---

## Implementation Strategy

### MVP First (User Stories 1 + 2)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1 (Add Building)
4. Complete Phase 4: User Story 2 (View List)
5. **STOP and VALIDATE**: Test creating and viewing buildings
6. Deploy/demo MVP

### Incremental Delivery

| Milestone | Phases | Delivers |
|-----------|--------|----------|
| MVP | 1 + 2 + 3 + 4 | Create buildings, view list |
| Details | + 5 | View full building info |
| Edit | + 6 | Modify building data |
| Delete | + 7 | Remove buildings |
| Production | + 8 | Polish, error handling, accessibility |

### Single Developer Strategy

1. Phases 1-2: Setup and Foundational (sequential)
2. Phases 3-4: US1 + US2 together (MVP)
3. Phase 5: US3 (building details)
4. Phases 6-7: US4 + US5 (can interleave)
5. Phase 8: Polish

---

## Task Summary

| Phase | Task Count | Parallel Opportunities |
|-------|------------|----------------------|
| Phase 1: Setup | 4 | 1 (T003) |
| Phase 2: Foundational | 8 | 5 (T005-T008, T010) |
| Phase 3: US1 Add Building | 6 | 2 (T013, T014) |
| Phase 4: US2 View List | 6 | 1 (T019) |
| Phase 5: US3 View Details | 4 | 1 (T025) |
| Phase 6: US4 Edit Building | 5 | 1 (T029) |
| Phase 7: US5 Delete Building | 4 | 1 (T034) |
| Phase 8: Polish | 7 | 3 (T038, T039, T041) |
| **TOTAL** | **44** | **15** |

---

## Notes

- [P] tasks = different files, no dependencies on incomplete tasks
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- All UI text must be in French per constitution
- Role checks: assistant = read-only, gestionnaire/admin = full CRUD
