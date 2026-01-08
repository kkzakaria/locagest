# Tasks: Module Baux (Lease Management)

**Input**: Design documents from `/specs/005-lease-management/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅

**Tests**: Not explicitly requested - test tasks not included.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## User Story Mapping

| Story | Priority | Title | Spec Reference |
|-------|----------|-------|----------------|
| US1 | P1 | Create a New Lease | User Story 1 |
| US2 | P1 | View Lease Details | User Story 2 |
| US3 | P2 | Edit Lease Information | User Story 3 |
| US4 | P2 | Terminate a Lease | User Story 4 |
| US5 | P2 | List and Filter Leases | User Story 5 |
| US6 | P1 | Automatic Rent Schedule Generation | User Story 6 |

**Note**: US6 (Rent Schedule Generation) is implemented as part of US1 (Create Lease) since schedules are generated at lease creation time.

---

## Phase 1: Setup (Database & Project Structure)

**Purpose**: Database schema and project scaffolding

- [x] T001 Create database migration file in supabase/migrations/005_leases.sql with leases and rent_schedules tables, enums, constraints, indexes, and RLS policies per data-model.md
- [x] T002 [P] Create lease exceptions file in lib/core/errors/lease_exceptions.dart with LeaseNotFoundException, LeaseUnitOccupiedException, LeaseValidationException, LeaseUnauthorizedException, LeaseCannotBeTerminatedException
- [x] T003 [P] Create directory structure: lib/presentation/pages/leases/, lib/presentation/widgets/leases/
- [ ] T004 Apply database migration to Supabase (via dashboard or CLI)

---

## Phase 2: Foundational (Domain & Data Layer Models)

**Purpose**: Core entities, models, and repository interface that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T005 [P] Create Lease entity in lib/domain/entities/lease.dart with LeaseStatus enum, all fields, computed properties (totalMonthlyAmount, statusLabel, statusColor, canBeTerminated, isActive, isPending, durationLabel)
- [ ] T006 [P] Create RentSchedule entity in lib/domain/entities/rent_schedule.dart with RentScheduleStatus enum, all fields, computed properties (isPaid, isOverdue, remainingBalance, periodLabel, statusLabel, statusColor, amountDueFormatted, amountPaidFormatted)
- [ ] T007 [P] Create LeaseModel with Freezed in lib/data/models/lease_model.dart including CreateLeaseInput and UpdateLeaseInput classes with toJson, fromJson, toEntity, toUpdateMap methods
- [ ] T008 [P] Create RentScheduleModel with Freezed in lib/data/models/rent_schedule_model.dart with toJson, fromJson, toEntity methods
- [ ] T009 Run build_runner to generate Freezed code: flutter pub run build_runner build --delete-conflicting-outputs
- [ ] T010 Create LeaseRepository interface in lib/domain/repositories/lease_repository.dart with all method signatures per contracts/lease-repository.md
- [ ] T011 Create LeaseRemoteDatasource in lib/data/datasources/lease_remote_datasource.dart with Supabase CRUD operations, error handling, and PostgreSQL error code mapping
- [ ] T012 Create LeaseRepositoryImpl in lib/data/repositories/lease_repository_impl.dart implementing LeaseRepository interface, delegating to datasource

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 + US6 - Create a New Lease with Rent Schedule Generation (Priority: P1) 🎯 MVP

**Goal**: Property manager can create a lease contract linking a tenant to a unit, with automatic rent schedule generation

**Independent Test**: Create a lease for existing tenant and vacant unit, verify unit status changes to "occupied", verify rent schedules are generated

### Implementation for User Story 1 + US6

- [ ] T013 [US1] Implement rent schedule generation utility function in lib/data/datasources/lease_remote_datasource.dart with pro-rata calculation for partial months (30-day basis), monthly schedule generation, payment_day handling
- [ ] T014 [US1] Implement createLease method in LeaseRemoteDatasource with: validate unit not occupied, insert lease, generate rent schedules, update unit status to 'occupied'
- [ ] T015 [US1] Implement createLease in LeaseRepositoryImpl calling datasource and converting to entity
- [ ] T016 [P] [US1] Create LeaseFormFields widget in lib/presentation/widgets/leases/lease_form_fields.dart with tenant picker, unit picker, date pickers, amount fields, payment day selector
- [ ] T017 [P] [US1] Create LeaseStatusBadge widget in lib/presentation/widgets/leases/lease_status_badge.dart with colored chip for each status (pending=orange, active=green, terminated=red, expired=grey)
- [ ] T018 [US1] Create CreateLeaseState and CreateLeaseNotifier in lib/presentation/providers/leases_provider.dart with createLease method, loading/success/error states
- [ ] T019 [US1] Create createLeaseProvider, canCreateLeaseForUnitProvider, canManageLeasesProvider in lib/presentation/providers/leases_provider.dart
- [ ] T020 [US1] Create LeaseFormPage in lib/presentation/pages/leases/lease_form_page.dart with form fields, validation, submit handling, preselectedUnitId and preselectedTenantId support
- [ ] T021 [US1] Add lease routes to lib/core/router/app_router.dart: /leases/new, /units/:unitId/leases/new, /tenants/:tenantId/leases/new
- [ ] T022 [US1] Add "Créer un bail" button to unit detail page (visible only if unit is vacant and user can manage leases)

**Checkpoint**: User Story 1 + US6 complete - leases can be created with automatic rent schedules

---

## Phase 4: User Story 2 - View Lease Details (Priority: P1)

**Goal**: Property manager can view all lease details including tenant, unit, rent schedules summary

**Independent Test**: Navigate to lease detail from tenant or unit page, verify all lease information displays correctly

### Implementation for User Story 2

- [ ] T023 [US2] Implement getLeaseById with joined tenant and unit data in LeaseRemoteDatasource
- [ ] T024 [US2] Implement getLeasesForTenant and getLeasesForUnit in LeaseRemoteDatasource
- [ ] T025 [US2] Implement getActiveLeaseForUnit in LeaseRemoteDatasource returning null if no active lease
- [ ] T026 [US2] Implement getRentSchedulesForLease and getRentSchedulesSummary in LeaseRemoteDatasource
- [ ] T027 [US2] Implement corresponding methods in LeaseRepositoryImpl
- [ ] T028 [US2] Create leaseByIdProvider, leasesForTenantProvider, leasesForUnitProvider, activeLeaseForUnitProvider, rentSchedulesForLeaseProvider, rentSchedulesSummaryProvider in lib/presentation/providers/leases_provider.dart
- [ ] T029 [P] [US2] Create LeaseCard widget in lib/presentation/widgets/leases/lease_card.dart showing tenant name, unit reference, status badge, rent amount, dates
- [ ] T030 [P] [US2] Create LeaseSection widget in lib/presentation/widgets/leases/lease_section.dart for embedding in tenant/unit detail pages with active lease highlight and historical list
- [ ] T031 [US2] Create LeaseDetailPage in lib/presentation/pages/leases/lease_detail_page.dart with all lease info sections, rent schedules summary, schedules list
- [ ] T032 [US2] Add lease detail route to lib/core/router/app_router.dart: /leases/:id
- [ ] T033 [US2] Add LeaseSection to tenant detail page in lib/presentation/pages/tenants/tenant_detail_page.dart with "Nouveau bail" button
- [ ] T034 [US2] Add LeaseSection to unit detail page in lib/presentation/pages/units/unit_detail_page.dart showing active lease or historical leases

**Checkpoint**: User Story 2 complete - lease details viewable from multiple entry points

---

## Phase 5: User Story 3 - Edit Lease Information (Priority: P2)

**Goal**: Property manager can modify lease terms (rent amount, end date, charges) for active leases

**Independent Test**: Edit a lease's rent amount, verify future schedules reflect new amount

### Implementation for User Story 3

- [ ] T035 [US3] Implement updateLease in LeaseRemoteDatasource with validation (cannot change tenant/unit, only update allowed fields)
- [ ] T036 [US3] Implement generateAdditionalSchedules in LeaseRemoteDatasource for lease extension (new end_date)
- [ ] T037 [US3] Implement updateLease and generateAdditionalSchedules in LeaseRepositoryImpl
- [ ] T038 [US3] Create EditLeaseState, EditLeaseNotifier, and editLeaseProvider in lib/presentation/providers/leases_provider.dart
- [ ] T039 [US3] Create LeaseEditPage in lib/presentation/pages/leases/lease_edit_page.dart with pre-filled form, disabled tenant/unit fields, editable rent/charges/end_date/notes
- [ ] T040 [US3] Add lease edit route to lib/core/router/app_router.dart: /leases/:id/edit
- [ ] T041 [US3] Add "Modifier" button to LeaseDetailPage (visible only if user can manage leases)

**Checkpoint**: User Story 3 complete - leases can be edited

---

## Phase 6: User Story 4 - Terminate a Lease (Priority: P2)

**Goal**: Property manager can terminate a lease with confirmation, recording date and reason, updating unit status

**Independent Test**: Terminate an active lease, verify unit becomes "vacant", verify lease status is "terminated", verify future schedules are cancelled

### Implementation for User Story 4

- [ ] T042 [US4] Implement terminateLease in LeaseRemoteDatasource with: update lease status/date/reason, update unit status to 'vacant', cancel future unpaid schedules (set status to 'cancelled')
- [ ] T043 [US4] Implement terminateLease in LeaseRepositoryImpl
- [ ] T044 [US4] Create TerminateLeaseState, TerminateLeaseNotifier, and terminateLeaseProvider in lib/presentation/providers/leases_provider.dart
- [ ] T045 [US4] Create TerminationModal widget in lib/presentation/widgets/leases/termination_modal.dart with termination date picker (default today), reason dropdown (départ locataire, impayés, fin de bail, autre), notes field, confirm/cancel buttons
- [ ] T046 [US4] Add "Résilier le bail" button and termination flow to LeaseDetailPage (visible only for active/pending leases and if user can manage)

**Checkpoint**: User Story 4 complete - leases can be terminated with proper cleanup

---

## Phase 7: User Story 5 - List and Filter Leases (Priority: P2)

**Goal**: Property manager can view all leases with filtering by status and searching by tenant/unit

**Independent Test**: View leases list, filter by status, search by tenant name

### Implementation for User Story 5

- [ ] T047 [US5] Implement getLeases with pagination, status filter, and building filter in LeaseRemoteDatasource
- [ ] T048 [US5] Implement searchLeases with full-text search on tenant name and unit reference in LeaseRemoteDatasource
- [ ] T049 [US5] Implement getLeaseCountsByStatus for dashboard stats in LeaseRemoteDatasource
- [ ] T050 [US5] Implement getLeases, searchLeases, getLeaseCountsByStatus in LeaseRepositoryImpl
- [ ] T051 [US5] Create LeasesState, LeasesNotifier with loadLeases, loadMore, searchLeases, setStatusFilter, refresh methods in lib/presentation/providers/leases_provider.dart
- [ ] T052 [US5] Create leasesProvider, leaseSearchProvider, leaseCountsByStatusProvider in lib/presentation/providers/leases_provider.dart
- [ ] T053 [US5] Create LeasesListPage in lib/presentation/pages/leases/leases_list_page.dart with AppBar search, status filter chips, ListView with LeaseCard, pagination, FAB for new lease
- [ ] T054 [US5] Add leases list route to lib/core/router/app_router.dart: /leases
- [ ] T055 [US5] Add "Baux" navigation item to bottom navigation or drawer menu

**Checkpoint**: User Story 5 complete - full lease portfolio management available

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Final integration, cleanup, and validation

- [ ] T056 Add leaseDatasourceProvider and leaseRepositoryProvider dependency injection providers in lib/presentation/providers/leases_provider.dart
- [ ] T057 Add navigation extensions to BuildContext for lease routes (goToLeases, goToNewLease, goToLeaseDetail, goToEditLease, goToNewLeaseForUnit, goToNewLeaseForTenant)
- [ ] T058 Verify all French localization: labels, error messages, date formats (DD/MM/YYYY), currency format (FCFA with space separators)
- [ ] T059 Verify role-based access: assistant cannot see create/edit/terminate buttons
- [ ] T060 Verify FCFA formatting throughout: "165 000 FCFA" format with space thousand separator
- [ ] T061 Run flutter analyze and fix any linting issues
- [ ] T062 Manual validation against quickstart.md testing checklist

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on T001 (migration) and T002 (exceptions) - BLOCKS all user stories
- **User Stories (Phase 3-7)**: All depend on Phase 2 completion
  - US1+US6 (Phase 3) → can start after Phase 2
  - US2 (Phase 4) → can start after Phase 2 (or after US1 for full flow testing)
  - US3, US4, US5 (Phases 5-7) → can start after Phase 2
- **Polish (Phase 8)**: Depends on all user story phases completion

### User Story Dependencies

| Story | Can Start After | Notes |
|-------|-----------------|-------|
| US1+US6 | Phase 2 | Core MVP - create lease with schedules |
| US2 | Phase 2 | View details - independent of creation flow |
| US3 | Phase 2 | Edit lease - independent of other stories |
| US4 | Phase 2 | Terminate - independent of other stories |
| US5 | Phase 2 | List/filter - independent of other stories |

### Within Each User Story

- Repository/datasource methods before providers
- Providers before widgets
- Widgets before pages
- Core implementation before integration tasks

### Parallel Opportunities

Within Phase 1:
```
T002 (exceptions) ─┐
                   ├── All can run in parallel
T003 (directories) ┘
```

Within Phase 2:
```
T005 (Lease entity) ─────┐
T006 (RentSchedule entity)├── All can run in parallel
T007 (LeaseModel) ────────┤
T008 (RentScheduleModel) ─┘

Then T009 (build_runner) must wait for all above

T010 (repository interface) ─┐
                             ├── Can run in parallel after T009
T011 (datasource) ───────────┘

T012 (repository impl) must wait for T010 and T011
```

Within Each User Story:
```
Widgets marked [P] can run in parallel
Datasource → Repository → Providers → Pages (sequential)
```

---

## Parallel Example: Phase 2 (Foundational)

```bash
# Launch all entity/model tasks together:
Task: "Create Lease entity in lib/domain/entities/lease.dart"
Task: "Create RentSchedule entity in lib/domain/entities/rent_schedule.dart"
Task: "Create LeaseModel with Freezed in lib/data/models/lease_model.dart"
Task: "Create RentScheduleModel with Freezed in lib/data/models/rent_schedule_model.dart"

# Then run build_runner (must wait for above):
Task: "Run build_runner to generate Freezed code"

# Then launch interface and datasource together:
Task: "Create LeaseRepository interface in lib/domain/repositories/lease_repository.dart"
Task: "Create LeaseRemoteDatasource in lib/data/datasources/lease_remote_datasource.dart"

# Finally repository implementation:
Task: "Create LeaseRepositoryImpl in lib/data/repositories/lease_repository_impl.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 + US6 Only)

1. Complete Phase 1: Setup (database migration)
2. Complete Phase 2: Foundational (entities, models, repository)
3. Complete Phase 3: User Story 1 + US6 (create lease with schedules)
4. **STOP and VALIDATE**: Test lease creation with rent schedules
5. Deploy/demo if ready

### Incremental Delivery

1. Setup + Foundational → Foundation ready
2. Add US1+US6 → **MVP: Create lease with schedules**
3. Add US2 → View lease details
4. Add US5 → List and filter leases
5. Add US3 → Edit leases
6. Add US4 → Terminate leases
7. Polish phase → Final cleanup

### Recommended Order (Solo Developer)

P1 stories first (US1+US6, US2), then P2 stories (US5, US3, US4):

```
Phase 1 → Phase 2 → Phase 3 (US1+US6) → Phase 4 (US2) →
Phase 7 (US5) → Phase 5 (US3) → Phase 6 (US4) → Phase 8
```

---

## Summary

| Phase | Tasks | Stories | Description |
|-------|-------|---------|-------------|
| Phase 1 | T001-T004 | - | Database & setup |
| Phase 2 | T005-T012 | - | Foundational models & repository |
| Phase 3 | T013-T022 | US1, US6 | Create lease with schedules (MVP) |
| Phase 4 | T023-T034 | US2 | View lease details |
| Phase 5 | T035-T041 | US3 | Edit lease |
| Phase 6 | T042-T046 | US4 | Terminate lease |
| Phase 7 | T047-T055 | US5 | List and filter leases |
| Phase 8 | T056-T062 | - | Polish & validation |

**Total Tasks**: 62
**MVP Tasks**: T001-T022 (22 tasks for Phase 1-3)

---

## Notes

- [P] tasks = different files, no dependencies within same phase
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Verify French localization throughout
- Verify FCFA formatting: "165 000 FCFA"
