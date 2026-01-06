# Implementation Plan: Building Management (Gestion des Immeubles)

**Branch**: `002-building-management` | **Date**: 2026-01-06 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/002-building-management/spec.md`

## Summary

Implement CRUD operations for building (immeuble) management, enabling property managers to create, view, edit, and delete buildings in their portfolio. This is the foundational feature for property management, providing the container entity for all units, leases, and tenant relationships. The implementation follows Clean Architecture with Supabase backend, Riverpod state management, and French localization.

## Technical Context

**Language/Version**: Dart 3.x (Flutter SDK stable)
**Primary Dependencies**: flutter_riverpod, go_router, freezed, supabase_flutter, image_picker
**Storage**: Supabase PostgreSQL (buildings table) + Supabase Storage (photos bucket)
**Testing**: flutter_test (unit + widget tests)
**Target Platform**: Android, iOS, Web (mobile-first)
**Project Type**: Mobile application with Clean Architecture
**Performance Goals**: List loads <2s for 100 buildings, form submission <500ms feedback
**Constraints**: Offline-capable for read operations, max 1MB compressed photos, French UI
**Scale/Scope**: Up to 200 buildings per user, typical portfolio 50-150 buildings

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Requirement | Status | Notes |
|-----------|-------------|--------|-------|
| I. Clean Architecture | Presentation → Domain ← Data layer separation | ✅ PASS | Following established patterns from auth feature |
| I. Clean Architecture | Use cases single-responsibility | ✅ PASS | One use case per CRUD operation |
| I. Clean Architecture | Repository interfaces in Domain | ✅ PASS | BuildingRepository interface defined |
| II. Mobile-First UX | Touch targets ≥48x48 dp | ✅ PASS | Will use standard Flutter widgets |
| II. Mobile-First UX | Critical actions ≤3 taps | ✅ PASS | Create building: List → FAB → Form → Save (3 taps) |
| II. Mobile-First UX | Loading states for async ops | ✅ PASS | Provider handles AsyncValue states |
| II. Mobile-First UX | French error messages | ✅ PASS | All messages in French |
| III. Supabase-First | RLS enabled on buildings table | ✅ PASS | Policies for admin/gestionnaire/assistant |
| III. Supabase-First | Private storage for photos | ✅ PASS | photos bucket with signed URLs |
| III. Supabase-First | Credentials in .env | ✅ PASS | Already configured in auth feature |
| IV. French Localization | UI text in French | ✅ PASS | All labels, buttons, messages |
| IV. French Localization | Date format DD/MM/YYYY | ✅ PASS | Date display formatting |
| V. Security | Auth required for all routes | ✅ PASS | AuthGuard from auth feature |
| V. Security | RLS + UI authorization | ✅ PASS | Role checks at both layers |
| V. Security | created_by + timestamps | ✅ PASS | Schema includes audit fields |

**Gate Status**: ✅ ALL PRINCIPLES SATISFIED - Proceed to Phase 0

## Project Structure

### Documentation (this feature)

```text
specs/002-building-management/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── building-api.md  # Supabase operations contract
└── tasks.md             # Phase 2 output (via /speckit.tasks)
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── constants/
│   │   └── app_constants.dart      # Add building-related constants
│   ├── errors/
│   │   └── building_exceptions.dart # NEW: Building-specific exceptions
│   └── utils/
│       └── validators.dart          # Add building validation rules
├── data/
│   ├── datasources/
│   │   └── building_remote_datasource.dart  # NEW: Supabase operations
│   ├── models/
│   │   └── building_model.dart              # NEW: Freezed model
│   └── repositories/
│       └── building_repository_impl.dart    # NEW: Repository impl
├── domain/
│   ├── entities/
│   │   └── building.dart                    # NEW: Domain entity
│   ├── repositories/
│   │   └── building_repository.dart         # NEW: Repository interface
│   └── usecases/
│       ├── create_building.dart             # NEW
│       ├── get_buildings.dart               # NEW
│       ├── get_building_by_id.dart          # NEW
│       ├── update_building.dart             # NEW
│       └── delete_building.dart             # NEW
└── presentation/
    ├── pages/
    │   └── buildings/
    │       ├── buildings_list_page.dart     # NEW
    │       ├── building_detail_page.dart    # NEW
    │       └── building_form_page.dart      # NEW
    ├── providers/
    │   └── buildings_provider.dart          # NEW
    └── widgets/
        └── buildings/
            ├── building_card.dart           # NEW
            └── building_form.dart           # NEW
```

**Structure Decision**: Following established Clean Architecture pattern from 001-user-auth. Buildings feature mirrors the auth structure with datasource → model → repository impl → entity → repository interface → use cases → providers → pages/widgets.

## Complexity Tracking

> No constitution violations requiring justification. Standard CRUD feature following established patterns.

| Component | Complexity | Rationale |
|-----------|------------|-----------|
| 5 Use Cases | Low | One per CRUD operation + list, single responsibility |
| 1 Provider | Low | Standard AsyncNotifier pattern for buildings state |
| 3 Pages | Medium | List, detail, form (create/edit shared) |
| 2 Widgets | Low | Card for list, form for input |
