# Implementation Plan: Module Echeances et Paiements

**Branch**: `006-payment-management` | **Date**: 2026-01-08 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/006-payment-management/spec.md`

## Summary

This feature implements a complete payment management module for LocaGest, enabling property managers to record, track, and manage rent payments against monthly rent schedules (echeances). The implementation extends the existing rent_schedules infrastructure (from Phase 7) with a dedicated payments table, payment history tracking, a centralized payments page with filtering, and integration with the tenant detail page.

**Technical Approach**: Extend the existing Clean Architecture with a new Payment entity and repository, create a dedicated payments database table with RLS policies, and add a payments page accessible from the main navigation.

## Technical Context

**Language/Version**: Dart 3.x with Flutter SDK (stable channel)
**Primary Dependencies**: flutter_riverpod 2.6.x, go_router 14.x, freezed 2.5.x, supabase_flutter 2.8.x, intl (date/currency formatting)
**Storage**: Supabase PostgreSQL with RLS - new `payments` table linking to existing `rent_schedules`
**Testing**: flutter test, Playwright for E2E testing (established pattern in project)
**Target Platform**: Android, iOS, Web (Flutter multi-platform)
**Project Type**: Mobile + Web application (Flutter)
**Performance Goals**: Page load <2s for 50 leases, filters <1s response
**Constraints**: Offline read not required for payments (online-only), FCFA currency (no decimals)
**Scale/Scope**: 50-150 managed properties, ~600 schedules/year per property = ~90,000 potential records

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Clean Architecture | PASS | Payment follows established pattern: Entity → Repository Interface → Repository Impl → Datasource. No Supabase in presentation layer. |
| II. Mobile-First UX | PASS | Payment form requires ≤3 fields minimum (amount, method, date). Touch targets will use standard Flutter sizing (48dp). Status colors follow existing scheme (green=paid, red=overdue). |
| III. Supabase-First Data | PASS | New payments table with RLS policies following existing pattern. Payments linked via FK to rent_schedules. No external storage services. |
| IV. French Localization | PASS | All labels in French, FCFA formatting with space separator (existing pattern), DD/MM/YYYY dates. Error messages in French. |
| V. Security by Design | PASS | RLS policies for payments: admin (full), gestionnaire (own via lease chain), assistant (read + insert only). created_by audit field. |

**Gate Result**: PASS - All constitution principles satisfied. Proceed to Phase 0.

## Project Structure

### Documentation (this feature)

```text
specs/006-payment-management/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (Supabase schema + Dart interfaces)
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
lib/
├── core/
│   └── router/app_router.dart          # Add /payments route
├── data/
│   ├── datasources/
│   │   └── payment_remote_datasource.dart  # NEW: Supabase CRUD for payments
│   ├── models/
│   │   └── payment_model.dart              # NEW: Freezed model
│   └── repositories/
│       └── payment_repository_impl.dart    # NEW: Repository implementation
├── domain/
│   ├── entities/
│   │   └── payment.dart                    # NEW: Payment entity
│   └── repositories/
│       └── payment_repository.dart         # NEW: Repository interface
└── presentation/
    ├── pages/
    │   └── payments/
    │       ├── payments_page.dart          # NEW: Centralized payments/schedules list
    │       └── payment_form_modal.dart     # NEW: Modal for recording payment
    ├── providers/
    │   └── payments_provider.dart          # NEW: Riverpod providers
    └── widgets/
        └── payments/
            ├── payment_status_badge.dart   # NEW: Status badge widget
            ├── rent_schedule_card.dart     # NEW: Schedule list item
            └── payment_history_list.dart   # NEW: Payment history display

supabase/migrations/
└── 006_payments.sql                        # NEW: Payments table + RLS

test/
├── unit/
│   └── domain/
│       └── payment_test.dart               # Unit tests for entity logic
└── integration/
    └── payments_test.dart                  # E2E tests (Playwright pattern)
```

**Structure Decision**: Follows established Clean Architecture pattern from existing modules (buildings, units, tenants, leases). Payment module added as parallel structure.

## Complexity Tracking

> No constitution violations requiring justification.

| Item | Status |
|------|--------|
| Layer separation | Standard - follows existing patterns |
| New table (payments) | Required for tracking individual payment transactions |
| RLS policies | Standard - follows existing role-based pattern |

---

## Post-Design Constitution Check

*Re-evaluated after Phase 1 design completion.*

| Principle | Status | Post-Design Notes |
|-----------|--------|-------------------|
| I. Clean Architecture | PASS | Design confirms: PaymentEntity (domain), PaymentModel+Freezed (data), PaymentRepository interface (domain) with impl (data), PaymentsProvider (presentation). No leakage. |
| II. Mobile-First UX | PASS | PaymentFormModal designed as bottom sheet with 3 required fields. RentScheduleCard uses existing status colors. Touch targets inherit Flutter defaults (48dp). |
| III. Supabase-First Data | PASS | 006_payments.sql contract defines: RLS policies with role-based access, receipt number generation via PL/pgSQL function, trigger for automatic schedule amount updates. |
| IV. French Localization | PASS | PaymentMethod enum includes French labels. Amount formatting uses FCFA with NumberFormat('fr_FR'). All error messages defined in French. |
| V. Security by Design | PASS | RLS: admin (full), gestionnaire (chain via lease.created_by), assistant (SELECT + INSERT only, no UPDATE/DELETE). Trigger auto-sets created_by. |

**Final Gate Result**: PASS - All constitution principles verified post-design. Ready for Phase 2 (tasks generation).

---

## Generated Artifacts

| Artifact | Path | Description |
|----------|------|-------------|
| Research | `research.md` | Technical decisions and rationale |
| Data Model | `data-model.md` | Entity definitions, relationships, state transitions |
| SQL Contract | `contracts/006_payments.sql` | Database migration with RLS |
| Repository Contract | `contracts/payment_repository.dart` | Dart interface specification |
| Quickstart | `quickstart.md` | Implementation guide with code samples |

---

## Next Steps

Run `/speckit.tasks` to generate the implementation task list based on this plan.
