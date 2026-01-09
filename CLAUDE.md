# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

LocaGest is a property management application (gestion locative) built with Flutter for mobile (Android/iOS) and web. It manages rental properties, tenants, leases, payments, and generates rent receipts (quittances). The backend uses Supabase (PostgreSQL + Auth + Storage).

## Development Commands

```bash
# Run the app
flutter run

# Run on specific platform
flutter run -d chrome          # Web
flutter run -d android         # Android
flutter run -d ios             # iOS

# Generate freezed/json_serializable code
flutter pub run build_runner build --delete-conflicting-outputs

# Analyze code
flutter analyze

# Run tests
flutter test
flutter test test/path/to/specific_test.dart

# Build releases
flutter build apk --release
flutter build ios --release
flutter build web --release
```

## Architecture

This project follows **Clean Architecture** with three main layers:

```
lib/
├── core/           # Shared utilities, constants, theme, error handling
├── data/           # Data layer: models, datasources (Supabase), repository implementations
├── domain/         # Business logic: entities, repository interfaces, use cases
└── presentation/   # UI: pages, widgets, state management (Riverpod providers)
```

### Key Patterns

- **State Management**: Riverpod
- **Navigation**: GoRouter with auth guards
- **Data Models**: Freezed for immutable models with JSON serialization
- **Backend**: Supabase client for database, auth, and storage operations

### Data Model Hierarchy

```
users (profiles)
  └── buildings (immeubles)
        └── units (lots) - apartments/commercial spaces
              └── leases (baux) - rental contracts
                    ├── tenant (locataire)
                    ├── rent_schedules (échéances) - monthly rent dues
                    │     └── payments (paiements)
                    └── inventory_reports (états des lieux)
                          └── inventory_rooms (pièces)
  └── expenses (dépenses) - linked to buildings or units
```

### User Roles

- **admin**: Full access including user management
- **gestionnaire**: Full property/tenant/payment management, reports
- **assistant**: Read-only for properties, full access for tenants/payments/inventory

## Key Dependencies (to be added)

- `supabase_flutter`: Backend client
- `flutter_riverpod`: State management
- `go_router`: Navigation
- `freezed`/`json_serializable`: Model generation
- `pdf`/`printing`: Receipt and report generation
- `image_picker`: Photo capture for inventory
- `signature`: Electronic signatures

## Supabase Configuration

Environment variables needed (store in `.env`, not committed):
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

All tables use Row Level Security (RLS) with policies based on user roles.

## Business Context

- Target users: Independent property managers in Ivory Coast managing 50-150 rental units
- Language: French (UI and documents)
- Currency: Local (CFA Franc implied)
- Key workflows: Property registration, tenant onboarding, monthly rent collection, receipt generation, inventory reports with photos and signatures

## Active Technologies
- Dart 3.x (Flutter SDK stable) + supabase_flutter, flutter_riverpod, go_router, freezed, flutter_secure_storage (001-user-auth)
- Supabase (PostgreSQL with RLS) via Supabase Auth (001-user-auth)
- Dart 3.x (Flutter SDK stable) + flutter_riverpod, go_router, freezed, supabase_flutter, image_picker (002-building-management)
- Supabase PostgreSQL (buildings table) + Supabase Storage (photos bucket) (002-building-management)
- Dart 3.x (Flutter SDK stable) + flutter_riverpod 2.4.x, go_router 13.x, freezed 2.4.x, supabase_flutter 2.x, image_picker 1.x (003-unit-management)
- Supabase PostgreSQL (units table) + Supabase Storage (photos bucket) (003-unit-management)
- Supabase PostgreSQL (tenants table) + Supabase Storage (documents bucket for ID documents) (004-tenant-management)
- Dart 3.x (Flutter SDK stable) + flutter_riverpod 2.6.x, go_router 14.x, freezed 2.5.x, supabase_flutter 2.8.x (005-lease-management)
- Supabase PostgreSQL (leases, rent_schedules tables) + existing profiles, buildings, units, tenants tables (005-lease-management)
- Dart 3.x with Flutter SDK (stable channel) + flutter_riverpod 2.6.x, go_router 14.x, freezed 2.5.x, supabase_flutter 2.8.x, intl (date/currency formatting) (006-payment-management)
- Supabase PostgreSQL with RLS - new `payments` table linking to existing `rent_schedules` (006-payment-management)
- Dart 3.x (Flutter SDK ^3.10.4, stable channel) + flutter_riverpod 2.6.x, go_router 14.x, supabase_flutter 2.8.x, intl 0.20.x (008-dashboard)
- Supabase PostgreSQL (existing tables: profiles, buildings, units, tenants, leases, rent_schedules, payments) (008-dashboard)

## Recent Changes
- 001-user-auth: Added Dart 3.x (Flutter SDK stable) + supabase_flutter, flutter_riverpod, go_router, freezed, flutter_secure_storage
