# Contract: PdfReceiptService

**Feature**: 007-pdf-receipt-generation
**Layer**: Presentation (Service)

## Class Definition

```dart
/// Service for generating PDF rent receipts (quittances)
class PdfReceiptService {
  /// Generates a PDF receipt document from payment data
  ///
  /// Returns PDF bytes ready for preview, download, or storage
  Future<Uint8List> generateReceipt(ReceiptData data);

  /// Generates filename for the receipt
  ///
  /// Format: "Quittance_{Period}_{TenantName}.pdf"
  /// Example: "Quittance_Janvier2026_KONAN.pdf"
  String generateFilename(ReceiptData data);

  /// Builds the PDF document structure
  ///
  /// Internal method, creates Document with pages
  pw.Document _buildDocument(ReceiptData data);

  /// Builds the header section with title and period
  pw.Widget _buildHeader(ReceiptData data);

  /// Builds the landlord/manager section
  pw.Widget _buildLandlordSection(ReceiptData data);

  /// Builds the tenant section with address
  pw.Widget _buildTenantSection(ReceiptData data);

  /// Builds the payment details section
  pw.Widget _buildPaymentDetails(ReceiptData data);

  /// Builds the partial payment notice (if applicable)
  pw.Widget _buildPartialPaymentNotice(ReceiptData data);

  /// Builds the footer with legal mention and date
  pw.Widget _buildFooter(ReceiptData data);
}
```

## Data Types

### ReceiptData

```dart
/// All data needed to generate a receipt PDF
class ReceiptData {
  // Payment info
  final String receiptNumber;
  final double amountPaid;
  final DateTime paymentDate;
  final String paymentMethod;       // French label
  final String? paymentReference;   // For transfers/mobile money

  // Period info
  final DateTime periodStart;
  final DateTime periodEnd;

  // Amounts breakdown
  final double rentAmount;          // Loyer hors charges
  final double chargesAmount;       // Charges
  final double totalDue;            // Total échéance
  final double remainingBalance;    // Solde restant (0 if fully paid)

  // Tenant info
  final String tenantFullName;

  // Property info
  final String buildingName;
  final String unitReference;
  final String fullAddress;         // Building address + city

  // Manager info (from current user or system config)
  final String managerName;
  final String? managerContact;

  // Computed
  bool get isPartialPayment => remainingBalance > 0;

  String get periodLabel {
    final month = DateFormat('MMMM yyyy', 'fr_FR').format(periodStart);
    return month[0].toUpperCase() + month.substring(1);
  }

  String get amountPaidFormatted => _formatCurrency(amountPaid);
  String get rentAmountFormatted => _formatCurrency(rentAmount);
  String get chargesAmountFormatted => _formatCurrency(chargesAmount);
  String get totalDueFormatted => _formatCurrency(totalDue);
  String get remainingBalanceFormatted => _formatCurrency(remainingBalance);
  String get paymentDateFormatted => DateFormat('dd/MM/yyyy').format(paymentDate);

  static String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'fr_FR');
    return '${formatter.format(amount.round())} FCFA';
  }
}
```

### ReceiptDataBuilder

```dart
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
      remainingBalance: schedule.amountDue - schedule.amountPaid,
      tenantFullName: lease.tenant?.fullName ?? 'Locataire',
      buildingName: lease.unit?.building?.name ?? '',
      unitReference: lease.unit?.reference ?? '',
      fullAddress: _buildFullAddress(lease),
      managerName: managerName,
      managerContact: managerContact,
    );
  }

  static String _buildFullAddress(Lease lease) {
    final parts = <String>[];
    if (lease.unit?.building?.address != null) {
      parts.add(lease.unit!.building!.address);
    }
    if (lease.unit?.building?.city != null) {
      parts.add(lease.unit!.building!.city);
    }
    return parts.join(', ');
  }
}
```

## PDF Layout Specification

### Page Setup

- **Format**: A4 (210 x 297 mm)
- **Margins**: 20mm all sides
- **Font**: Helvetica (built-in, supports French)
- **Font sizes**: Title 24pt, Section headers 14pt, Body 12pt

### Document Structure

```
┌────────────────────────────────────────────────────────┐
│                                                        │
│              QUITTANCE DE LOYER                        │  ← Title, centered, bold
│               Janvier 2026                             │  ← Period, centered
│                                                        │
├────────────────────────────────────────────────────────┤
│ BAILLEUR                                               │  ← Section header, bold
│ Nom du gestionnaire                                    │
│ Contact (si disponible)                                │
├────────────────────────────────────────────────────────┤
│ LOCATAIRE                                              │  ← Section header, bold
│ Nom complet du locataire                               │
│ Immeuble - Lot XXX                                     │
│ Adresse, Ville                                         │
├────────────────────────────────────────────────────────┤
│ DÉTAIL DU PAIEMENT                                     │  ← Section header, bold
│                                                        │
│ Loyer (hors charges)              150 000 FCFA         │  ← Right-aligned amounts
│ Charges                            25 000 FCFA         │
│ ──────────────────────────────────────────────────     │
│ TOTAL                             175 000 FCFA         │  ← Bold
│                                                        │
│ Date de paiement: 05/01/2026                           │
│ Mode de paiement: Espèces                              │
│ Numéro de reçu: REC-2026-0001                          │
├────────────────────────────────────────────────────────┤
│ ⚠ ACOMPTE                                              │  ← Only if partial, yellow bg
│ Ce paiement est un acompte.                            │
│ Solde restant dû: 50 000 FCFA                          │
├────────────────────────────────────────────────────────┤
│                                                        │
│ Pour valoir ce que de droit.                           │  ← Legal mention, italic
│                                                        │
│ Fait le 05/01/2026                                     │  ← Generation date
│                                                        │
└────────────────────────────────────────────────────────┘
```

## Acceptance Criteria

- [ ] `generateReceipt` returns valid PDF bytes
- [ ] PDF opens correctly in standard PDF viewers
- [ ] All required fields from FR-002 are present
- [ ] FCFA amounts formatted with space thousands separator
- [ ] Dates in DD/MM/YYYY format
- [ ] Partial payment clearly indicated when applicable
- [ ] Legal mention "Pour valoir ce que de droit" included
- [ ] File size < 500KB for simple receipts
- [ ] French accents render correctly (é, è, à, etc.)
- [ ] `generateFilename` produces clean, safe filename
