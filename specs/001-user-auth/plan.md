# Implementation Plan: User Authentication System

**Branch**: `001-user-auth` | **Date**: 2026-01-06 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-user-auth/spec.md`

## Summary

Implement a complete authentication system for LocaGest including user registration, login, password reset, role-based access control (admin/gestionnaire/assistant), and secure session management. The system leverages Supabase Auth for authentication with custom RLS policies for authorization, following Clean Architecture principles with Flutter/Riverpod on the frontend.

## Technical Context

**Language/Version**: Dart 3.x (Flutter SDK stable)
**Primary Dependencies**: supabase_flutter, flutter_riverpod, go_router, freezed, flutter_secure_storage
**Storage**: Supabase (PostgreSQL with RLS) via Supabase Auth
**Testing**: flutter_test (widget tests), integration_test (integration tests)
**Target Platform**: Android, iOS, Web (Flutter multi-platform)
**Project Type**: Mobile/Web application (Flutter Clean Architecture)
**Performance Goals**: Login <5 seconds, Registration <2 minutes, 100 concurrent users
**Constraints**: Offline read capability for essential data, French-only UI, GDPR-aligned data handling
**Scale/Scope**: 50-150 managed properties, ~100 users, 10 auth-related screens

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Compliance Notes |
|-----------|--------|------------------|
| I. Clean Architecture | PASS | Auth logic in Domain (use cases), Supabase calls in Data (datasources), UI in Presentation (providers/pages) |
| II. Mobile-First UX | PASS | Login/Register forms will use proper keyboard types (email), 48dp touch targets, French error messages |
| III. Supabase-First Data | PASS | Using Supabase Auth for authentication, RLS policies for role-based authorization, credentials in .env |
| IV. French Localization | PASS | All auth messages defined in French per spec (e.g., "Email ou mot de passe incorrect") |
| V. Security by Design | PASS | Auth guards on all routes, RLS for authorization, flutter_secure_storage for tokens, audit timestamps |

**Gate Status**: PASSED - No violations requiring justification.

## Project Structure

### Documentation (this feature)

```text
specs/001-user-auth/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── auth-api.md      # Supabase Auth API contracts
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── constants/
│   │   └── app_constants.dart       # Auth-related constants (timeouts, limits)
│   ├── errors/
│   │   └── auth_exceptions.dart     # Custom auth error types
│   ├── theme/
│   │   └── app_theme.dart           # Status colors, button styles
│   └── utils/
│       ├── validators.dart          # Email, password validation
│       └── secure_storage.dart      # Token storage wrapper
├── data/
│   ├── datasources/
│   │   └── auth_remote_datasource.dart  # Supabase Auth calls
│   ├── models/
│   │   └── user_model.dart          # Freezed model for profiles table
│   └── repositories/
│       └── auth_repository_impl.dart    # Repository implementation
├── domain/
│   ├── entities/
│   │   └── user.dart                # User entity (pure Dart)
│   ├── repositories/
│   │   └── auth_repository.dart     # Repository interface
│   └── usecases/
│       ├── sign_in.dart             # Login use case
│       ├── sign_up.dart             # Registration use case
│       ├── sign_out.dart            # Logout use case
│       ├── reset_password.dart      # Password reset use case
│       ├── get_current_user.dart    # Session check use case
│       └── update_user_role.dart    # Role management use case (admin only)
└── presentation/
    ├── pages/
    │   ├── auth/
    │   │   ├── login_page.dart
    │   │   ├── register_page.dart
    │   │   ├── forgot_password_page.dart
    │   │   └── reset_password_page.dart
    │   └── settings/
    │       └── user_management_page.dart  # Admin only
    ├── providers/
    │   └── auth_provider.dart       # Riverpod auth state
    └── widgets/
        ├── auth_guard.dart          # Route protection widget
        └── role_guard.dart          # Role-based UI visibility

test/
├── unit/
│   ├── validators_test.dart
│   └── usecases/
│       ├── sign_in_test.dart
│       └── sign_up_test.dart
└── widget/
    ├── login_page_test.dart
    └── register_page_test.dart

supabase/
└── migrations/
    └── 001_auth_setup.sql           # RLS policies and profiles table
```

**Structure Decision**: Flutter Clean Architecture with Supabase backend. All auth logic follows the standard lib/ structure with domain/data/presentation layers. Database migrations tracked in supabase/migrations/.

## Complexity Tracking

> No violations - table not required.
