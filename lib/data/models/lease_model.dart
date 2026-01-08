import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/lease.dart';
import 'tenant_model.dart';
import 'unit_model.dart';

part 'lease_model.freezed.dart';
part 'lease_model.g.dart';

/// LeaseModel for Supabase leases table (Data layer)
@freezed
class LeaseModel with _$LeaseModel {
  const LeaseModel._();

  const factory LeaseModel({
    required String id,
    @JsonKey(name: 'unit_id') required String unitId,
    @JsonKey(name: 'tenant_id') required String tenantId,
    @JsonKey(name: 'start_date') required DateTime startDate,
    @JsonKey(name: 'end_date') DateTime? endDate,
    @JsonKey(name: 'duration_months') int? durationMonths,
    @JsonKey(name: 'rent_amount') required double rentAmount,
    @JsonKey(name: 'charges_amount') @Default(0) double chargesAmount,
    @JsonKey(name: 'deposit_amount') double? depositAmount,
    @JsonKey(name: 'deposit_paid') @Default(false) bool depositPaid,
    @JsonKey(name: 'payment_day') @Default(1) int paymentDay,
    @JsonKey(name: 'annual_revision') @Default(false) bool annualRevision,
    @JsonKey(name: 'revision_rate') double? revisionRate,
    required String status,
    @JsonKey(name: 'termination_date') DateTime? terminationDate,
    @JsonKey(name: 'termination_reason') String? terminationReason,
    @JsonKey(name: 'document_url') String? documentUrl,
    String? notes,
    @JsonKey(name: 'created_by') String? createdBy,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    // Joined data (from nested queries)
    TenantModel? tenant,
    UnitModel? unit,
  }) = _LeaseModel;

  factory LeaseModel.fromJson(Map<String, dynamic> json) =>
      _$LeaseModelFromJson(json);

  /// Convert to domain entity
  Lease toEntity() => Lease(
        id: id,
        unitId: unitId,
        tenantId: tenantId,
        startDate: startDate,
        endDate: endDate,
        durationMonths: durationMonths,
        rentAmount: rentAmount,
        chargesAmount: chargesAmount,
        depositAmount: depositAmount,
        depositPaid: depositPaid,
        paymentDay: paymentDay,
        annualRevision: annualRevision,
        revisionRate: revisionRate,
        status: LeaseStatus.fromString(status),
        terminationDate: terminationDate,
        terminationReason: terminationReason,
        documentUrl: documentUrl,
        notes: notes,
        createdBy: createdBy,
        createdAt: createdAt,
        updatedAt: updatedAt,
        tenant: tenant?.toEntity(),
        unit: unit?.toEntity(),
      );
}

/// Extension to create LeaseModel from Lease entity
extension LeaseModelFromEntity on Lease {
  LeaseModel toModel() {
    return LeaseModel(
      id: id,
      unitId: unitId,
      tenantId: tenantId,
      startDate: startDate,
      endDate: endDate,
      durationMonths: durationMonths,
      rentAmount: rentAmount,
      chargesAmount: chargesAmount,
      depositAmount: depositAmount,
      depositPaid: depositPaid,
      paymentDay: paymentDay,
      annualRevision: annualRevision,
      revisionRate: revisionRate,
      status: status.toJson(),
      terminationDate: terminationDate,
      terminationReason: terminationReason,
      documentUrl: documentUrl,
      notes: notes,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Input model for creating a new lease (no id, timestamps)
@freezed
class CreateLeaseInput with _$CreateLeaseInput {
  const factory CreateLeaseInput({
    @JsonKey(name: 'unit_id') required String unitId,
    @JsonKey(name: 'tenant_id') required String tenantId,
    @JsonKey(name: 'start_date') required String startDate, // ISO date string
    @JsonKey(name: 'end_date') String? endDate,
    @JsonKey(name: 'duration_months') int? durationMonths,
    @JsonKey(name: 'rent_amount') required double rentAmount,
    @JsonKey(name: 'charges_amount') double? chargesAmount,
    @JsonKey(name: 'deposit_amount') double? depositAmount,
    @JsonKey(name: 'deposit_paid') bool? depositPaid,
    @JsonKey(name: 'payment_day') int? paymentDay,
    @JsonKey(name: 'annual_revision') bool? annualRevision,
    @JsonKey(name: 'revision_rate') double? revisionRate,
    String? status,
    String? notes,
  }) = _CreateLeaseInput;

  factory CreateLeaseInput.fromJson(Map<String, dynamic> json) =>
      _$CreateLeaseInputFromJson(json);
}

/// Input model for updating an existing lease
@freezed
class UpdateLeaseInput with _$UpdateLeaseInput {
  const UpdateLeaseInput._();

  const factory UpdateLeaseInput({
    @JsonKey(name: 'end_date') String? endDate,
    @JsonKey(name: 'rent_amount') double? rentAmount,
    @JsonKey(name: 'charges_amount') double? chargesAmount,
    @JsonKey(name: 'deposit_amount') double? depositAmount,
    @JsonKey(name: 'deposit_paid') bool? depositPaid,
    @JsonKey(name: 'annual_revision') bool? annualRevision,
    @JsonKey(name: 'revision_rate') double? revisionRate,
    String? notes,
  }) = _UpdateLeaseInput;

  factory UpdateLeaseInput.fromJson(Map<String, dynamic> json) =>
      _$UpdateLeaseInputFromJson(json);

  /// Convert to Map with only non-null fields for Supabase update
  Map<String, dynamic> toUpdateMap() {
    final map = <String, dynamic>{};
    if (endDate != null) map['end_date'] = endDate;
    if (rentAmount != null) map['rent_amount'] = rentAmount;
    if (chargesAmount != null) map['charges_amount'] = chargesAmount;
    if (depositAmount != null) map['deposit_amount'] = depositAmount;
    if (depositPaid != null) map['deposit_paid'] = depositPaid;
    if (annualRevision != null) map['annual_revision'] = annualRevision;
    if (revisionRate != null) map['revision_rate'] = revisionRate;
    if (notes != null) map['notes'] = notes;
    return map;
  }
}

/// Input model for terminating a lease
@freezed
class TerminateLeaseInput with _$TerminateLeaseInput {
  const factory TerminateLeaseInput({
    @JsonKey(name: 'termination_date') required String terminationDate,
    @JsonKey(name: 'termination_reason') required String terminationReason,
  }) = _TerminateLeaseInput;

  factory TerminateLeaseInput.fromJson(Map<String, dynamic> json) =>
      _$TerminateLeaseInputFromJson(json);
}
