import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/expiring_lease.dart';

part 'expiring_lease_model.freezed.dart';
part 'expiring_lease_model.g.dart';

/// Expiring lease model for data layer (Freezed)
/// Handles JSON serialization from Supabase queries
@freezed
class ExpiringLeaseModel with _$ExpiringLeaseModel {
  const factory ExpiringLeaseModel({
    @JsonKey(name: 'lease_id') required String leaseId,
    @JsonKey(name: 'tenant_name') required String tenantName,
    @JsonKey(name: 'unit_reference') required String unitReference,
    @JsonKey(name: 'building_name') required String buildingName,
    @JsonKey(name: 'end_date') required DateTime endDate,
    @JsonKey(name: 'days_remaining') required int daysRemaining,
    @JsonKey(name: 'monthly_rent') required double monthlyRent,
  }) = _ExpiringLeaseModel;

  factory ExpiringLeaseModel.fromJson(Map<String, dynamic> json) =>
      _$ExpiringLeaseModelFromJson(json);
}

/// Extension for converting model to domain entity
extension ExpiringLeaseModelX on ExpiringLeaseModel {
  ExpiringLease toEntity() => ExpiringLease(
        leaseId: leaseId,
        tenantName: tenantName,
        unitReference: unitReference,
        buildingName: buildingName,
        endDate: endDate,
        daysRemaining: daysRemaining,
        monthlyRent: monthlyRent,
      );
}
