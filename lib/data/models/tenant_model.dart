import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/tenant.dart';

part 'tenant_model.freezed.dart';
part 'tenant_model.g.dart';

/// TenantModel for Supabase tenants table (Data layer)
@freezed
class TenantModel with _$TenantModel {
  const TenantModel._();

  const factory TenantModel({
    required String id,
    @JsonKey(name: 'first_name') required String firstName,
    @JsonKey(name: 'last_name') required String lastName,
    String? email,
    required String phone,
    @JsonKey(name: 'phone_secondary') String? phoneSecondary,
    @JsonKey(name: 'id_type') String? idType,
    @JsonKey(name: 'id_number') String? idNumber,
    @JsonKey(name: 'id_document_url') String? idDocumentUrl,
    String? profession,
    String? employer,
    @JsonKey(name: 'guarantor_name') String? guarantorName,
    @JsonKey(name: 'guarantor_phone') String? guarantorPhone,
    @JsonKey(name: 'guarantor_id_url') String? guarantorIdUrl,
    String? notes,
    @JsonKey(name: 'created_by') String? createdBy,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    // Computed from join (when available - future leases module)
    @JsonKey(name: 'has_active_lease') @Default(false) bool hasActiveLease,
  }) = _TenantModel;

  factory TenantModel.fromJson(Map<String, dynamic> json) =>
      _$TenantModelFromJson(json);

  /// Convert to domain entity
  Tenant toEntity() => Tenant(
        id: id,
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        phoneSecondary: phoneSecondary,
        idType: IdDocumentType.fromDbValue(idType),
        idNumber: idNumber,
        idDocumentUrl: idDocumentUrl,
        profession: profession,
        employer: employer,
        guarantorName: guarantorName,
        guarantorPhone: guarantorPhone,
        guarantorIdUrl: guarantorIdUrl,
        notes: notes,
        createdBy: createdBy,
        createdAt: createdAt,
        updatedAt: updatedAt,
        hasActiveLease: hasActiveLease,
      );
}

/// Extension to create TenantModel from Tenant entity
extension TenantModelFromEntity on Tenant {
  TenantModel toModel() {
    return TenantModel(
      id: id,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      phoneSecondary: phoneSecondary,
      idType: idType?.dbValue,
      idNumber: idNumber,
      idDocumentUrl: idDocumentUrl,
      profession: profession,
      employer: employer,
      guarantorName: guarantorName,
      guarantorPhone: guarantorPhone,
      guarantorIdUrl: guarantorIdUrl,
      notes: notes,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
      hasActiveLease: hasActiveLease,
    );
  }
}

/// Input model for creating a new tenant (no id, timestamps)
@freezed
class CreateTenantInput with _$CreateTenantInput {
  const factory CreateTenantInput({
    @JsonKey(name: 'first_name') required String firstName,
    @JsonKey(name: 'last_name') required String lastName,
    String? email,
    required String phone,
    @JsonKey(name: 'phone_secondary') String? phoneSecondary,
    @JsonKey(name: 'id_type') String? idType,
    @JsonKey(name: 'id_number') String? idNumber,
    @JsonKey(name: 'id_document_url') String? idDocumentUrl,
    String? profession,
    String? employer,
    @JsonKey(name: 'guarantor_name') String? guarantorName,
    @JsonKey(name: 'guarantor_phone') String? guarantorPhone,
    @JsonKey(name: 'guarantor_id_url') String? guarantorIdUrl,
    String? notes,
  }) = _CreateTenantInput;

  factory CreateTenantInput.fromJson(Map<String, dynamic> json) =>
      _$CreateTenantInputFromJson(json);
}

/// Input model for updating an existing tenant
@freezed
class UpdateTenantInput with _$UpdateTenantInput {
  const UpdateTenantInput._();

  const factory UpdateTenantInput({
    @JsonKey(name: 'first_name') String? firstName,
    @JsonKey(name: 'last_name') String? lastName,
    String? email,
    String? phone,
    @JsonKey(name: 'phone_secondary') String? phoneSecondary,
    @JsonKey(name: 'id_type') String? idType,
    @JsonKey(name: 'id_number') String? idNumber,
    @JsonKey(name: 'id_document_url') String? idDocumentUrl,
    String? profession,
    String? employer,
    @JsonKey(name: 'guarantor_name') String? guarantorName,
    @JsonKey(name: 'guarantor_phone') String? guarantorPhone,
    @JsonKey(name: 'guarantor_id_url') String? guarantorIdUrl,
    String? notes,
  }) = _UpdateTenantInput;

  factory UpdateTenantInput.fromJson(Map<String, dynamic> json) =>
      _$UpdateTenantInputFromJson(json);

  /// Convert to Map with only non-null fields for Supabase update
  Map<String, dynamic> toUpdateMap() {
    final map = <String, dynamic>{};
    if (firstName != null) map['first_name'] = firstName;
    if (lastName != null) map['last_name'] = lastName;
    if (email != null) map['email'] = email;
    if (phone != null) map['phone'] = phone;
    if (phoneSecondary != null) map['phone_secondary'] = phoneSecondary;
    if (idType != null) map['id_type'] = idType;
    if (idNumber != null) map['id_number'] = idNumber;
    if (idDocumentUrl != null) map['id_document_url'] = idDocumentUrl;
    if (profession != null) map['profession'] = profession;
    if (employer != null) map['employer'] = employer;
    if (guarantorName != null) map['guarantor_name'] = guarantorName;
    if (guarantorPhone != null) map['guarantor_phone'] = guarantorPhone;
    if (guarantorIdUrl != null) map['guarantor_id_url'] = guarantorIdUrl;
    if (notes != null) map['notes'] = notes;
    return map;
  }
}
