import 'package:intl/intl.dart';

/// Status of a receipt
enum ReceiptStatus {
  valid,
  cancelled;

  String get displayName {
    switch (this) {
      case ReceiptStatus.valid:
        return 'Valide';
      case ReceiptStatus.cancelled:
        return 'Annulée';
    }
  }
}

/// Receipt entity representing a generated rent receipt (quittance)
class Receipt {
  final String id;
  final String paymentId;
  final String receiptNumber;
  final String fileUrl;
  final ReceiptStatus status;
  final DateTime generatedAt;
  final String? createdBy;
  final DateTime createdAt;

  const Receipt({
    required this.id,
    required this.paymentId,
    required this.receiptNumber,
    required this.fileUrl,
    required this.status,
    required this.generatedAt,
    this.createdBy,
    required this.createdAt,
  });

  /// Whether the receipt is valid
  bool get isValid => status == ReceiptStatus.valid;

  /// Whether the receipt is cancelled
  bool get isCancelled => status == ReceiptStatus.cancelled;

  /// Status label in French
  String get statusLabel => status.displayName;

  /// Formatted generation date (DD/MM/YYYY HH:mm)
  String get generatedAtFormatted {
    return DateFormat('dd/MM/yyyy HH:mm').format(generatedAt);
  }

  /// Formatted generation date (DD/MM/YYYY only)
  String get generatedAtDateOnly {
    return DateFormat('dd/MM/yyyy').format(generatedAt);
  }

  /// Copy with method for immutability
  Receipt copyWith({
    String? id,
    String? paymentId,
    String? receiptNumber,
    String? fileUrl,
    ReceiptStatus? status,
    DateTime? generatedAt,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return Receipt(
      id: id ?? this.id,
      paymentId: paymentId ?? this.paymentId,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      fileUrl: fileUrl ?? this.fileUrl,
      status: status ?? this.status,
      generatedAt: generatedAt ?? this.generatedAt,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Receipt && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Receipt(id: $id, receiptNumber: $receiptNumber, status: $status)';
  }
}
