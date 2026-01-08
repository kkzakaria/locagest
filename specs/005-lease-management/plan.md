# Implementation Plan: Module Baux (Lease Management)

**Branch**: `005-lease-management` | **Date**: 2026-01-08 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/005-lease-management/spec.md`

## Summary

Implement the Lease (Bail) module for LocaGest property management application. This module manages rental contracts between tenants and units, with automatic monthly rent schedule generation. Key features include lease CRUD operations, unit status auto-update (vacant/occupied), termination workflow with confirmation modal, and integration with existing tenant and unit modules.

**Technical approach**: Follow existing Clean Architecture patterns established in tenant/unit modules. Use Freezed models with three-model pattern (main, create input, update input), Riverpod StateNotifier for list management, and comprehensive Supabase integration with RLS policies.

## Technical Context

**Language/Version**: Dart 3.x (Flutter SDK stable)
**Primary Dependencies**: flutter_riverpod 2.6.x, go_router 14.x, freezed 2.5.x, supabase_flutter 2.8.x
**Storage**: Supabase PostgreSQL (leases, rent_schedules tables) + existing profiles, buildings, units, tenants tables
**Testing**: flutter test (widget and unit tests)
**Target Platform**: Android, iOS, Web (Flutter multi-platform)
**Project Type**: Mobile-first with web support (Flutter cross-platform)
**Performance Goals**: Dashboard queries <2 seconds, list pagination for >20 items, UI interactions <1 second
**Constraints**: Offline read capability (future), mobile-first UX with 48x48dp touch targets, French localization
**Scale/Scope**: 50-150 rental units per property manager, ~10 screens for lease module

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Clean Architecture | ✅ PASS | Three-layer separation with Presentation → Domain ← Data flow. Use cases optional per existing patterns. |
| II. Mobile-First UX | ✅ PASS | 48x48dp touch targets, ≤3 taps for critical actions, status colors defined (🟢 active, 🔴 terminated/expired, 🟡 pending) |
| III. Supabase-First Data | ✅ PASS | RLS enabled, role-based policies (admin/gestionnaire/assistant), storage for lease documents (future) |
| IV. French Localization | ✅ PASS | All UI text in French, DD/MM/YYYY dates, FCFA currency with space separators |
| V. Security by Design | ✅ PASS | Auth required, RLS policies, input validation on client and server, audit timestamps |

**Pre-design Gate**: ✅ PASS - All constitution principles satisfied

### Post-Design Re-check (Phase 1 Complete)

| Principle | Status | Verification |
|-----------|--------|--------------|
| I. Clean Architecture | ✅ PASS | Data model follows three-layer separation; no Supabase imports in domain layer |
| II. Mobile-First UX | ✅ PASS | Form design supports touch targets; status colors defined; critical actions (create lease) achievable in ≤3 taps |
| III. Supabase-First Data | ✅ PASS | RLS policies defined in data-model.md; unique index prevents duplicate active leases; storage for documents planned |
| IV. French Localization | ✅ PASS | All labels in French; status enums have French translations; FCFA formatting specified |
| V. Security by Design | ✅ PASS | Role-based access in providers; RLS policies per role; audit timestamps on all records |

**Post-design Gate**: ✅ PASS - Design artifacts comply with constitution

## Project Structure

### Documentation (this feature)

```text
specs/005-lease-management/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (API contracts)
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
lib/
├── core/
│   └── errors/
│       └── lease_exceptions.dart        # Lease-specific exceptions
├── data/
│   ├── datasources/
│   │   └── lease_remote_datasource.dart # Supabase lease operations
│   ├── models/
│   │   ├── lease_model.dart             # LeaseModel, CreateLeaseInput, UpdateLeaseInput
│   │   └── rent_schedule_model.dart     # RentScheduleModel (read-only from DB)
│   └── repositories/
│       └── lease_repository_impl.dart   # Repository implementation
├── domain/
│   ├── entities/
│   │   ├── lease.dart                   # Lease entity with status enum
│   │   └── rent_schedule.dart           # RentSchedule entity
│   └── repositories/
│       └── lease_repository.dart        # Repository interface
└── presentation/
    ├── pages/
    │   └── leases/
    │       ├── leases_list_page.dart    # All leases list with filters
    │       ├── lease_form_page.dart     # Create lease form
    │       ├── lease_detail_page.dart   # Lease detail view
    │       └── lease_edit_page.dart     # Edit lease form
    ├── providers/
    │   └── leases_provider.dart         # Riverpod state management
    └── widgets/
        └── leases/
            ├── lease_card.dart          # List item card
            ├── lease_status_badge.dart  # Status badge widget
            ├── lease_form_fields.dart   # Reusable form fields
            ├── lease_section.dart       # For unit/tenant detail pages
            └── termination_modal.dart   # Confirmation dialog

supabase/migrations/
└── 005_leases.sql                       # Database schema + RLS policies

test/
└── lease/
    ├── lease_model_test.dart            # Model serialization tests
    └── lease_repository_test.dart       # Repository unit tests
```

**Structure Decision**: Following existing Clean Architecture pattern established in tenant/unit modules. Single Flutter project targeting mobile (Android/iOS) and web platforms.

## Complexity Tracking

No constitution violations requiring justification. Implementation follows established patterns.
