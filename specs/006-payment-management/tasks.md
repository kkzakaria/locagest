# Tasks: Module Echeances et Paiements

**Input**: Design documents from `/specs/006-payment-management/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Not explicitly requested in specification. Basic validation will be included as part of implementation.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Flutter/Dart**: `lib/` with Clean Architecture (domain/data/presentation layers)
- **Database**: `supabase/migrations/` for SQL files
- Paths follow existing LocaGest structure per plan.md

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Database migration and core project structure

- [x] T001 Copy migration file from specs/006-payment-management/contracts/006_payments.sql to supabase/migrations/006_payments.sql
- [x] T002 Apply database migration via Supabase dashboard or CLI (verify payments table, triggers, RLS policies created)
- [x] T003 [P] Create payments directory structure in lib/presentation/pages/payments/ and lib/presentation/widgets/payments/

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core Payment entity and repository infrastructure that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 Create Payment entity with PaymentMethod enum in lib/domain/entities/payment.dart (include amountFormatted, methodLabel computed properties)
- [x] T005 Create PaymentRepository interface in lib/domain/repositories/payment_repository.dart (define all CRUD and query methods from contracts)
- [x] T006 [P] Create PaymentModel with Freezed in lib/data/models/payment_model.dart (map all DB columns, include toEntity method)
- [x] T007 Run build_runner to generate payment_model.freezed.dart and payment_model.g.dart files
- [x] T008 Create PaymentRemoteDatasource in lib/data/datasources/payment_remote_datasource.dart (Supabase CRUD operations)
- [x] T009 Create PaymentRepositoryImpl in lib/data/repositories/payment_repository_impl.dart (implement all interface methods)
- [x] T010 Create core Riverpod providers in lib/presentation/providers/payments_provider.dart (paymentRepositoryProvider, paymentDatasourceProvider)
- [x] T011 [P] Create PaymentStatusBadge widget in lib/presentation/widgets/payments/payment_status_badge.dart (reuse existing status color scheme)

**Checkpoint**: Foundation ready - Payment entity, repository, and providers exist. User story implementation can now begin.

---

## Phase 3: User Story 1 - Enregistrer un paiement de loyer (Priority: P1) 🎯 MVP

**Goal**: Enable property managers to record rent payments with method, date, and amount, automatically updating schedule status

**Independent Test**: Create a payment for an existing schedule, verify schedule.amount_paid and schedule.status are updated correctly

### Implementation for User Story 1

- [x] T012 [US1] Add createPayment method implementation in lib/data/datasources/payment_remote_datasource.dart
- [x] T013 [US1] Add CreatePaymentNotifier and createPaymentProvider in lib/presentation/providers/payments_provider.dart
- [x] T014 [US1] Create PaymentFormModal widget in lib/presentation/pages/payments/payment_form_modal.dart (bottom sheet with amount, method, date fields)
- [x] T015 [US1] Add conditional check fields (check_number, bank_name) to PaymentFormModal when payment_method = 'check'
- [x] T016 [US1] Add conditional reference field to PaymentFormModal when payment_method = 'transfer' or 'mobile_money'
- [x] T017 [US1] Add validation logic to PaymentFormModal (amount > 0, required fields, overpayment warning)
- [x] T018 [US1] Integrate PaymentFormModal into existing lease_detail_page.dart (replace inline modal with reusable component)
- [x] T019 [US1] Add French error messages and labels to PaymentFormModal (Montant, Methode de paiement, Date de paiement, etc.)
- [x] T020 [US1] Add success feedback after payment creation (SnackBar with receipt number)

**Checkpoint**: User Story 1 complete - Payments can be recorded from lease detail page, schedules auto-update via DB trigger

---

## Phase 4: User Story 2 - Consulter l'historique des paiements d'une echeance (Priority: P1)

**Goal**: Display payment history for a rent schedule, showing all partial payments with details

**Independent Test**: View a schedule with 2+ payments, verify all payments display with date, amount, method, reference

### Implementation for User Story 2

- [x] T021 [US2] Add getPaymentsForSchedule method implementation in lib/data/datasources/payment_remote_datasource.dart
- [x] T022 [US2] Add paymentsForScheduleProvider in lib/presentation/providers/payments_provider.dart (FutureProvider.family)
- [x] T023 [US2] Create PaymentHistoryList widget in lib/presentation/widgets/payments/payment_history_list.dart
- [x] T024 [US2] Add payment detail display in PaymentHistoryList (date, amount, method, reference, receipt number)
- [x] T025 [US2] Add check-specific fields display in PaymentHistoryList (check_number, bank_name when method = check)
- [x] T026 [US2] Add empty state message in PaymentHistoryList ("Aucun paiement enregistre")
- [x] T027 [US2] Integrate PaymentHistoryList into lease_detail_page.dart (show below schedule list or in expandable section)

**Checkpoint**: User Story 2 complete - Payment history visible in lease detail page

---

## Phase 5: User Story 3 - Consulter la page globale des paiements (Priority: P2)

**Goal**: Centralized page listing all rent schedules with filtering by status, period, and tenant

**Independent Test**: Navigate to /payments, verify all schedules display with filters functional

### Implementation for User Story 3

- [x] T028 [US3] Add getAllSchedules method with filters in lib/data/datasources/payment_remote_datasource.dart
- [x] T029 [US3] Add schedules list provider with filters in lib/presentation/providers/payments_provider.dart (AllSchedulesNotifier)
- [x] T030 [US3] Create RentScheduleCard widget in lib/presentation/widgets/payments/rent_schedule_card.dart (status badge, amount, tenant name, due date)
- [x] T031 [US3] Create PaymentsPage scaffold in lib/presentation/pages/payments/payments_page.dart
- [x] T032 [US3] Add summary cards to PaymentsPage (total du, total impayes, total collecte ce mois)
- [x] T033 [US3] Add status filter dropdown to PaymentsPage (Tous, En attente, Paye, Partiel, En retard)
- [x] T034 [US3] Add period filter to PaymentsPage (month/year picker)
- [x] T035 [US3] Add tenant search field to PaymentsPage
- [x] T036 [US3] Add RentScheduleCard list with pagination in PaymentsPage
- [x] T037 [US3] Add navigation from RentScheduleCard to lease detail page
- [x] T038 [US3] Add /payments route in lib/core/router/app_router.dart
- [x] T039 [US3] Add "Enregistrer paiement" FAB in PaymentsPage (opens PaymentFormModal for selected schedule)
- [x] T040 [US3] Add navigation link to payments page from dashboard in lib/presentation/pages/home/dashboard_page.dart

**Checkpoint**: User Story 3 complete - Centralized payments page accessible from dashboard

---

## Phase 6: User Story 4 - Visualiser les impayes (Priority: P2)

**Goal**: Quickly identify overdue schedules with days overdue calculation

**Independent Test**: Create overdue schedules, verify they appear in overdue list sorted by age, with days overdue displayed

### Implementation for User Story 4

- [x] T041 [US4] Add getOverdueSchedules method in lib/data/datasources/payment_remote_datasource.dart
- [x] T042 [US4] Add overdueSchedulesProvider in lib/presentation/providers/payments_provider.dart
- [x] T043 [US4] Add daysOverdue computed property to RentSchedule entity in lib/domain/entities/rent_schedule.dart
- [x] T044 [US4] Add overdue filter tab/section in PaymentsPage (quick access to overdue only)
- [x] T045 [US4] Display days overdue badge in RentScheduleCard when schedule is overdue
- [x] T046 [US4] Sort overdue schedules by due_date ASC (oldest first) in overdue view
- [x] T047 [US4] Add visual styling for overdue items in RentScheduleCard (red accent, warning icon)

**Checkpoint**: User Story 4 complete - Overdue schedules easily identifiable and actionable

---

## Phase 7: User Story 5 - Modifier un paiement (Priority: P3)

**Goal**: Edit or delete payments to correct data entry errors

**Independent Test**: Modify payment amount, verify schedule recalculates. Delete payment, verify schedule status updates.

### Implementation for User Story 5

- [x] T048 [US5] Add updatePayment method in lib/data/datasources/payment_remote_datasource.dart
- [x] T049 [US5] Add deletePayment method in lib/data/datasources/payment_remote_datasource.dart
- [x] T050 [US5] Add UpdatePaymentNotifier and DeletePaymentNotifier in lib/presentation/providers/payments_provider.dart
- [x] T051 [US5] Add canManagePayments permission check in lib/presentation/providers/payments_provider.dart
- [x] T052 [US5] Create PaymentEditModal in lib/presentation/pages/payments/payment_edit_modal.dart (prefilled with existing values)
- [x] T053 [US5] Add edit button to PaymentHistoryList items (visible to admin/gestionnaire only)
- [x] T054 [US5] Add delete button with confirmation dialog to PaymentHistoryList items
- [x] T055 [US5] Add RBAC check - hide edit/delete for assistant role
- [x] T056 [US5] Add French confirmation messages ("Voulez-vous vraiment supprimer ce paiement?")

**Checkpoint**: User Story 5 complete - Payments can be edited/deleted with proper authorization

---

## Phase 8: User Story 6 - Historique des paiements dans la fiche locataire (Priority: P3)

**Goal**: Display payment summary and history in tenant detail page

**Independent Test**: View tenant with payments, verify summary metrics and recent payments list display

### Implementation for User Story 6

- [x] T057 [US6] Add getTenantPaymentSummary method in lib/data/datasources/payment_remote_datasource.dart
- [x] T058 [US6] Add getPaymentsForTenant method in lib/data/datasources/payment_remote_datasource.dart
- [x] T059 [US6] Create TenantPaymentSummary entity in lib/domain/entities/tenant_payment_summary.dart
- [x] T060 [US6] Add tenantPaymentSummaryProvider in lib/presentation/providers/payments_provider.dart (FutureProvider.family)
- [x] T061 [US6] Create TenantPaymentsSummaryCard widget in lib/presentation/widgets/payments/tenant_payments_summary_card.dart
- [x] T062 [US6] Add summary section to tenant_detail_page.dart (total paye, echeances en cours, impayes)
- [x] T063 [US6] Add recent payments list to tenant_detail_page.dart (last 10 payments)
- [x] T064 [US6] Add "Voir tous les paiements" link in tenant detail that navigates to filtered payments page

**Checkpoint**: User Story 6 complete - Tenant payment history visible in tenant profile

---

## Phase 9: Polish & Cross-Cutting Concerns ✅ TERMINÉE

**Purpose**: Final improvements across all user stories

- [x] T065 [P] Add loading states to all async operations (shimmer or CircularProgressIndicator)
- [x] T066 [P] Add error handling with French error messages across all payment operations
- [x] T067 [P] Verify FCFA formatting consistency (XXX XXX FCFA) in all amount displays
- [x] T068 [P] Verify DD/MM/YYYY date formatting in all date displays
- [x] T069 [P] Run flutter analyze and fix any linting issues
- [x] T070 Verify mobile-first UX: touch targets >= 48dp, forms usable on small screens
- [x] T071 Manual E2E test: full payment recording flow from lease detail
- [x] T072 Manual E2E test: payments page filters and navigation
- [x] T073 Update PLAN-DEV-LocaGest.md to mark Phase 8 as complete

**Checkpoint**: All polish tasks complete - Module ready for production

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-8)**: All depend on Foundational phase completion
- **Polish (Phase 9)**: Depends on all desired user stories being complete

### User Story Dependencies

| Story | Priority | Can Start After | Dependencies on Other Stories |
|-------|----------|-----------------|-------------------------------|
| US1 | P1 | Phase 2 | None - core MVP |
| US2 | P1 | Phase 2 | Uses PaymentHistoryList in same context as US1, but independently testable |
| US3 | P2 | Phase 2 | Uses RentScheduleCard, can integrate US1/US2 components |
| US4 | P2 | Phase 2 | Extends US3 with overdue filter, shares RentScheduleCard |
| US5 | P3 | Phase 2 | Requires Payment entity from Phase 2, PaymentHistoryList from US2 |
| US6 | P3 | Phase 2 | Requires Payment repository from Phase 2 |

### Within Each User Story

1. Datasource methods before repository/provider
2. Providers before UI components
3. Widgets before pages
4. Core implementation before integration

### Parallel Opportunities

**Phase 2 (Foundational):**
```
Parallel: T006 (PaymentModel) + T011 (PaymentStatusBadge)
Sequential: T004 → T005 → T006 → T007 → T008 → T009 → T010
```

**Phase 3 (US1) - After T012:**
```
Parallel: T015 (check fields) + T016 (reference field) + T019 (French labels)
```

**Phase 5 (US3) - After T030:**
```
Parallel: T033 (status filter) + T034 (period filter) + T035 (tenant search)
```

**Phase 9 (Polish):**
```
Parallel: T065, T066, T067, T068, T069 (all independent)
```

---

## Parallel Example: Phase 2 Foundation

```bash
# Sequential core chain:
T004 → T005 → T006 → T007 → T008 → T009 → T010

# Parallel opportunity:
After T005, can start in parallel:
- T006 (PaymentModel)
- T011 (PaymentStatusBadge)
```

## Parallel Example: User Story 3

```bash
# After RentScheduleCard (T030) is complete:
# Launch filter implementations in parallel:
Task: T033 - Status filter dropdown
Task: T034 - Period filter
Task: T035 - Tenant search field
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (database migration)
2. Complete Phase 2: Foundational (entity, repository, providers)
3. Complete Phase 3: User Story 1 (payment recording)
4. **STOP and VALIDATE**: Test payment creation, verify schedule updates
5. Deploy/demo if ready

### Incremental Delivery

1. Setup + Foundational → Foundation ready
2. Add US1 (Record Payment) → Test → **MVP Complete!**
3. Add US2 (Payment History) → Test → Enhanced traceability
4. Add US3 (Payments Page) → Test → Centralized management
5. Add US4 (Overdue View) → Test → Risk visibility
6. Add US5 (Edit/Delete) → Test → Error correction
7. Add US6 (Tenant Summary) → Test → Complete tenant view

### Suggested Scope

- **Minimum Viable**: US1 + US2 (record payments, see history)
- **Recommended MVP**: US1 + US2 + US3 + US4 (full payment management)
- **Complete Feature**: All 6 user stories

---

## Summary

| Phase | Task Count | User Story |
|-------|------------|------------|
| Phase 1: Setup | 3 | - |
| Phase 2: Foundational | 8 | - |
| Phase 3 | 9 | US1 - Enregistrer paiement |
| Phase 4 | 7 | US2 - Historique echeance |
| Phase 5 | 13 | US3 - Page globale |
| Phase 6 | 7 | US4 - Visualiser impayes |
| Phase 7 | 9 | US5 - Modifier paiement |
| Phase 8 | 8 | US6 - Historique locataire |
| Phase 9: Polish | 9 | - |
| **Total** | **73** | |

### Independent Test Criteria

| Story | Independent Test |
|-------|------------------|
| US1 | Record payment → schedule.status updates |
| US2 | View schedule → payment history displays |
| US3 | Navigate to /payments → schedules list with filters |
| US4 | Overdue filter → only overdue schedules, sorted by age |
| US5 | Edit/delete payment → schedule recalculates |
| US6 | View tenant → payment summary and history display |

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Database trigger handles schedule updates automatically - no client-side calculation needed
