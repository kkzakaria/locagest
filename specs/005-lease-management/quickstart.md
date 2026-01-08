# Quickstart: Module Baux (Lease Management)

**Feature**: 005-lease-management
**Date**: 2026-01-08

## Prerequisites

Before starting implementation, ensure:

1. **Phase 5 (Units) complete**: Unit module with status management
2. **Phase 6 (Tenants) complete**: Tenant module with CRUD operations
3. **Development environment ready**:
   ```bash
   flutter --version  # Dart 3.x required
   flutter pub get
   ```

---

## Implementation Order

```
1. Database Migration (005_leases.sql)
       ↓
2. Domain Layer (entities, repository interface)
       ↓
3. Data Layer (models, datasource, repository impl)
       ↓
4. Presentation Layer (providers → pages → widgets)
       ↓
5. Integration (tenant/unit detail pages)
       ↓
6. Router Update (routes)
```

---

## Step 1: Database Migration

Create `supabase/migrations/005_leases.sql`:

```sql
-- See data-model.md for complete schema
-- Key tables: leases, rent_schedules
-- Includes: RLS policies, indexes, triggers
```

Apply migration via Supabase dashboard or CLI.

---

## Step 2: Domain Layer

### 2.1 Create Entities

**`lib/domain/entities/lease.dart`**:
```dart
enum LeaseStatus { pending, active, terminated, expired }

class Lease {
  final String id;
  final String unitId;
  final String tenantId;
  final DateTime startDate;
  final DateTime? endDate;
  final double rentAmount;
  final double chargesAmount;
  final LeaseStatus status;
  // ... other fields

  double get totalMonthlyAmount => rentAmount + chargesAmount;
  String get statusLabel => _statusLabels[status]!;
  // ... computed properties
}
```

**`lib/domain/entities/rent_schedule.dart`**:
```dart
enum RentScheduleStatus { pending, partial, paid, overdue, cancelled }

class RentSchedule {
  final String id;
  final String leaseId;
  final DateTime dueDate;
  final double amountDue;
  final double amountPaid;
  final RentScheduleStatus status;
  // ...
}
```

### 2.2 Create Repository Interface

**`lib/domain/repositories/lease_repository.dart`**:
```dart
abstract class LeaseRepository {
  Future<Lease> createLease({...});
  Future<List<Lease>> getLeases({...});
  Future<Lease> getLeaseById(String id);
  Future<Lease> updateLease({...});
  Future<Lease> terminateLease({...});
  // See contracts/lease-repository.md for full interface
}
```

### 2.3 Create Exceptions

**`lib/core/errors/lease_exceptions.dart`**:
```dart
abstract class LeaseException implements Exception {...}
class LeaseNotFoundException extends LeaseException {...}
class LeaseUnitOccupiedException extends LeaseException {...}
// See contracts/lease-repository.md for full list
```

---

## Step 3: Data Layer

### 3.1 Create Models

**`lib/data/models/lease_model.dart`**:
```dart
@freezed
class LeaseModel with _$LeaseModel {
  // Main model, CreateLeaseInput, UpdateLeaseInput
  // See data-model.md for complete structure
}
```

**`lib/data/models/rent_schedule_model.dart`**:
```dart
@freezed
class RentScheduleModel with _$RentScheduleModel {...}
```

Generate code:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3.2 Create Datasource

**`lib/data/datasources/lease_remote_datasource.dart`**:
```dart
class LeaseRemoteDatasource {
  final SupabaseClient _supabase;

  Future<LeaseModel> createLease(CreateLeaseInput input) async {
    // Insert lease
    // Update unit status
    // Generate rent schedules
    // Return created lease with schedules
  }

  Future<List<LeaseModel>> getLeases({...}) async {...}
  Future<LeaseModel> getLeaseById(String id) async {...}
  // ...
}
```

### 3.3 Create Repository Implementation

**`lib/data/repositories/lease_repository_impl.dart`**:
```dart
class LeaseRepositoryImpl implements LeaseRepository {
  final LeaseRemoteDatasource _datasource;

  @override
  Future<Lease> createLease({...}) async {
    final input = CreateLeaseInput(...);
    final model = await _datasource.createLease(input);
    return model.toEntity();
  }
  // ...
}
```

---

## Step 4: Presentation Layer

### 4.1 Create Providers

**`lib/presentation/providers/leases_provider.dart`**:
```dart
// Dependency providers
final leaseDatasourceProvider = Provider<LeaseRemoteDatasource>(...);
final leaseRepositoryProvider = Provider<LeaseRepository>(...);

// State classes
class LeasesState {...}
class CreateLeaseState {...}
class TerminateLeaseState {...}

// Notifiers
class LeasesNotifier extends StateNotifier<LeasesState> {...}
class CreateLeaseNotifier extends StateNotifier<CreateLeaseState> {...}
class TerminateLeaseNotifier extends StateNotifier<TerminateLeaseState> {...}

// Providers
final leasesProvider = StateNotifierProvider<LeasesNotifier, LeasesState>(...);
final leaseByIdProvider = FutureProvider.family<Lease, String>(...);
final createLeaseProvider = StateNotifierProvider<CreateLeaseNotifier, CreateLeaseState>(...);
// See contracts/lease-providers.md for full list
```

### 4.2 Create Pages

**`lib/presentation/pages/leases/leases_list_page.dart`**:
```dart
class LeasesListPage extends ConsumerWidget {
  // AppBar with search
  // Filter chips (status)
  // ListView with LeaseCard
  // FAB for new lease (if can manage)
  // Pagination support
}
```

**`lib/presentation/pages/leases/lease_form_page.dart`**:
```dart
class LeaseFormPage extends ConsumerStatefulWidget {
  final String? preselectedUnitId;
  final String? preselectedTenantId;

  // Tenant picker (searchable dropdown)
  // Unit picker (filter by vacant, searchable)
  // Date pickers (start, end)
  // Amount fields (rent, charges, deposit)
  // Payment day dropdown (1-28)
  // Annual revision toggle
  // Notes field
  // Submit button
}
```

**`lib/presentation/pages/leases/lease_detail_page.dart`**:
```dart
class LeaseDetailPage extends ConsumerWidget {
  // Header with status badge
  // Tenant info section
  // Unit info section
  // Financial info (rent, charges, deposit)
  // Dates section
  // Rent schedules summary
  // Rent schedules list
  // Action buttons (edit, terminate)
}
```

**`lib/presentation/pages/leases/lease_edit_page.dart`**:
```dart
class LeaseEditPage extends ConsumerStatefulWidget {
  // Pre-filled form with current values
  // Cannot change tenant/unit
  // Can update: rent, charges, end_date, deposit_paid, notes
}
```

### 4.3 Create Widgets

**`lib/presentation/widgets/leases/`**:
- `lease_card.dart` - List item with key info
- `lease_status_badge.dart` - Colored status chip
- `lease_form_fields.dart` - Reusable form inputs
- `lease_section.dart` - For embedding in tenant/unit detail
- `termination_modal.dart` - Confirmation dialog

---

## Step 5: Integration

### 5.1 Update Tenant Detail Page

Add lease section to `tenant_detail_page.dart`:
```dart
// After existing sections
LeaseSection(
  title: 'Baux',
  leases: ref.watch(leasesForTenantProvider(tenant.id)),
  onNewLease: () => context.goToNewLeaseForTenant(tenant.id),
  canCreate: canManage,
),
```

### 5.2 Update Unit Detail Page

Add lease section to `unit_detail_page.dart`:
```dart
// Show active lease if occupied
final activeLease = ref.watch(activeLeaseForUnitProvider(unit.id));
if (activeLease.hasValue && activeLease.value != null) {
  ActiveLeaseCard(lease: activeLease.value!),
}

// Historical leases
LeaseSection(
  title: 'Historique des baux',
  leases: ref.watch(leasesForUnitProvider(unit.id)),
  onNewLease: unit.status == 'vacant'
      ? () => context.goToNewLeaseForUnit(unit.id)
      : null,
),
```

---

## Step 6: Router Update

Update `lib/core/router/app_router.dart`:
```dart
// Add route constants
static const String leases = '/leases';
static const String leaseNew = '/leases/new';
static const String leaseDetail = '/leases/:id';
static const String leaseEdit = '/leases/:id/edit';
static const String unitLeaseNew = '/units/:unitId/leases/new';
static const String tenantLeaseNew = '/tenants/:tenantId/leases/new';

// Add routes to GoRouter
GoRoute(path: leases, name: 'leases', builder: ...),
GoRoute(path: leaseNew, name: 'lease-new', builder: ...),
// ... see contracts/lease-routes.md
```

---

## Testing Checklist

After implementation, verify:

- [ ] Create lease for vacant unit
- [ ] Cannot create lease for occupied unit
- [ ] Rent schedules generated correctly
- [ ] Unit status updates to "occupied"
- [ ] View lease from tenant detail
- [ ] View lease from unit detail
- [ ] Edit lease (rent amount, end date)
- [ ] Terminate lease
- [ ] Unit status updates to "vacant" after termination
- [ ] Future schedules cancelled on termination
- [ ] Search leases by tenant name
- [ ] Filter leases by status
- [ ] Role-based access (assistant cannot create/edit)
- [ ] French labels and FCFA formatting

---

## Key Files Created

```
lib/
├── core/errors/lease_exceptions.dart
├── data/
│   ├── datasources/lease_remote_datasource.dart
│   ├── models/
│   │   ├── lease_model.dart
│   │   ├── lease_model.freezed.dart
│   │   ├── lease_model.g.dart
│   │   ├── rent_schedule_model.dart
│   │   ├── rent_schedule_model.freezed.dart
│   │   └── rent_schedule_model.g.dart
│   └── repositories/lease_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── lease.dart
│   │   └── rent_schedule.dart
│   └── repositories/lease_repository.dart
└── presentation/
    ├── pages/leases/
    │   ├── leases_list_page.dart
    │   ├── lease_form_page.dart
    │   ├── lease_detail_page.dart
    │   └── lease_edit_page.dart
    ├── providers/leases_provider.dart
    └── widgets/leases/
        ├── lease_card.dart
        ├── lease_status_badge.dart
        ├── lease_form_fields.dart
        ├── lease_section.dart
        └── termination_modal.dart

supabase/migrations/
└── 005_leases.sql
```

---

## Common Issues

### "Ce lot a déjà un bail actif"
- Check that unit status is 'vacant' before creating lease
- Verify no existing lease with status 'active' or 'pending' for that unit

### Rent schedules not generated
- Verify `generateRentSchedules()` is called in `createLease()`
- Check start_date and end_date are valid

### Unit status not updating
- Ensure transaction includes unit status update
- Check RLS policies allow unit updates

### Generated files missing
- Run `flutter pub run build_runner build --delete-conflicting-outputs`
- Check for syntax errors in Freezed classes
