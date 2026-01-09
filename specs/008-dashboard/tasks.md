# Tasks: Dashboard avec KPIs

**Feature**: 008-dashboard
**Branch**: `008-dashboard`
**Input**: Design documents from `/specs/008-dashboard/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Not explicitly requested - implementation tasks only.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2)
- Include exact file paths in descriptions

## User Story Mapping

| Story | Priority | Description |
|-------|----------|-------------|
| US1 | P1 | KPIs (buildings, tenants, revenue, overdue) |
| US2 | P1 | Overdue rents list (top 5) |
| US3 | P2 | Expiring leases (30 days) |
| US4 | P2 | Occupancy rate with color coding |
| US5 | P3 | Quick navigation actions |
| US6 | P3 | Bottom navigation bar |

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create dashboard module structure and shared entities

- [X] T001 Create dashboard widgets directory at lib/presentation/widgets/dashboard/
- [X] T002 [P] Create DashboardStats entity in lib/domain/entities/dashboard_stats.dart
- [X] T003 [P] Create OverdueRent entity in lib/domain/entities/overdue_rent.dart
- [X] T004 [P] Create ExpiringLease entity in lib/domain/entities/expiring_lease.dart
- [X] T005 Create DashboardRepository interface in lib/domain/repositories/dashboard_repository.dart
- [X] T006 Create DashboardException classes in lib/core/errors/dashboard_exceptions.dart

---

## Phase 2: Foundational (Data Layer)

**Purpose**: Implement data layer components that ALL user stories depend on

**CRITICAL**: No user story work can begin until this phase is complete

- [X] T007 [P] Create DashboardStatsModel (Freezed) in lib/data/models/dashboard_stats_model.dart
- [X] T008 [P] Create OverdueRentModel (Freezed) in lib/data/models/overdue_rent_model.dart
- [X] T009 [P] Create ExpiringLeaseModel (Freezed) in lib/data/models/expiring_lease_model.dart
- [X] T010 Run build_runner to generate Freezed files: flutter pub run build_runner build --delete-conflicting-outputs
- [X] T011 Create DashboardRemoteDatasource in lib/data/datasources/dashboard_remote_datasource.dart
- [X] T012 Implement _getBuildingsCount() query in dashboard_remote_datasource.dart
- [X] T013 Implement _getActiveTenantsCount() query in dashboard_remote_datasource.dart
- [X] T014 Implement _getTotalUnitsCount() and _getOccupiedUnitsCount() queries in dashboard_remote_datasource.dart
- [X] T015 Implement _getMonthlyRevenueCollected() and _getMonthlyRevenueDue() queries in dashboard_remote_datasource.dart
- [X] T016 Implement _getOverdueCount() and _getOverdueAmount() queries in dashboard_remote_datasource.dart
- [X] T017 Implement getDashboardStats() using Future.wait() for parallel execution in dashboard_remote_datasource.dart
- [X] T018 Create DashboardRepositoryImpl in lib/data/repositories/dashboard_repository_impl.dart
- [X] T019 Create dashboard_provider.dart with datasource, repository, and stats providers in lib/presentation/providers/dashboard_provider.dart

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - KPIs Display (Priority: P1)

**Goal**: Display 4 KPI cards showing buildings count, active tenants, monthly revenue (FCFA), and overdue count

**Independent Test**: Login and verify 4 KPI cards display real data from database with proper FCFA formatting

### Implementation for User Story 1

- [X] T020 [P] [US1] Create KpiCard widget in lib/presentation/widgets/dashboard/kpi_card.dart
- [X] T021 [P] [US1] Create KpiGridSection widget to display 4 cards in lib/presentation/widgets/dashboard/kpi_grid_section.dart
- [X] T022 [US1] Implement KPI section in dashboard_page.dart using dashboardStatsProvider in lib/presentation/pages/home/dashboard_page.dart
- [X] T023 [US1] Add loading state with shimmer placeholders for KPI cards in dashboard_page.dart
- [X] T024 [US1] Add error state with retry button for KPI section in dashboard_page.dart
- [X] T025 [US1] Add empty state message "Commencez par ajouter des immeubles" when portfolio is empty in dashboard_page.dart
- [X] T026 [US1] Implement pull-to-refresh with ref.invalidate() for dashboardStatsProvider in dashboard_page.dart
- [X] T027 [US1] Add FCFA currency formatting using intl package for revenue KPI in kpi_card.dart

**Checkpoint**: User Story 1 complete - 4 KPI cards functional with real data

---

## Phase 4: User Story 2 - Overdue Rents List (Priority: P1)

**Goal**: Display top 5 overdue rent schedules with tenant name, unit reference, amount due, and days overdue

**Independent Test**: Create overdue rent schedules and verify they appear in "Impayés" section sorted by oldest first

### Implementation for User Story 2

- [X] T028 [US2] Add getOverdueRents() query to dashboard_remote_datasource.dart with JOIN to leases, tenants, units, buildings
- [X] T029 [US2] Add getTotalOverdueCount() query to dashboard_remote_datasource.dart
- [X] T030 [US2] Add getOverdueRents() and getTotalOverdueCount() to DashboardRepositoryImpl in dashboard_repository_impl.dart
- [X] T031 [US2] Add overdueRentsProvider FutureProvider to dashboard_provider.dart
- [X] T032 [P] [US2] Create OverdueRentCard widget in lib/presentation/widgets/dashboard/overdue_rent_card.dart
- [X] T033 [P] [US2] Create OverdueRentsSection widget in lib/presentation/widgets/dashboard/overdue_rents_section.dart
- [X] T034 [US2] Add "Impayés" section to dashboard_page.dart using overdueRentsProvider
- [X] T035 [US2] Add empty state "Aucun impayé - Félicitations !" with check icon when no overdue
- [X] T036 [US2] Add navigation to lease detail page on overdue item tap using context.push('/leases/${leaseId}')
- [X] T037 [US2] Add "Voir tous les impayés (X)" link when count > 5 navigating to /payments filtered

**Checkpoint**: User Story 2 complete - Overdue section displays top 5 with navigation

---

## Phase 5: User Story 3 - Expiring Leases (Priority: P2)

**Goal**: Display leases expiring within 30 days with tenant name, unit reference, end date, and days remaining

**Independent Test**: Create leases with end_date within 30 days and verify they appear in "Baux à renouveler" section

### Implementation for User Story 3

- [X] T038 [US3] Add getExpiringLeases() query to dashboard_remote_datasource.dart with JOIN to tenants, units, buildings
- [X] T039 [US3] Add getExpiringLeases() to DashboardRepositoryImpl in dashboard_repository_impl.dart
- [X] T040 [US3] Add expiringLeasesProvider FutureProvider to dashboard_provider.dart
- [X] T041 [P] [US3] Create ExpiringLeaseCard widget in lib/presentation/widgets/dashboard/expiring_lease_card.dart
- [X] T042 [P] [US3] Create ExpiringLeasesSection widget in lib/presentation/widgets/dashboard/expiring_leases_section.dart
- [X] T043 [US3] Add "Baux à renouveler" section to dashboard_page.dart using expiringLeasesProvider
- [X] T044 [US3] Add empty state "Aucun bail à renouveler prochainement" when no expiring leases
- [X] T045 [US3] Add navigation to lease detail page on expiring lease tap using context.push('/leases/${leaseId}')
- [X] T046 [US3] Add urgency styling (red text) for leases expiring within 7 days in expiring_lease_card.dart

**Checkpoint**: User Story 3 complete - Expiring leases section displays with navigation

---

## Phase 6: User Story 4 - Occupancy Rate (Priority: P2)

**Goal**: Display occupancy rate as percentage with color coding (green >85%, orange 70-85%, red <70%)

**Independent Test**: Create units with different statuses and verify occupancy rate percentage is correct with proper color

### Implementation for User Story 4

- [X] T047 [US4] Verify occupancyRate computed property works in DashboardStats entity in dashboard_stats.dart
- [X] T048 [P] [US4] Create OccupancyRateWidget with circular progress or linear gauge in lib/presentation/widgets/dashboard/occupancy_rate_widget.dart
- [X] T049 [US4] Implement color coding logic: green (>85%), orange (70-85%), red (<70%) in occupancy_rate_widget.dart
- [X] T050 [US4] Add "Taux d'occupation" section to dashboard_page.dart displaying OccupancyRateWidget
- [X] T051 [US4] Handle edge case: display "N/A" when totalUnitsCount is 0 in occupancy_rate_widget.dart

**Checkpoint**: User Story 4 complete - Occupancy rate displays with color coding

---

## Phase 7: User Story 5 - Quick Navigation Actions (Priority: P3)

**Goal**: Provide quick action buttons to navigate to modules (Immeubles, Locataires, Baux, Paiements) with RBAC

**Independent Test**: Click each quick action button and verify navigation to correct page; verify admin sees user management

### Implementation for User Story 5

- [X] T052 [P] [US5] Create QuickActionCard widget in lib/presentation/widgets/dashboard/quick_action_card.dart
- [X] T053 [P] [US5] Create QuickActionsSection widget in lib/presentation/widgets/dashboard/quick_actions_section.dart
- [X] T054 [US5] Implement quick actions: Voir les immeubles, Voir les locataires, Voir les baux, Paiements in quick_actions_section.dart
- [X] T055 [US5] Add RBAC filtering: show "Ajouter un immeuble" only for gestionnaire/admin roles in quick_actions_section.dart
- [X] T056 [US5] Add RBAC filtering: show "Gérer les utilisateurs" only for admin role in quick_actions_section.dart
- [X] T057 [US5] Add "Quick Actions" section to dashboard_page.dart (can reuse existing _buildQuickActions or replace)

**Checkpoint**: User Story 5 complete - Quick actions display with proper RBAC filtering

---

## Phase 8: User Story 6 - Bottom Navigation Bar (Priority: P3)

**Goal**: Implement persistent bottom navigation bar with 4 tabs: Accueil, Immeubles, Locataires, Paiements

**Independent Test**: Navigate between tabs and verify correct page displays with correct tab highlighted

### Implementation for User Story 6

- [X] T058 [US6] Create MainNavigationShell widget with NavigationBar in lib/presentation/widgets/dashboard/main_navigation_shell.dart
- [X] T059 [US6] Implement _getSelectedIndex() to determine active tab from current route in main_navigation_shell.dart
- [X] T060 [US6] Implement _navigateTo() to navigate using context.go() in main_navigation_shell.dart
- [X] T061 [US6] Configure 4 NavigationDestinations: Accueil, Immeubles, Locataires, Paiements with French labels
- [X] T062 [US6] Update app_router.dart: Wrap main routes in ShellRoute using MainNavigationShell
- [X] T063 [US6] Configure ShellRoute to include /dashboard, /buildings, /tenants, /payments routes
- [X] T064 [US6] Keep detail routes (/:id, /edit) outside ShellRoute to hide bottom nav on detail pages
- [X] T065 [US6] Test tab highlighting: verify correct tab is highlighted when navigating directly via URL

**Checkpoint**: User Story 6 complete - Bottom navigation works across all main screens

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Final improvements affecting multiple user stories

- [X] T066 Verify all French labels are correctly displayed (Immeubles, Locataires, Impayés, etc.)
- [X] T067 Verify FCFA formatting with space separator (e.g., "150 000 FCFA") across all amounts
- [X] T068 Verify DD/MM/YYYY date format for all displayed dates
- [X] T069 Test performance: verify dashboard loads in <2 seconds with parallel queries
- [X] T070 Add welcome message with user name at top of dashboard (existing feature - verify works)
- [X] T071 Test empty state: verify dashboard displays correctly with no data
- [X] T072 Test error handling: verify error messages display in French with retry option
- [X] T073 Run flutter analyze and fix any issues
- [X] T074 Manual test: complete user flow - login, view dashboard, navigate to each section

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-8)**: All depend on Foundational phase completion
- **Polish (Phase 9)**: Depends on all user stories being complete

### User Story Dependencies

| Story | Depends On | Notes |
|-------|------------|-------|
| US1 (KPIs) | Phase 2 | Core dashboard functionality |
| US2 (Overdue) | Phase 2 | Independent of US1 for display |
| US3 (Expiring) | Phase 2 | Independent of US1, US2 |
| US4 (Occupancy) | Phase 2, partial US1 | Uses DashboardStats entity |
| US5 (Quick Nav) | Phase 2 | Independent, uses existing routes |
| US6 (Bottom Nav) | Phase 2 | Modifies app_router.dart |

### Within Each User Story

1. Data layer tasks first (queries, repository methods, providers)
2. Widgets can be created in parallel [P]
3. Page integration last
4. Story complete before moving to next priority

### Parallel Opportunities

**Phase 1 (Setup)**:
```
T002, T003, T004 can run in parallel (different entity files)
```

**Phase 2 (Foundational)**:
```
T007, T008, T009 can run in parallel (different model files)
T012, T013, T014, T015, T016 can run in parallel (different query methods)
```

**User Stories (after Phase 2)**:
```
US1, US2, US3, US4, US5, US6 can start in parallel (different files)
Within each story, widgets marked [P] can be created in parallel
```

---

## Parallel Example: Phase 2

```bash
# Launch all Freezed model files together:
Task: "Create DashboardStatsModel (Freezed) in lib/data/models/dashboard_stats_model.dart"
Task: "Create OverdueRentModel (Freezed) in lib/data/models/overdue_rent_model.dart"
Task: "Create ExpiringLeaseModel (Freezed) in lib/data/models/expiring_lease_model.dart"

# Then run build_runner once for all:
flutter pub run build_runner build --delete-conflicting-outputs
```

## Parallel Example: User Story 1 Widgets

```bash
# Launch widget creation in parallel:
Task: "Create KpiCard widget in lib/presentation/widgets/dashboard/kpi_card.dart"
Task: "Create KpiGridSection widget in lib/presentation/widgets/dashboard/kpi_grid_section.dart"
```

---

## Implementation Strategy

### MVP First (User Stories 1 + 2 Only)

1. Complete Phase 1: Setup (T001-T006)
2. Complete Phase 2: Foundational (T007-T019)
3. Complete Phase 3: User Story 1 - KPIs (T020-T027)
4. Complete Phase 4: User Story 2 - Overdue (T028-T037)
5. **STOP and VALIDATE**: Test KPIs and Overdue section independently
6. Deploy/demo if ready - this is a functional MVP!

### Incremental Delivery

1. MVP (US1 + US2) → KPIs + Overdue list working
2. Add US3 (Expiring) → Complete alerts section
3. Add US4 (Occupancy) → Visual performance indicator
4. Add US5 + US6 (Navigation) → Complete UX polish

### Single Developer Strategy

Execute in priority order: Setup → Foundational → US1 → US2 → US3 → US4 → US5 → US6 → Polish

### Parallel Team Strategy

With 3 developers after Foundational:
- Developer A: US1 (KPIs) + US4 (Occupancy)
- Developer B: US2 (Overdue) + US3 (Expiring)
- Developer C: US5 (Quick Nav) + US6 (Bottom Nav)

---

## Summary

| Phase | Tasks | Parallelizable |
|-------|-------|----------------|
| Setup | 6 | 3 |
| Foundational | 13 | 8 |
| US1 (KPIs) | 8 | 2 |
| US2 (Overdue) | 10 | 2 |
| US3 (Expiring) | 9 | 2 |
| US4 (Occupancy) | 5 | 1 |
| US5 (Quick Nav) | 6 | 2 |
| US6 (Bottom Nav) | 8 | 0 |
| Polish | 9 | 0 |
| **Total** | **74** | **20** |

**MVP Scope**: Phases 1-4 (US1 + US2) = 37 tasks
**Full Feature**: All 74 tasks
