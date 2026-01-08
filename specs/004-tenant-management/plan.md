# Implementation Plan: Module Locataires (Tenant Management)

**Branch**: `004-tenant-management` | **Date**: 2026-01-07 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/004-tenant-management/spec.md`

## Summary

Implement complete CRUD functionality for tenants (locataires) in the property management system. Tenants are individuals who can rent units through leases. This module captures personal information (name, contact details), identity documents (CNI, passport, carte de séjour with file upload), professional information (profession, employer), and guarantor details. The tenant's active/inactive status is derived from their lease history (active if has current lease). This module follows established Clean Architecture patterns from Building and Unit Management.

## Technical Context

**Language/Version**: Dart 3.x (Flutter SDK stable)
**Primary Dependencies**: flutter_riverpod 2.4.x, go_router 13.x, freezed 2.4.x, supabase_flutter 2.x, image_picker 1.x
**Storage**: Supabase PostgreSQL (tenants table) + Supabase Storage (documents bucket for ID documents)
**Testing**: Flutter test framework (widget tests, integration tests)
**Target Platform**: Android, iOS, Web (mobile-first)
**Project Type**: mobile - Flutter Clean Architecture
**Performance Goals**: Tenant list load <2s for 100 tenants, search results <1s, document upload <10s
**Constraints**: Mobile-first UX, French localization, Ivory Coast context (phone formats +225), max 5MB document uploads
**Scale/Scope**: 50-200 tenants per property manager

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Evidence |
|-----------|--------|----------|
| **I. Clean Architecture** | ✅ PASS | Will follow existing Building/Unit module pattern: Entity → Repository Interface (Domain), Model + Datasource + Repository Impl (Data), Provider + Pages (Presentation) |
| **II. Mobile-First UX** | ✅ PASS | Tenant cards with status badges, form validation, loading states, French error messages, search functionality, bottom navigation integration |
| **III. Supabase-First Data** | ✅ PASS | Tenants table with RLS policies (admin/gestionnaire/assistant), documents in private bucket with signed URLs, created_by ownership tracking |
| **IV. French Localization** | ✅ PASS | All UI text in French, phone validation for Ivory Coast formats (+225 XX XX XX XX XX or 07/05/01 XX XX XX XX), French document type labels |
| **V. Security by Design** | ✅ PASS | RLS policies enforce role-based access, private document storage with signed URLs, input validation both client and server, cannot delete tenant with active lease |

**Gate Status**: ✅ ALL GATES PASS - Proceed to Phase 0

## Project Structure

### Documentation (this feature)

```text
specs/004-tenant-management/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
│   └── tenant-api.md    # Supabase table/RLS contract
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── errors/
│   │   └── tenant_exceptions.dart           # Tenant-specific exceptions
│   └── utils/
│       └── validators.dart                  # Existing - add phone validators
├── data/
│   ├── models/
│   │   ├── tenant_model.dart                # Freezed model + CreateTenantInput + UpdateTenantInput
│   │   ├── tenant_model.freezed.dart        # Generated
│   │   └── tenant_model.g.dart              # Generated
│   ├── datasources/
│   │   └── tenant_remote_datasource.dart    # Supabase tenants table operations
│   └── repositories/
│       └── tenant_repository_impl.dart      # TenantRepository implementation
├── domain/
│   ├── entities/
│   │   └── tenant.dart                      # Tenant entity (pure Dart)
│   ├── repositories/
│   │   └── tenant_repository.dart           # Tenant repository interface
│   └── usecases/
│       ├── create_tenant.dart
│       ├── get_tenants.dart
│       ├── get_tenant_by_id.dart
│       ├── update_tenant.dart
│       ├── delete_tenant.dart
│       ├── search_tenants.dart
│       └── upload_tenant_document.dart
└── presentation/
    ├── providers/
    │   └── tenants_provider.dart            # Riverpod providers for tenants
    ├── pages/
    │   └── tenants/
    │       ├── tenants_list_page.dart
    │       ├── tenant_detail_page.dart
    │       ├── tenant_form_page.dart
    │       └── tenant_edit_page.dart
    └── widgets/
        └── tenants/
            ├── tenant_card.dart             # Tenant list item with status badge
            ├── tenant_form.dart             # Reusable form widget
            ├── tenant_status_badge.dart     # Active/Inactive indicator
            ├── guarantor_section.dart       # Guarantor info section
            ├── identity_document_section.dart # ID document management
            └── lease_history_section.dart   # Read-only lease history

supabase/migrations/
└── 004_tenants.sql                          # Tenants table, indexes, RLS, triggers
```

**Structure Decision**: Following existing Flutter Clean Architecture pattern from Building and Unit Management modules. Tenants have their own dedicated list page accessible from main navigation, with detail/form/edit pages for CRUD operations.

## Complexity Tracking

> No constitution violations - table not needed.
