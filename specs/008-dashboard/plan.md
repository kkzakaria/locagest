# Implementation Plan: Dashboard avec KPIs

**Branch**: `008-dashboard` | **Date**: 2026-01-09 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/008-dashboard/spec.md`

## Summary

Implement a functional dashboard for LocaGest displaying key performance indicators (KPIs), priority unpaid rents (top 5), expiring leases (30 days), occupancy rate with color coding, and a bottom navigation bar. The dashboard will leverage existing repositories (buildings, units, tenants, leases, payments) and aggregate data through a new DashboardRepository with optimized Supabase queries.

## Technical Context

**Language/Version**: Dart 3.x (Flutter SDK ^3.10.4, stable channel)
**Primary Dependencies**: flutter_riverpod 2.6.x, go_router 14.x, supabase_flutter 2.8.x, intl 0.20.x
**Storage**: Supabase PostgreSQL (existing tables: profiles, buildings, units, tenants, leases, rent_schedules, payments)
**Testing**: flutter_test (widget and unit tests)
**Target Platform**: Android, iOS, Web (Flutter cross-platform)
**Project Type**: Mobile-first Flutter application with existing Clean Architecture
**Performance Goals**: Dashboard KPIs load in <2 seconds (Constitution: "Dashboard queries MUST complete in <2 seconds")
**Constraints**: Mobile-first UX, French localization (Ivory Coast), FCFA currency, RBAC permissions
**Scale/Scope**: Target 100 buildings, 500 units, 1000+ rent schedules (from spec SC-002)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Requirement | Status | Notes |
|-----------|-------------|--------|-------|
| I. Clean Architecture | Separate Presentation/Domain/Data layers | PASS | New DashboardRepository interface in Domain, impl in Data, DashboardProvider in Presentation |
| II. Mobile-First UX | Touch targets 48x48dp, 3 taps max, bottom nav, status colors | PASS | KPI cards, bottom nav bar, color-coded occupancy rate |
| III. Supabase-First Data | RLS enabled, role-based policies | PASS | Uses existing RLS-protected tables, aggregate queries via Supabase |
| IV. French Localization | UI in French, FCFA format, DD/MM/YYYY dates | PASS | All labels/messages in French per spec |
| V. Security by Design | Auth required, RBAC at UI and API levels | PASS | Actions filtered by user role per FR-009 |

**Gate Result**: PASS - All constitution principles satisfied

## Project Structure

### Documentation (this feature)

```text
specs/008-dashboard/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (repository interfaces)
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── constants/
│   ├── errors/
│   ├── router/
│   │   └── app_router.dart       # UPDATE: Add bottom nav shell route
│   ├── theme/
│   └── utils/
├── data/
│   ├── datasources/
│   │   └── dashboard_remote_datasource.dart    # NEW: Supabase queries
│   ├── models/
│   │   └── dashboard_stats_model.dart          # NEW: Freezed model
│   └── repositories/
│       └── dashboard_repository_impl.dart      # NEW: Implementation
├── domain/
│   ├── entities/
│   │   ├── dashboard_stats.dart                # NEW: Entity
│   │   ├── overdue_rent.dart                   # NEW: Entity
│   │   └── expiring_lease.dart                 # NEW: Entity
│   └── repositories/
│       └── dashboard_repository.dart           # NEW: Interface
└── presentation/
    ├── pages/
    │   └── home/
    │       └── dashboard_page.dart             # UPDATE: Full implementation
    ├── providers/
    │   └── dashboard_provider.dart             # NEW: Riverpod providers
    └── widgets/
        └── dashboard/                          # NEW: Dashboard widgets
            ├── kpi_card.dart
            ├── overdue_rent_card.dart
            ├── expiring_lease_card.dart
            ├── occupancy_rate_widget.dart
            └── main_navigation_shell.dart
```

**Structure Decision**: Mobile Flutter application following existing Clean Architecture pattern. New Dashboard module with Domain entities, Data layer (repository + datasource), and Presentation layer (provider + widgets). Bottom navigation requires a shell route wrapper for persistent navigation.

## Complexity Tracking

> No constitution violations requiring justification.

| Aspect | Complexity | Justification |
|--------|------------|---------------|
| Aggregate queries | Low | Single Supabase call per KPI using COUNT/SUM |
| Bottom navigation | Low | Standard Flutter Scaffold with NavigationBar |
| State management | Low | FutureProvider for dashboard stats, no complex state |

---

## Post-Design Constitution Re-Check

*Gate re-evaluation after Phase 1 design artifacts completed.*

| Principle | Design Artifact | Compliance | Evidence |
|-----------|----------------|------------|----------|
| I. Clean Architecture | data-model.md, contracts/ | PASS | DashboardRepository interface in Domain, DashboardRepositoryImpl in Data, DashboardProvider in Presentation. No Supabase imports in Domain layer. |
| II. Mobile-First UX | quickstart.md | PASS | KPI cards with touch-friendly targets, bottom NavigationBar with 4 tabs, color-coded indicators (green/orange/red). |
| III. Supabase-First Data | research.md, contracts/ | PASS | All queries use existing RLS-protected tables. Parallel queries via Future.wait(). No new tables required. |
| IV. French Localization | quickstart.md | PASS | All labels defined in French. FCFA currency formatting. DD/MM/YYYY dates via intl package. |
| V. Security by Design | contracts/ | PASS | DashboardRepository uses authenticated Supabase client. RLS policies filter data per user. RBAC controls quick actions visibility. |

**Post-Design Gate Result**: PASS - All constitution principles verified against design artifacts.

---

## Generated Artifacts

| Artifact | Path | Status |
|----------|------|--------|
| Research | `specs/008-dashboard/research.md` | Complete |
| Data Model | `specs/008-dashboard/data-model.md` | Complete |
| Contracts | `specs/008-dashboard/contracts/dashboard_repository.dart` | Complete |
| Quickstart | `specs/008-dashboard/quickstart.md` | Complete |
| Tasks | `specs/008-dashboard/tasks.md` | Pending (`/speckit.tasks`) |

---

## Next Steps

1. Run `/speckit.tasks` to generate implementation tasks
2. Implement tasks in order (Setup → Foundational → User Stories)
3. Run `flutter pub run build_runner build --delete-conflicting-outputs` after creating Freezed models
4. Test dashboard with existing test data
