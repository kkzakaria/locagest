import 'package:intl/intl.dart';

import '../../domain/entities/lease.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/rent_schedule.dart';

/// All data needed to generate a receipt PDF
class ReceiptData {
  // Payment info
  final String receiptNumber;
  final double amountPaid;
  final DateTime paymentDate;
  final String paymentMethod;
  final String? paymentReference;

  // Period info
  final DateTime periodStart;
  final DateTime periodEnd;

  // Amounts breakdown
  final double rentAmount;
  final double chargesAmount;
  final double totalDue;
  final double remainingBalance;

  // Tenant info
  final String tenantFullName;
  final String? tenantEmail;

  // Property info
  final String buildingName;
  final String unitReference;
  final String fullAddress;
  final String city;

  // Manager info
  final String managerName;
  final String? managerContact;

  const ReceiptData({
    required this.receiptNumber,
    required this.amountPaid,
    required this.paymentDate,
    required this.paymentMethod,
    this.paymentReference,
    required this.periodStart,
    required this.periodEnd,
    required this.rentAmount,
    required this.chargesAmount,
    required this.totalDue,
    required this.remainingBalance,
    required this.tenantFullName,
    this.tenantEmail,
    required this.buildingName,
    required this.unitReference,
    required this.fullAddress,
    required this.city,
    required this.managerName,
    this.managerContact,
  });

  /// Whether this is a partial payment (acompte)
  bool get isPartialPayment => remainingBalance > 0;

  /// Period label in French (e.g., "Janvier 2026")
  String get periodLabel {
    final month = DateFormat('MMMM yyyy', 'fr_FR').format(periodStart);
    // Capitalize first letter
    return month[0].toUpperCase() + month.substring(1);
  }

  /// Amount paid formatted in FCFA
  String get amountPaidFormatted => _formatCurrency(amountPaid);

  /// Rent amount formatted in FCFA
  String get rentAmountFormatted => _formatCurrency(rentAmount);

  /// Charges amount formatted in FCFA
  String get chargesAmountFormatted => _formatCurrency(chargesAmount);

  /// Total due formatted in FCFA
  String get totalDueFormatted => _formatCurrency(totalDue);

  /// Remaining balance formatted in FCFA
  String get remainingBalanceFormatted => _formatCurrency(remainingBalance);

  /// Payment date formatted (DD/MM/YYYY)
  String get paymentDateFormatted {
    return DateFormat('dd/MM/yyyy').format(paymentDate);
  }

  /// Current date formatted for footer
  String get generationDateFormatted {
    return DateFormat('dd/MM/yyyy').format(DateTime.now());
  }

  /// Full property address for receipt
  String get propertyFullAddress {
    final parts = <String>[];
    if (buildingName.isNotEmpty) parts.add(buildingName);
    if (unitReference.isNotEmpty) parts.add('Lot $unitReference');
    if (fullAddress.isNotEmpty) parts.add(fullAddress);
    if (city.isNotEmpty) parts.add(city);
    return parts.join(', ');
  }

  /// Format currency in FCFA with space thousand separator
  static String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'fr_FR');
    return '${formatter.format(amount.round())} FCFA';
  }
}

/// Factory to create ReceiptData from domain entities
class ReceiptDataBuilder {
  /// Creates ReceiptData from payment with related entities
  static ReceiptData fromPayment({
    required Payment payment,
    required RentSchedule schedule,
    required Lease lease,
    required String managerName,
    String? managerContact,
  }) {
    // Extract property info from lease and unit
    // Note: Unit entity has buildingName as a string, not a full building object
    // Address/city are not available through this path - would require separate building fetch
    final buildingName = lease.buildingName;
    final unitReference = lease.unitReference;

    return ReceiptData(
      receiptNumber: payment.receiptNumber,
      amountPaid: payment.amount,
      paymentDate: payment.paymentDate,
      paymentMethod: payment.methodLabel,
      paymentReference: payment.reference,
      periodStart: schedule.periodStart,
      periodEnd: schedule.periodEnd,
      rentAmount: lease.rentAmount,
      chargesAmount: lease.chargesAmount,
      totalDue: schedule.amountDue,
      remainingBalance: schedule.remainingBalance,
      tenantFullName: lease.tenant?.fullName ?? 'Locataire',
      tenantEmail: lease.tenant?.email,
      buildingName: buildingName,
      unitReference: unitReference,
      fullAddress: '', // Building address not available through Unit entity
      city: '', // Building city not available through Unit entity
      managerName: managerName,
      managerContact: managerContact,
    );
  }
}
