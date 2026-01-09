import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/overdue_rent.dart';

part 'overdue_rent_model.freezed.dart';
part 'overdue_rent_model.g.dart';

/// Overdue rent model for data layer (Freezed)
/// Handles JSON serialization from Supabase queries
@freezed
class OverdueRentModel with _$OverdueRentModel {
  const factory OverdueRentModel({
    @JsonKey(name: 'schedule_id') required String scheduleId,
    @JsonKey(name: 'lease_id') required String leaseId,
    @JsonKey(name: 'tenant_name') required String tenantName,
    @JsonKey(name: 'unit_reference') required String unitReference,
    @JsonKey(name: 'building_name') required String buildingName,
    @JsonKey(name: 'due_date') required DateTime dueDate,
    @JsonKey(name: 'amount_due') required double amountDue,
    @JsonKey(name: 'amount_paid') @Default(0.0) double amountPaid,
    @JsonKey(name: 'days_overdue') required int daysOverdue,
  }) = _OverdueRentModel;

  factory OverdueRentModel.fromJson(Map<String, dynamic> json) =>
      _$OverdueRentModelFromJson(json);
}

/// Extension for converting model to domain entity
extension OverdueRentModelX on OverdueRentModel {
  OverdueRent toEntity() => OverdueRent(
        scheduleId: scheduleId,
        leaseId: leaseId,
        tenantName: tenantName,
        unitReference: unitReference,
        buildingName: buildingName,
        dueDate: dueDate,
        amountDue: amountDue,
        amountPaid: amountPaid,
        daysOverdue: daysOverdue,
      );
}
