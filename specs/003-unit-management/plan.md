# Implementation Plan: Module Lots/Unités (Unit Management)

**Branch**: `003-unit-management` | **Date**: 2026-01-07 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/003-unit-management/spec.md`

## Summary

Implement complete CRUD functionality for rental units (lots) within buildings. Units are the core rentable entities in the property management system, with attributes including reference, type (residential/commercial), floor, surface area, rent, charges, status, equipment list, and photos. This module follows the existing Building Management patterns using Clean Architecture with Riverpod state management, Freezed models, and Supabase backend with RLS policies.

## Technical Context

**Language/Version**: Dart 3.x (Flutter SDK stable)
**Primary Dependencies**: flutter_riverpod 2.4.x, go_router 13.x, freezed 2.4.x, supabase_flutter 2.x, image_picker 1.x
**Storage**: Supabase PostgreSQL (units table) + Supabase Storage (photos bucket)
**Testing**: Flutter test framework (widget tests, integration tests)
**Target Platform**: Android, iOS, Web (mobile-first)
**Project Type**: mobile - Flutter Clean Architecture
**Performance Goals**: Unit list load <2s for 100 units, photo upload <10s for typical smartphone images
**Constraints**: Mobile-first UX, offline read capability (future), French localization, CFA Franc currency
**Scale/Scope**: 50-150 units per property manager, up to 100 units per building

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Evidence |
|-----------|--------|----------|
| **I. Clean Architecture** | ✅ PASS | Will follow existing Building module pattern: Entity → Repository Interface (Domain), Model + Datasource + Repository Impl (Data), Provider + Pages (Presentation) |
| **II. Mobile-First UX** | ✅ PASS | Unit cards with status badges, form validation, loading states, French error messages, bottom navigation integration |
| **III. Supabase-First Data** | ✅ PASS | Units table with RLS policies (admin/gestionnaire/assistant), photos in existing bucket with signed URLs, foreign key to buildings |
| **IV. French Localization** | ✅ PASS | All UI text in French, CFA Franc formatting for rent/charges, DD/MM/YYYY date format |
| **V. Security by Design** | ✅ PASS | RLS policies enforce role-based access, unique constraint on reference per building, cascade delete from building, input validation both client and server |

**Gate Status**: ✅ ALL GATES PASS - Proceed to Phase 0

## Project Structure

### Documentation (this feature)

```text
specs/003-unit-management/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
│   └── unit-api.md      # Supabase table/RLS contract
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── errors/
│   │   └── unit_exceptions.dart           # Unit-specific exceptions
│   └── utils/
│       ├── formatters.dart                # Existing - add currency formatter if needed
│       └── validators.dart                # Existing - add unit validators
├── data/
│   ├── models/
│   │   ├── unit_model.dart                # Freezed model + CreateUnitInput + UpdateUnitInput
│   │   ├── unit_model.freezed.dart        # Generated
│   │   └── unit_model.g.dart              # Generated
│   ├── datasources/
│   │   └── unit_remote_datasource.dart    # Supabase units table operations
│   └── repositories/
│       └── unit_repository_impl.dart      # UnitRepository implementation
├── domain/
│   ├── entities/
│   │   └── unit.dart                      # Unit entity (pure Dart)
│   ├── repositories/
│   │   └── unit_repository.dart           # Unit repository interface
│   └── usecases/
│       ├── create_unit.dart
│       ├── get_units_by_building.dart
│       ├── get_unit_by_id.dart
│       ├── update_unit.dart
│       ├── delete_unit.dart
│       └── upload_unit_photo.dart
└── presentation/
    ├── providers/
    │   └── units_provider.dart            # Riverpod providers for units
    ├── pages/
    │   └── units/
    │       ├── unit_detail_page.dart
    │       ├── unit_form_page.dart
    │       └── unit_edit_page.dart
    └── widgets/
        └── units/
            ├── unit_card.dart             # Unit list item with status badge
            ├── unit_form.dart             # Reusable form widget
            ├── unit_status_badge.dart     # Status indicator widget
            ├── unit_photos_gallery.dart   # Photo gallery widget
            └── equipment_list_editor.dart # Equipment CRUD widget

supabase/migrations/
└── 003_units.sql                          # Units table, indexes, RLS, triggers
```

**Structure Decision**: Following existing Flutter Clean Architecture pattern from Building Management module. Units are nested within building detail view (integrated list), with dedicated pages for detail/form/edit.

## Complexity Tracking

> No constitution violations - table not needed.
