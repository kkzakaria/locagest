# Lease Repository Contract

**Feature**: 005-lease-management
**Type**: Repository Interface
**Date**: 2026-01-08

## Overview

Defines the contract for lease data operations following the repository pattern. Implementation will use Supabase as the data source.

---

## Interface Definition

```dart
/// Repository interface for lease (bail) operations.
///
/// All methods throw domain-specific exceptions:
/// - [LeaseNotFoundException] when lease not found
/// - [LeaseValidationException] for invalid data
/// - [LeaseUnauthorizedException] for permission errors
/// - [LeaseUnitOccupiedException] when unit has active lease
abstract class LeaseRepository {

  // ============================================================================
  // CRUD OPERATIONS
  // ============================================================================

  /// Creates a new lease linking a tenant to a unit.
  ///
  /// - Validates unit is not already occupied
  /// - Updates unit status to 'occupied' (for active leases)
  /// - Generates rent schedules automatically
  ///
  /// Throws [LeaseUnitOccupiedException] if unit has active/pending lease.
  /// Throws [LeaseValidationException] if data is invalid.
  /// Returns the created lease with generated schedules.
  Future<Lease> createLease({
    required String unitId,
    required String tenantId,
    required DateTime startDate,
    DateTime? endDate,
    int? durationMonths,
    required double rentAmount,
    double chargesAmount = 0,
    double? depositAmount,
    bool depositPaid = false,
    int paymentDay = 1,
    bool annualRevision = false,
    double? revisionRate,
    String? notes,
  });

  /// Retrieves all leases with pagination and optional filters.
  ///
  /// [page] starts at 1
  /// [limit] defaults to 20
  /// [status] filter by lease status (null = all)
  /// [buildingId] filter by building (via unit)
  ///
  /// Returns leases with joined tenant and unit data.
  Future<List<Lease>> getLeases({
    int page = 1,
    int limit = 20,
    LeaseStatus? status,
    String? buildingId,
  });

  /// Retrieves a single lease by ID.
  ///
  /// Throws [LeaseNotFoundException] if not found.
  /// Returns lease with joined tenant, unit, and schedules.
  Future<Lease> getLeaseById(String id);

  /// Updates an existing lease.
  ///
  /// Only provided fields will be updated.
  /// Cannot change tenant or unit - must terminate and create new lease.
  ///
  /// Throws [LeaseNotFoundException] if not found.
  /// Throws [LeaseValidationException] if data is invalid.
  /// Returns the updated lease.
  Future<Lease> updateLease({
    required String id,
    DateTime? endDate,
    double? rentAmount,
    double? chargesAmount,
    bool? depositPaid,
    bool? annualRevision,
    double? revisionRate,
    String? notes,
  });

  /// Deletes a lease (soft delete or hard delete based on status).
  ///
  /// Only pending leases can be deleted.
  /// Active/terminated/expired leases are preserved for records.
  ///
  /// Throws [LeaseNotFoundException] if not found.
  /// Throws [LeaseCannotBeDeletedException] if not pending.
  Future<void> deleteLease(String id);

  // ============================================================================
  // TERMINATION
  // ============================================================================

  /// Terminates an active or pending lease.
  ///
  /// - Sets status to 'terminated'
  /// - Records termination date and reason
  /// - Updates unit status to 'vacant'
  /// - Cancels future unpaid rent schedules
  ///
  /// [terminationDate] defaults to today if not provided.
  ///
  /// Throws [LeaseNotFoundException] if not found.
  /// Throws [LeaseCannotBeTerminatedException] if already terminated/expired.
  Future<Lease> terminateLease({
    required String id,
    DateTime? terminationDate,
    required String terminationReason,
  });

  // ============================================================================
  // QUERIES
  // ============================================================================

  /// Gets all leases for a specific tenant.
  ///
  /// Returns list ordered by start_date descending (newest first).
  Future<List<Lease>> getLeasesForTenant(String tenantId);

  /// Gets lease history for a specific unit.
  ///
  /// Returns list ordered by start_date descending (newest first).
  Future<List<Lease>> getLeasesForUnit(String unitId);

  /// Gets the active or pending lease for a unit (if any).
  ///
  /// Returns null if unit is vacant.
  Future<Lease?> getActiveLeaseForUnit(String unitId);

  /// Searches leases by tenant name or unit reference.
  ///
  /// [query] searches in tenant first_name, last_name, and unit reference.
  /// Returns up to 50 results.
  Future<List<Lease>> searchLeases(String query);

  /// Gets count of leases by status.
  ///
  /// Returns map of status -> count.
  Future<Map<LeaseStatus, int>> getLeaseCountsByStatus();

  // ============================================================================
  // RENT SCHEDULES
  // ============================================================================

  /// Gets all rent schedules for a lease.
  ///
  /// Returns list ordered by due_date ascending.
  Future<List<RentSchedule>> getRentSchedulesForLease(String leaseId);

  /// Gets rent schedules summary for a lease.
  ///
  /// Returns counts and totals for dashboard display.
  Future<RentSchedulesSummary> getRentSchedulesSummary(String leaseId);

  /// Generates additional rent schedules for an extended lease.
  ///
  /// Called when end_date is extended.
  /// [fromDate] start generating from this date (exclusive).
  /// [toDate] generate up to this date (inclusive).
  Future<List<RentSchedule>> generateAdditionalSchedules({
    required String leaseId,
    required DateTime fromDate,
    required DateTime toDate,
  });

  // ============================================================================
  // VALIDATION
  // ============================================================================

  /// Checks if a unit can have a new lease.
  ///
  /// Returns true if unit exists, is vacant (or maintenance), and has no active lease.
  Future<bool> canCreateLeaseForUnit(String unitId);

  /// Checks if current user can manage leases.
  ///
  /// Returns true for admin and gestionnaire roles.
  Future<bool> canManageLeases();
}
```

---

## Data Transfer Objects

### RentSchedulesSummary

```dart
/// Summary of rent schedules for dashboard display.
class RentSchedulesSummary {
  final int totalSchedules;
  final int paidCount;
  final int pendingCount;
  final int overdueCount;
  final int partialCount;
  final double totalDue;
  final double totalPaid;
  final double totalBalance;

  const RentSchedulesSummary({
    required this.totalSchedules,
    required this.paidCount,
    required this.pendingCount,
    required this.overdueCount,
    required this.partialCount,
    required this.totalDue,
    required this.totalPaid,
    required this.totalBalance,
  });
}
```

---

## Exception Hierarchy

```dart
/// Base exception for lease operations.
abstract class LeaseException implements Exception {
  final String message;
  const LeaseException(this.message);

  @override
  String toString() => message;
}

/// Lease not found in database.
class LeaseNotFoundException extends LeaseException {
  const LeaseNotFoundException() : super('Bail non trouvé');
}

/// User doesn't have permission for this operation.
class LeaseUnauthorizedException extends LeaseException {
  const LeaseUnauthorizedException()
      : super('Vous n\'avez pas la permission d\'effectuer cette action');
}

/// Validation error (invalid data).
class LeaseValidationException extends LeaseException {
  const LeaseValidationException(super.message);
}

/// Unit already has an active or pending lease.
class LeaseUnitOccupiedException extends LeaseException {
  const LeaseUnitOccupiedException()
      : super('Ce lot a déjà un bail actif');
}

/// Lease cannot be terminated (already terminated or expired).
class LeaseCannotBeTerminatedException extends LeaseException {
  const LeaseCannotBeTerminatedException()
      : super('Ce bail ne peut pas être résilié');
}

/// Lease cannot be deleted (not in pending status).
class LeaseCannotBeDeletedException extends LeaseException {
  const LeaseCannotBeDeletedException()
      : super('Seuls les baux en attente peuvent être supprimés');
}
```

---

## Usage Examples

### Create Lease
```dart
final lease = await leaseRepository.createLease(
  unitId: 'unit-uuid',
  tenantId: 'tenant-uuid',
  startDate: DateTime(2026, 2, 1),
  endDate: DateTime(2027, 1, 31),
  rentAmount: 150000,
  chargesAmount: 15000,
  depositAmount: 300000,
  paymentDay: 5,
);
// Lease created with 12 rent schedules
```

### Terminate Lease
```dart
final terminatedLease = await leaseRepository.terminateLease(
  id: 'lease-uuid',
  terminationDate: DateTime.now(),
  terminationReason: 'Départ du locataire',
);
// Unit status updated to 'vacant'
// Future schedules cancelled
```

### Get Lease with Summary
```dart
final lease = await leaseRepository.getLeaseById('lease-uuid');
final summary = await leaseRepository.getRentSchedulesSummary('lease-uuid');
print('Payé: ${summary.totalPaid} / ${summary.totalDue}');
print('En retard: ${summary.overdueCount}');
```
