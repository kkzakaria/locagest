import 'package:flutter/material.dart';

import 'tenant.dart';
import 'unit.dart';

/// Lease status enum representing the lifecycle of a rental contract.
enum LeaseStatus {
  /// Future lease, not yet active (start_date > today)
  pending,
  /// Currently running lease
  active,
  /// Ended early by user action
  terminated,
  /// End date passed naturally
  expired;

  /// Parse status from string (database value)
  static LeaseStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return LeaseStatus.pending;
      case 'active':
        return LeaseStatus.active;
      case 'terminated':
        return LeaseStatus.terminated;
      case 'expired':
        return LeaseStatus.expired;
      default:
        return LeaseStatus.active;
    }
  }

  /// Convert to string for database
  String toJson() => name;
}

/// Represents a rental contract (bail) between a tenant and a unit.
class Lease {
  final String id;
  final String unitId;
  final String tenantId;
  final DateTime startDate;
  final DateTime? endDate;
  final int? durationMonths;
  final double rentAmount;
  final double chargesAmount;
  final double? depositAmount;
  final bool depositPaid;
  final int paymentDay;
  final bool annualRevision;
  final double? revisionRate;
  final LeaseStatus status;
  final DateTime? terminationDate;
  final String? terminationReason;
  final String? documentUrl;
  final String? notes;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined entities (optional, loaded via queries)
  final Tenant? tenant;
  final Unit? unit;

  const Lease({
    required this.id,
    required this.unitId,
    required this.tenantId,
    required this.startDate,
    this.endDate,
    this.durationMonths,
    required this.rentAmount,
    this.chargesAmount = 0,
    this.depositAmount,
    this.depositPaid = false,
    this.paymentDay = 1,
    this.annualRevision = false,
    this.revisionRate,
    required this.status,
    this.terminationDate,
    this.terminationReason,
    this.documentUrl,
    this.notes,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.tenant,
    this.unit,
  });

  // ============================================================================
  // COMPUTED PROPERTIES
  // ============================================================================

  /// Total monthly amount (rent + charges)
  double get totalMonthlyAmount => rentAmount + chargesAmount;

  /// Whether lease is currently active
  bool get isActive => status == LeaseStatus.active;

  /// Whether lease is pending (future start)
  bool get isPending => status == LeaseStatus.pending;

  /// Whether lease can be terminated (only pending or active)
  bool get canBeTerminated =>
      status == LeaseStatus.pending || status == LeaseStatus.active;

  /// Whether lease can be edited (only pending or active)
  bool get canBeEdited =>
      status == LeaseStatus.pending || status == LeaseStatus.active;

  /// Whether lease can be deleted (only pending)
  bool get canBeDeleted => status == LeaseStatus.pending;

  /// Tenant full name (from joined entity)
  String get tenantFullName => tenant?.fullName ?? '';

  /// Unit reference (from joined entity)
  String get unitReference => unit?.reference ?? '';

  /// Building name (from joined unit)
  String get buildingName => unit?.buildingName ?? '';

  /// Full address: building name + unit reference
  String get fullAddress {
    if (buildingName.isNotEmpty && unitReference.isNotEmpty) {
      return '$buildingName - $unitReference';
    }
    return unitReference.isNotEmpty ? unitReference : buildingName;
  }

  // ============================================================================
  // FRENCH LABELS
  // ============================================================================

  /// French label for status
  String get statusLabel {
    switch (status) {
      case LeaseStatus.pending:
        return 'En attente';
      case LeaseStatus.active:
        return 'Actif';
      case LeaseStatus.terminated:
        return 'Résilié';
      case LeaseStatus.expired:
        return 'Expiré';
    }
  }

  /// Material color for status
  Color get statusColor {
    switch (status) {
      case LeaseStatus.pending:
        return Colors.orange;
      case LeaseStatus.active:
        return Colors.green;
      case LeaseStatus.terminated:
        return Colors.red;
      case LeaseStatus.expired:
        return Colors.grey;
    }
  }

  /// Duration label in French
  String get durationLabel {
    if (endDate == null) {
      return 'Durée indéterminée';
    }
    if (durationMonths != null) {
      return '$durationMonths mois';
    }
    // Calculate months between dates
    final months = (endDate!.year - startDate.year) * 12 +
        (endDate!.month - startDate.month);
    if (months == 1) {
      return '1 mois';
    }
    return '$months mois';
  }

  /// Deposit status label
  String get depositStatusLabel {
    if (depositAmount == null || depositAmount == 0) {
      return 'Pas de caution';
    }
    return depositPaid ? 'Caution payée' : 'Caution non payée';
  }

  /// Deposit status color
  Color get depositStatusColor {
    if (depositAmount == null || depositAmount == 0) {
      return Colors.grey;
    }
    return depositPaid ? Colors.green : Colors.orange;
  }

  // ============================================================================
  // COPY WITH
  // ============================================================================

  Lease copyWith({
    String? id,
    String? unitId,
    String? tenantId,
    DateTime? startDate,
    DateTime? endDate,
    int? durationMonths,
    double? rentAmount,
    double? chargesAmount,
    double? depositAmount,
    bool? depositPaid,
    int? paymentDay,
    bool? annualRevision,
    double? revisionRate,
    LeaseStatus? status,
    DateTime? terminationDate,
    String? terminationReason,
    String? documentUrl,
    String? notes,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    Tenant? tenant,
    Unit? unit,
  }) {
    return Lease(
      id: id ?? this.id,
      unitId: unitId ?? this.unitId,
      tenantId: tenantId ?? this.tenantId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      durationMonths: durationMonths ?? this.durationMonths,
      rentAmount: rentAmount ?? this.rentAmount,
      chargesAmount: chargesAmount ?? this.chargesAmount,
      depositAmount: depositAmount ?? this.depositAmount,
      depositPaid: depositPaid ?? this.depositPaid,
      paymentDay: paymentDay ?? this.paymentDay,
      annualRevision: annualRevision ?? this.annualRevision,
      revisionRate: revisionRate ?? this.revisionRate,
      status: status ?? this.status,
      terminationDate: terminationDate ?? this.terminationDate,
      terminationReason: terminationReason ?? this.terminationReason,
      documentUrl: documentUrl ?? this.documentUrl,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tenant: tenant ?? this.tenant,
      unit: unit ?? this.unit,
    );
  }

  // ============================================================================
  // EQUALITY
  // ============================================================================

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Lease &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          unitId == other.unitId &&
          tenantId == other.tenantId &&
          startDate == other.startDate &&
          status == other.status;

  @override
  int get hashCode =>
      id.hashCode ^
      unitId.hashCode ^
      tenantId.hashCode ^
      startDate.hashCode ^
      status.hashCode;

  @override
  String toString() =>
      'Lease{id: $id, tenant: $tenantFullName, unit: $unitReference, status: $statusLabel}';
}
