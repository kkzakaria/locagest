import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/rent_schedule.dart';

part 'rent_schedule_model.freezed.dart';
part 'rent_schedule_model.g.dart';

/// RentScheduleModel for Supabase rent_schedules table (Data layer)
@freezed
class RentScheduleModel with _$RentScheduleModel {
  const RentScheduleModel._();

  const factory RentScheduleModel({
    required String id,
    @JsonKey(name: 'lease_id') required String leaseId,
    @JsonKey(name: 'due_date') required DateTime dueDate,
    @JsonKey(name: 'period_start') required DateTime periodStart,
    @JsonKey(name: 'period_end') required DateTime periodEnd,
    @JsonKey(name: 'amount_due') required double amountDue,
    @JsonKey(name: 'amount_paid') @Default(0) double amountPaid,
    @JsonKey(name: 'balance') required double balance,
    required String status,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _RentScheduleModel;

  factory RentScheduleModel.fromJson(Map<String, dynamic> json) =>
      _$RentScheduleModelFromJson(json);

  /// Convert to domain entity
  RentSchedule toEntity() => RentSchedule(
        id: id,
        leaseId: leaseId,
        dueDate: dueDate,
        periodStart: periodStart,
        periodEnd: periodEnd,
        amountDue: amountDue,
        amountPaid: amountPaid,
        balance: balance,
        status: RentScheduleStatus.fromString(status),
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

/// Extension to create RentScheduleModel from RentSchedule entity
extension RentScheduleModelFromEntity on RentSchedule {
  RentScheduleModel toModel() {
    return RentScheduleModel(
      id: id,
      leaseId: leaseId,
      dueDate: dueDate,
      periodStart: periodStart,
      periodEnd: periodEnd,
      amountDue: amountDue,
      amountPaid: amountPaid,
      balance: balance,
      status: status.toJson(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Input model for recording a payment on a rent schedule
@freezed
class RecordPaymentInput with _$RecordPaymentInput {
  const factory RecordPaymentInput({
    required double amount,
    @JsonKey(name: 'payment_date') required String paymentDate,
    @JsonKey(name: 'payment_method') String? paymentMethod,
    String? reference,
    String? notes,
  }) = _RecordPaymentInput;

  factory RecordPaymentInput.fromJson(Map<String, dynamic> json) =>
      _$RecordPaymentInputFromJson(json);
}
