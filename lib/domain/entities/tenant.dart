import 'package:flutter/material.dart';

/// ID document type enumeration
enum IdDocumentType {
  cni,
  passport,
  residencePermit;

  /// Get French label for the type
  String get label {
    switch (this) {
      case IdDocumentType.cni:
        return 'CNI';
      case IdDocumentType.passport:
        return 'Passeport';
      case IdDocumentType.residencePermit:
        return 'Carte de séjour';
    }
  }

  /// Get database value
  String get dbValue {
    switch (this) {
      case IdDocumentType.cni:
        return 'cni';
      case IdDocumentType.passport:
        return 'passport';
      case IdDocumentType.residencePermit:
        return 'residence_permit';
    }
  }

  /// Parse from database value
  static IdDocumentType? fromDbValue(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'cni':
        return IdDocumentType.cni;
      case 'passport':
        return IdDocumentType.passport;
      case 'residence_permit':
        return IdDocumentType.residencePermit;
      default:
        return null;
    }
  }
}

/// Tenant entity (Domain layer - pure Dart, no Supabase dependencies)
/// Represents a person who can rent a unit through a lease
class Tenant {
  final String id;
  final String firstName;
  final String lastName;
  final String? email;
  final String phone;
  final String? phoneSecondary;
  final IdDocumentType? idType;
  final String? idNumber;
  final String? idDocumentUrl;
  final String? profession;
  final String? employer;
  final String? guarantorName;
  final String? guarantorPhone;
  final String? guarantorIdUrl;
  final String? notes;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Computed property - requires lease data (set from join query)
  final bool hasActiveLease;

  const Tenant({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.email,
    required this.phone,
    this.phoneSecondary,
    this.idType,
    this.idNumber,
    this.idDocumentUrl,
    this.profession,
    this.employer,
    this.guarantorName,
    this.guarantorPhone,
    this.guarantorIdUrl,
    this.notes,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.hasActiveLease = false,
  });

  // ============================================================================
  // COMPUTED PROPERTIES
  // ============================================================================

  /// Full name display
  String get fullName => '$firstName $lastName';

  /// Human-readable ID type in French
  String get idTypeLabel => idType?.label ?? '-';

  /// Status based on active lease
  bool get isActive => hasActiveLease;

  /// Status label in French
  String get statusLabel => isActive ? 'Actif' : 'Inactif';

  /// Status color for UI (Constitution II)
  Color get statusColor => isActive ? Colors.green : Colors.grey;

  /// Has identity document uploaded
  bool get hasIdDocument =>
      idDocumentUrl != null && idDocumentUrl!.isNotEmpty;

  /// Has guarantor info
  bool get hasGuarantor =>
      guarantorName != null && guarantorName!.isNotEmpty;

  /// Has guarantor document uploaded
  bool get hasGuarantorDocument =>
      guarantorIdUrl != null && guarantorIdUrl!.isNotEmpty;

  /// Has professional info
  bool get hasProfessionalInfo =>
      (profession != null && profession!.isNotEmpty) ||
      (employer != null && employer!.isNotEmpty);

  /// Has email
  bool get hasEmail => email != null && email!.isNotEmpty;

  /// Has secondary phone
  bool get hasSecondaryPhone =>
      phoneSecondary != null && phoneSecondary!.isNotEmpty;

  /// Has notes
  bool get hasNotes => notes != null && notes!.isNotEmpty;

  /// Formatted phone for display (XX XX XX XX XX)
  String get phoneDisplay {
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length >= 10) {
      final last10 = digits.substring(digits.length - 10);
      return '${last10.substring(0, 2)} ${last10.substring(2, 4)} ${last10.substring(4, 6)} ${last10.substring(6, 8)} ${last10.substring(8, 10)}';
    }
    return phone;
  }

  /// Formatted secondary phone for display
  String? get phoneSecondaryDisplay {
    if (phoneSecondary == null || phoneSecondary!.isEmpty) return null;
    final digits = phoneSecondary!.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length >= 10) {
      final last10 = digits.substring(digits.length - 10);
      return '${last10.substring(0, 2)} ${last10.substring(2, 4)} ${last10.substring(4, 6)} ${last10.substring(6, 8)} ${last10.substring(8, 10)}';
    }
    return phoneSecondary;
  }

  /// Formatted guarantor phone for display
  String? get guarantorPhoneDisplay {
    if (guarantorPhone == null || guarantorPhone!.isEmpty) return null;
    final digits = guarantorPhone!.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length >= 10) {
      final last10 = digits.substring(digits.length - 10);
      return '${last10.substring(0, 2)} ${last10.substring(2, 4)} ${last10.substring(4, 6)} ${last10.substring(6, 8)} ${last10.substring(8, 10)}';
    }
    return guarantorPhone;
  }

  // ============================================================================
  // COPY WITH
  // ============================================================================

  /// Copy with modified fields
  Tenant copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? phoneSecondary,
    IdDocumentType? idType,
    String? idNumber,
    String? idDocumentUrl,
    String? profession,
    String? employer,
    String? guarantorName,
    String? guarantorPhone,
    String? guarantorIdUrl,
    String? notes,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? hasActiveLease,
  }) {
    return Tenant(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      phoneSecondary: phoneSecondary ?? this.phoneSecondary,
      idType: idType ?? this.idType,
      idNumber: idNumber ?? this.idNumber,
      idDocumentUrl: idDocumentUrl ?? this.idDocumentUrl,
      profession: profession ?? this.profession,
      employer: employer ?? this.employer,
      guarantorName: guarantorName ?? this.guarantorName,
      guarantorPhone: guarantorPhone ?? this.guarantorPhone,
      guarantorIdUrl: guarantorIdUrl ?? this.guarantorIdUrl,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      hasActiveLease: hasActiveLease ?? this.hasActiveLease,
    );
  }

  // ============================================================================
  // EQUALITY
  // ============================================================================

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tenant &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          firstName == other.firstName &&
          lastName == other.lastName &&
          email == other.email &&
          phone == other.phone &&
          phoneSecondary == other.phoneSecondary &&
          idType == other.idType &&
          idNumber == other.idNumber &&
          profession == other.profession &&
          employer == other.employer &&
          guarantorName == other.guarantorName &&
          guarantorPhone == other.guarantorPhone;

  @override
  int get hashCode =>
      id.hashCode ^
      firstName.hashCode ^
      lastName.hashCode ^
      phone.hashCode;

  @override
  String toString() {
    return 'Tenant{id: $id, name: $fullName, phone: $phone, isActive: $isActive}';
  }
}
