import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/payment.dart';

part 'payment_model.freezed.dart';
part 'payment_model.g.dart';

/// PaymentModel for Supabase payments table (Data layer)
@freezed
class PaymentModel with _$PaymentModel {
  const PaymentModel._();

  const factory PaymentModel({
    required String id,
    @JsonKey(name: 'rent_schedule_id') required String rentScheduleId,
    required double amount,
    @JsonKey(name: 'payment_date') required DateTime paymentDate,
    @JsonKey(name: 'payment_method') required String paymentMethod,
    String? reference,
    @JsonKey(name: 'check_number') String? checkNumber,
    @JsonKey(name: 'bank_name') String? bankName,
    @JsonKey(name: 'receipt_number') required String receiptNumber,
    String? notes,
    @JsonKey(name: 'created_by') String? createdBy,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _PaymentModel;

  factory PaymentModel.fromJson(Map<String, dynamic> json) =>
      _$PaymentModelFromJson(json);

  /// Convert to domain entity
  Payment toEntity() => Payment(
        id: id,
        rentScheduleId: rentScheduleId,
        amount: amount,
        paymentDate: paymentDate,
        paymentMethod: PaymentMethod.fromString(paymentMethod),
        reference: reference,
        checkNumber: checkNumber,
        bankName: bankName,
        receiptNumber: receiptNumber,
        notes: notes,
        createdBy: createdBy,
        createdAt: createdAt,
      );
}

/// Extension to create PaymentModel from Payment entity
extension PaymentModelFromEntity on Payment {
  PaymentModel toModel() {
    return PaymentModel(
      id: id,
      rentScheduleId: rentScheduleId,
      amount: amount,
      paymentDate: paymentDate,
      paymentMethod: paymentMethod.toJson(),
      reference: reference,
      checkNumber: checkNumber,
      bankName: bankName,
      receiptNumber: receiptNumber,
      notes: notes,
      createdBy: createdBy,
      createdAt: createdAt,
    );
  }
}
