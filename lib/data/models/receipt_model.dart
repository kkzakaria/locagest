import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/receipt.dart';

part 'receipt_model.freezed.dart';
part 'receipt_model.g.dart';

/// Receipt model for Supabase serialization
@freezed
class ReceiptModel with _$ReceiptModel {
  const ReceiptModel._();

  const factory ReceiptModel({
    required String id,
    @JsonKey(name: 'payment_id') required String paymentId,
    @JsonKey(name: 'receipt_number') required String receiptNumber,
    @JsonKey(name: 'file_url') required String fileUrl,
    required String status,
    @JsonKey(name: 'generated_at') required DateTime generatedAt,
    @JsonKey(name: 'created_by') String? createdBy,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _ReceiptModel;

  factory ReceiptModel.fromJson(Map<String, dynamic> json) =>
      _$ReceiptModelFromJson(json);

  /// Convert to domain entity
  Receipt toEntity() => Receipt(
        id: id,
        paymentId: paymentId,
        receiptNumber: receiptNumber,
        fileUrl: fileUrl,
        status: ReceiptStatus.values.firstWhere(
          (e) => e.name == status,
          orElse: () => ReceiptStatus.valid,
        ),
        generatedAt: generatedAt,
        createdBy: createdBy,
        createdAt: createdAt,
      );
}

/// Input for creating a new receipt
@freezed
class CreateReceiptInput with _$CreateReceiptInput {
  const factory CreateReceiptInput({
    required String paymentId,
    required String receiptNumber,
    required String fileUrl,
  }) = _CreateReceiptInput;

  factory CreateReceiptInput.fromJson(Map<String, dynamic> json) =>
      _$CreateReceiptInputFromJson(json);
}
