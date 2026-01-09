import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Payment method enumeration
enum PaymentMethod {
  cash,
  check,
  transfer,
  mobileMoney;

  /// Parse payment method from database string
  static PaymentMethod fromString(String value) {
    switch (value) {
      case 'cash':
        return PaymentMethod.cash;
      case 'check':
        return PaymentMethod.check;
      case 'transfer':
        return PaymentMethod.transfer;
      case 'mobile_money':
        return PaymentMethod.mobileMoney;
      default:
        return PaymentMethod.cash;
    }
  }

  /// Convert to database string
  String toJson() {
    switch (this) {
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.check:
        return 'check';
      case PaymentMethod.transfer:
        return 'transfer';
      case PaymentMethod.mobileMoney:
        return 'mobile_money';
    }
  }

  /// French label for display
  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'Especes';
      case PaymentMethod.check:
        return 'Cheque';
      case PaymentMethod.transfer:
        return 'Virement bancaire';
      case PaymentMethod.mobileMoney:
        return 'Mobile Money';
    }
  }

  /// Icon for display
  IconData get icon {
    switch (this) {
      case PaymentMethod.cash:
        return Icons.money;
      case PaymentMethod.check:
        return Icons.receipt_long;
      case PaymentMethod.transfer:
        return Icons.account_balance;
      case PaymentMethod.mobileMoney:
        return Icons.phone_android;
    }
  }
}

/// Payment entity representing a rent payment transaction
class Payment {
  final String id;
  final String rentScheduleId;
  final double amount;
  final DateTime paymentDate;
  final PaymentMethod paymentMethod;
  final String? reference;
  final String? checkNumber;
  final String? bankName;
  final String receiptNumber;
  final String? notes;
  final String? createdBy;
  final DateTime createdAt;

  const Payment({
    required this.id,
    required this.rentScheduleId,
    required this.amount,
    required this.paymentDate,
    required this.paymentMethod,
    this.reference,
    this.checkNumber,
    this.bankName,
    required this.receiptNumber,
    this.notes,
    this.createdBy,
    required this.createdAt,
  });

  /// Formatted amount with FCFA currency (e.g., "150 000 FCFA")
  String get amountFormatted {
    final formatter = NumberFormat('#,###', 'fr_FR');
    return '${formatter.format(amount.round())} FCFA';
  }

  /// Formatted payment date (DD/MM/YYYY)
  String get paymentDateFormatted {
    return DateFormat('dd/MM/yyyy').format(paymentDate);
  }

  /// French label for payment method
  String get methodLabel => paymentMethod.label;

  /// Icon for payment method
  IconData get methodIcon => paymentMethod.icon;

  /// Whether this payment was made by check
  bool get isCheckPayment => paymentMethod == PaymentMethod.check;

  /// Whether this payment needs a reference (transfer or mobile money)
  bool get needsReference =>
      paymentMethod == PaymentMethod.transfer ||
      paymentMethod == PaymentMethod.mobileMoney;

  /// Create a copy with updated fields
  Payment copyWith({
    String? id,
    String? rentScheduleId,
    double? amount,
    DateTime? paymentDate,
    PaymentMethod? paymentMethod,
    String? reference,
    String? checkNumber,
    String? bankName,
    String? receiptNumber,
    String? notes,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return Payment(
      id: id ?? this.id,
      rentScheduleId: rentScheduleId ?? this.rentScheduleId,
      amount: amount ?? this.amount,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      reference: reference ?? this.reference,
      checkNumber: checkNumber ?? this.checkNumber,
      bankName: bankName ?? this.bankName,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Payment && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
