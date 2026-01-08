import 'dart:typed_data';
import '../../domain/entities/tenant.dart';
import '../../domain/repositories/tenant_repository.dart';
import '../datasources/tenant_remote_datasource.dart';
import '../models/tenant_model.dart';

/// Implementation of TenantRepository using remote datasource
class TenantRepositoryImpl implements TenantRepository {
  final TenantRemoteDatasource _datasource;

  TenantRepositoryImpl(this._datasource);

  @override
  Future<Tenant> createTenant({
    required String firstName,
    required String lastName,
    required String phone,
    String? email,
    String? phoneSecondary,
    String? idType,
    String? idNumber,
    String? idDocumentUrl,
    String? profession,
    String? employer,
    String? guarantorName,
    String? guarantorPhone,
    String? guarantorIdUrl,
    String? notes,
  }) async {
    final input = CreateTenantInput(
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      email: email,
      phoneSecondary: phoneSecondary,
      idType: idType,
      idNumber: idNumber,
      idDocumentUrl: idDocumentUrl,
      profession: profession,
      employer: employer,
      guarantorName: guarantorName,
      guarantorPhone: guarantorPhone,
      guarantorIdUrl: guarantorIdUrl,
      notes: notes,
    );

    final model = await _datasource.createTenant(input);
    return model.toEntity();
  }

  @override
  Future<List<Tenant>> getTenants({
    int page = 1,
    int limit = 20,
  }) async {
    final models = await _datasource.getTenants(
      page: page,
      limit: limit,
    );

    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<Tenant> getTenantById(String id) async {
    final model = await _datasource.getTenantById(id);
    return model.toEntity();
  }

  @override
  Future<Tenant> updateTenant({
    required String id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? phoneSecondary,
    String? idType,
    String? idNumber,
    String? idDocumentUrl,
    String? profession,
    String? employer,
    String? guarantorName,
    String? guarantorPhone,
    String? guarantorIdUrl,
    String? notes,
  }) async {
    final input = UpdateTenantInput(
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      phoneSecondary: phoneSecondary,
      idType: idType,
      idNumber: idNumber,
      idDocumentUrl: idDocumentUrl,
      profession: profession,
      employer: employer,
      guarantorName: guarantorName,
      guarantorPhone: guarantorPhone,
      guarantorIdUrl: guarantorIdUrl,
      notes: notes,
    );

    final model = await _datasource.updateTenant(id: id, input: input);
    return model.toEntity();
  }

  @override
  Future<void> deleteTenant(String id) async {
    await _datasource.deleteTenant(id);
  }

  @override
  Future<List<Tenant>> searchTenants(String query) async {
    final models = await _datasource.searchTenants(query);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<String> uploadDocument({
    required String tenantId,
    required Uint8List documentBytes,
    required String fileName,
    required DocumentType documentType,
  }) async {
    return _datasource.uploadDocument(
      tenantId: tenantId,
      documentBytes: documentBytes,
      fileName: fileName,
      documentType: documentType,
    );
  }

  @override
  Future<void> deleteDocument(String storagePath) async {
    await _datasource.deleteDocument(storagePath);
  }

  @override
  Future<String> getDocumentUrl(String storagePath) async {
    return _datasource.getDocumentUrl(storagePath);
  }

  @override
  Future<List<Tenant>> checkPhoneDuplicate(
    String phone, {
    String? excludeTenantId,
  }) async {
    final models = await _datasource.checkPhoneDuplicate(
      phone,
      excludeTenantId: excludeTenantId,
    );
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<bool> canDeleteTenant(String tenantId) async {
    return _datasource.canDeleteTenant(tenantId);
  }

  @override
  Future<int> getTenantsCount() async {
    return _datasource.getTenantsCount();
  }

  @override
  Future<bool> canManageTenants() async {
    return _datasource.canManageTenants();
  }
}
