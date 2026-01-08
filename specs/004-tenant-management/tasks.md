# Tasks: Module Locataires (Tenant Management)

**Input**: Design documents from `/specs/004-tenant-management/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/tenant-api.md

**Tests**: Not explicitly requested - tests are OMITTED from this task list.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Flutter Clean Architecture**: `lib/` at repository root
- **Migrations**: `supabase/migrations/`
- Paths follow plan.md structure

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Database setup and core infrastructure for tenant management

- [x] T001 Create database migration with tenants table, constraints, indexes, triggers, and RLS policies in `supabase/migrations/004_tenants.sql`
- [x] T002 Create documents storage bucket with private access and storage policies in `supabase/migrations/004_tenants.sql` (storage section)
- [x] T003 [P] Create tenant exceptions in `lib/core/errors/tenant_exceptions.dart`
- [x] T004 [P] Add phone and email validators for Ivory Coast formats in `lib/core/utils/validators.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Domain entity, data models, and repository infrastructure that MUST be complete before ANY user story

**CRITICAL**: No user story work can begin until this phase is complete

- [x] T005 Create Tenant domain entity with IdDocumentType enum and computed properties in `lib/domain/entities/tenant.dart`
- [x] T006 Create TenantModel, CreateTenantInput, UpdateTenantInput Freezed models in `lib/data/models/tenant_model.dart`
- [x] T007 Run Freezed code generation: `flutter pub run build_runner build --delete-conflicting-outputs`
- [x] T008 Create TenantRepository interface in `lib/domain/repositories/tenant_repository.dart`
- [x] T009 Create TenantRemoteDatasource with Supabase operations in `lib/data/datasources/tenant_remote_datasource.dart`
- [x] T010 Create TenantRepositoryImpl in `lib/data/repositories/tenant_repository_impl.dart`
- [x] T011 Create Riverpod providers (repository, datasource) in `lib/presentation/providers/tenants_provider.dart`

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - View Tenants List (Priority: P1) MVP

**Goal**: Display list of all tenants with search functionality and status badges

**Independent Test**: Navigate to "Locataires" page, verify list displays with name, phone, status; search filters correctly; empty state shows "Aucun locataire"

### Implementation for User Story 1

- [x] T012 [US1] Implement getTenants and searchTenants use cases in datasource `lib/data/datasources/tenant_remote_datasource.dart`
- [x] T013 [P] [US1] Create TenantStatusBadge widget (Actif/Inactif) in `lib/presentation/widgets/tenants/tenant_status_badge.dart`
- [x] T014 [P] [US1] Create TenantCard widget with name, phone, status in `lib/presentation/widgets/tenants/tenant_card.dart`
- [x] T015 [US1] Add tenantsProvider and tenantSearchProvider to `lib/presentation/providers/tenants_provider.dart`
- [x] T016 [US1] Create TenantsListPage with search bar, list, empty state, FAB in `lib/presentation/pages/tenants/tenants_list_page.dart`
- [x] T017 [US1] Add tenants route to router in `lib/core/router/app_router.dart`
- [x] T018 [US1] Add "Locataires" to dashboard quick actions in `lib/presentation/pages/home/dashboard_page.dart`

**Checkpoint**: User Story 1 complete - tenant list viewable and searchable

---

## Phase 4: User Story 2 - Create a New Tenant (Priority: P1) MVP

**Goal**: Create new tenants with personal info, ID documents, professional info, and guarantor details

**Independent Test**: Click "Ajouter un locataire", fill form with required fields (nom, prénom, téléphone), save, verify tenant appears in list

### Implementation for User Story 2

- [x] T019 [US2] Implement createTenant in datasource `lib/data/datasources/tenant_remote_datasource.dart`
- [x] T020 [US2] Implement document upload (uploadDocument, deleteDocument, getDocumentUrl) in datasource `lib/data/datasources/tenant_remote_datasource.dart`
- [x] T021 [P] [US2] Create TenantForm widget with all fields and validation in `lib/presentation/widgets/tenants/tenant_form.dart`
- [x] T022 [P] [US2] Create IdentityDocumentSection widget with type picker and file upload in `lib/presentation/widgets/tenants/identity_document_section.dart`
- [x] T023 [P] [US2] Create GuarantorSection widget with name, phone, document upload in `lib/presentation/widgets/tenants/guarantor_section.dart`
- [x] T024 [US2] Implement duplicate phone check with warning display in `lib/presentation/widgets/tenants/tenant_form.dart`
- [x] T025 [US2] Create TenantFormPage for creating new tenants in `lib/presentation/pages/tenants/tenant_form_page.dart`
- [x] T026 [US2] Add createTenant provider action to `lib/presentation/providers/tenants_provider.dart`
- [x] T027 [US2] Add tenant form route to router in `lib/core/router/app_router.dart`

**Checkpoint**: User Stories 1 AND 2 complete - can view list and create new tenants

---

## Phase 5: User Story 3 - View Tenant Details (Priority: P2)

**Goal**: Display complete tenant information including ID documents, guarantor, and lease history

**Independent Test**: Click on tenant in list, verify all info displays (personal, professional, ID doc, guarantor, lease history placeholder)

### Implementation for User Story 3

- [x] T028 [US3] Implement getTenantById in datasource `lib/data/datasources/tenant_remote_datasource.dart`
- [x] T029 [P] [US3] Create LeaseHistorySection widget (read-only, placeholder until Leases module) in `lib/presentation/widgets/tenants/lease_history_section.dart`
- [x] T030 [US3] Add tenantByIdProvider to `lib/presentation/providers/tenants_provider.dart`
- [x] T031 [US3] Create TenantDetailPage with all sections (personal, professional, ID, guarantor, leases) in `lib/presentation/pages/tenants/tenant_detail_page.dart`
- [x] T032 [US3] Add tenant detail route to router in `lib/core/router/app_router.dart`
- [x] T033 [US3] Connect TenantCard tap to navigate to detail page in `lib/presentation/pages/tenants/tenants_list_page.dart`

**Checkpoint**: User Story 3 complete - can view full tenant details

---

## Phase 6: User Story 4 - Edit Tenant Information (Priority: P2)

**Goal**: Modify existing tenant information with pre-filled form and document replacement

**Independent Test**: From tenant detail, click "Modifier", verify form pre-filled, change values, save, verify changes persisted

### Implementation for User Story 4

- [x] T034 [US4] Implement updateTenant in datasource `lib/data/datasources/tenant_remote_datasource.dart`
- [x] T035 [US4] Create TenantEditPage reusing TenantForm with pre-filled data in `lib/presentation/pages/tenants/tenant_edit_page.dart`
- [x] T036 [US4] Add updateTenant provider action to `lib/presentation/providers/tenants_provider.dart`
- [x] T037 [US4] Add tenant edit route to router in `lib/core/router/app_router.dart`
- [x] T038 [US4] Add "Modifier" button to TenantDetailPage navigating to edit in `lib/presentation/pages/tenants/tenant_detail_page.dart`

**Checkpoint**: User Story 4 complete - can edit any tenant information

---

## Phase 7: User Story 5 - Delete a Tenant (Priority: P3)

**Goal**: Delete tenants without active leases with confirmation dialog and protection

**Independent Test**: From tenant detail (no active lease), click "Supprimer", confirm, verify tenant removed from list; for tenant with active lease, verify error message

### Implementation for User Story 5

- [x] T039 [US5] Implement deleteTenant with active lease check in datasource `lib/data/datasources/tenant_remote_datasource.dart`
- [x] T040 [US5] Implement canDeleteTenant check in datasource `lib/data/datasources/tenant_remote_datasource.dart`
- [x] T041 [US5] Add deleteTenant provider action to `lib/presentation/providers/tenants_provider.dart`
- [x] T042 [US5] Add delete button with confirmation dialog to TenantDetailPage in `lib/presentation/pages/tenants/tenant_detail_page.dart`
- [x] T043 [US5] Handle TenantHasActiveLeaseException with French error message in detail page

**Checkpoint**: User Story 5 complete - can delete tenants with protection for active leases

---

## Phase 8: User Story 6 - Manage Identity Documents (Priority: P3)

**Goal**: Full document management with upload, view, download, and replace functionality

**Independent Test**: Edit tenant, upload ID document (JPEG/PNG/PDF < 5MB), save, view tenant, verify document viewable/downloadable, replace document, verify old removed

### Implementation for User Story 6

- [x] T044 [US6] Add document size validation (5MB max) to IdentityDocumentSection in `lib/presentation/widgets/tenants/identity_document_section.dart`
- [x] T045 [US6] Add document format validation (JPEG, PNG, PDF) to IdentityDocumentSection in `lib/presentation/widgets/tenants/identity_document_section.dart`
- [x] T046 [US6] Implement document preview/download with signed URLs in TenantDetailPage `lib/presentation/pages/tenants/tenant_detail_page.dart`
- [x] T047 [US6] Handle document replacement (delete old, upload new) in IdentityDocumentSection `lib/presentation/widgets/tenants/identity_document_section.dart`
- [x] T048 [US6] Add document upload progress indicator in `lib/presentation/widgets/tenants/identity_document_section.dart`

**Checkpoint**: User Story 6 complete - full document management working

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Final improvements affecting multiple user stories

- [x] T049 [P] Verify all text is in French (labels, buttons, errors, placeholders)
- [x] T050 [P] Add loading states to all async operations in tenant pages
- [x] T051 [P] Verify pagination works for 100+ tenants in list page
- [x] T052 Apply migration to local Supabase: `supabase db reset`
- [x] T053 Run `flutter analyze` and fix any issues
- [x] T054 Run quickstart.md validation checklist

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-8)**: All depend on Foundational phase completion
  - US1 and US2 are both P1 (MVP) - complete in order
  - US3 and US4 are P2 - complete after MVP
  - US5 and US6 are P3 - complete last
- **Polish (Phase 9)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational - No dependencies on other stories
- **User Story 2 (P1)**: Can start after US1 - Uses same list page for navigation
- **User Story 3 (P2)**: Can start after US2 - Navigates from list created in US1
- **User Story 4 (P2)**: Can start after US3 - Uses detail page from US3
- **User Story 5 (P3)**: Can start after US4 - Adds delete to detail page from US3/US4
- **User Story 6 (P3)**: Can start after US4 - Enhances document handling from US2/US4

### Within Each User Story

- Datasource implementation before providers
- Providers before pages
- Widgets can be created in parallel with datasource
- Pages created last (depend on providers and widgets)

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All widget tasks marked [P] within a story can run in parallel
- T003 and T004 (exceptions and validators) can run in parallel
- T013 and T014 (status badge and card widgets) can run in parallel
- T021, T022, T023 (form widgets) can run in parallel
- T049, T050, T051 (polish tasks) can run in parallel

---

## Parallel Example: User Story 2 Widgets

```bash
# Launch all widgets for User Story 2 together:
Task: "Create TenantForm widget in lib/presentation/widgets/tenants/tenant_form.dart"
Task: "Create IdentityDocumentSection widget in lib/presentation/widgets/tenants/identity_document_section.dart"
Task: "Create GuarantorSection widget in lib/presentation/widgets/tenants/guarantor_section.dart"
```

---

## Implementation Strategy

### MVP First (User Stories 1 & 2)

1. Complete Phase 1: Setup (database, exceptions, validators)
2. Complete Phase 2: Foundational (entity, models, repository, datasource)
3. Complete Phase 3: User Story 1 (view tenant list)
4. Complete Phase 4: User Story 2 (create tenant)
5. **STOP and VALIDATE**: Test CRUD independently
6. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational -> Foundation ready
2. Add User Story 1 -> Test -> MVP v1 (view list)
3. Add User Story 2 -> Test -> MVP v2 (create tenant)
4. Add User Story 3 -> Test -> Can view details
5. Add User Story 4 -> Test -> Can edit tenant
6. Add User Story 5 -> Test -> Can delete tenant
7. Add User Story 6 -> Test -> Full document management
8. Each story adds value without breaking previous stories

---

## Summary

| Phase | Description | Task Count |
|-------|-------------|------------|
| Phase 1 | Setup | 4 |
| Phase 2 | Foundational | 7 |
| Phase 3 | US1 - View List (P1) | 7 |
| Phase 4 | US2 - Create Tenant (P1) | 9 |
| Phase 5 | US3 - View Details (P2) | 6 |
| Phase 6 | US4 - Edit Tenant (P2) | 5 |
| Phase 7 | US5 - Delete Tenant (P3) | 5 |
| Phase 8 | US6 - Manage Documents (P3) | 5 |
| Phase 9 | Polish | 6 |
| **Total** | | **54** |

**MVP Scope**: Phases 1-4 (27 tasks) -> View list, create tenants with all fields
**Full Feature**: All phases (54 tasks) -> Complete CRUD + document management

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story is independently testable
- All UI text must be in French per Constitution IV
- Phone validation for Ivory Coast formats (+225, 07, 05, 01 prefixes)
- Document uploads max 5MB, formats: JPEG, PNG, PDF
- Tenant status computed from lease data (inactive until Leases module)
- Commit after each task or logical group
