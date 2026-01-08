import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/tenant_exceptions.dart';
import '../../domain/repositories/tenant_repository.dart';
import '../models/tenant_model.dart';

/// Remote datasource for tenant operations via Supabase
class TenantRemoteDatasource {
  final SupabaseClient _supabase;

  TenantRemoteDatasource(this._supabase);

  /// Create a new tenant
  Future<TenantModel> createTenant(CreateTenantInput input) async {
    try {
      final response = await _supabase
          .from('tenants')
          .insert(input.toJson())
          .select()
          .single();

      return TenantModel.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == '23514') {
        // Check constraint violation
        throw TenantValidationException('Les données saisies sont invalides: ${e.message}');
      } else if (e.code == '42501') {
        // Insufficient privilege
        throw const TenantUnauthorizedException();
      }
      throw TenantValidationException(e.message);
    }
  }

  /// Get all tenants with pagination
  Future<List<TenantModel>> getTenants({
    int page = 1,
    int limit = 20,
  }) async {
    final offset = (page - 1) * limit;

    try {
      final response = await _supabase
          .from('tenants')
          .select()
          .order('last_name', ascending: true)
          .order('first_name', ascending: true)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => TenantModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw TenantValidationException(e.message);
    }
  }

  /// Get tenant by ID
  Future<TenantModel> getTenantById(String id) async {
    try {
      final response = await _supabase
          .from('tenants')
          .select()
          .eq('id', id)
          .single();

      return TenantModel.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw const TenantNotFoundException();
      } else if (e.code == '42501') {
        throw const TenantUnauthorizedException();
      }
      throw TenantValidationException(e.message);
    }
  }

  /// Update tenant
  Future<TenantModel> updateTenant({
    required String id,
    required UpdateTenantInput input,
  }) async {
    try {
      final updateMap = input.toUpdateMap();
      if (updateMap.isEmpty) {
        // Nothing to update, return current tenant
        return getTenantById(id);
      }

      final response = await _supabase
          .from('tenants')
          .update(updateMap)
          .eq('id', id)
          .select()
          .single();

      return TenantModel.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw const TenantNotFoundException();
      } else if (e.code == '23514') {
        throw TenantValidationException('Les données saisies sont invalides: ${e.message}');
      } else if (e.code == '42501') {
        throw const TenantUnauthorizedException();
      }
      throw TenantValidationException(e.message);
    }
  }

  /// Delete tenant
  Future<void> deleteTenant(String id) async {
    try {
      await _supabase.from('tenants').delete().eq('id', id);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw const TenantNotFoundException();
      } else if (e.code == '23503') {
        // Foreign key violation - has active leases
        throw const TenantHasActiveLeaseException();
      } else if (e.code == '42501') {
        throw const TenantUnauthorizedException();
      }
      throw TenantValidationException(e.message);
    }
  }

  /// Search tenants by name or phone using ILIKE
  Future<List<TenantModel>> searchTenants(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }

    try {
      final searchTerm = '%${query.trim()}%';
      final response = await _supabase
          .from('tenants')
          .select()
          .or('first_name.ilike.$searchTerm,last_name.ilike.$searchTerm,phone.ilike.$searchTerm')
          .order('last_name', ascending: true)
          .limit(50);

      return (response as List)
          .map((json) => TenantModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw TenantValidationException(e.message);
    }
  }

  /// Upload document to storage (returns storage path, not signed URL)
  Future<String> uploadDocument({
    required String tenantId,
    required Uint8List documentBytes,
    required String fileName,
    required DocumentType documentType,
  }) async {
    try {
      // Determine path based on document type
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = fileName.split('.').last.toLowerCase();
      final path = documentType == DocumentType.idDocument
          ? 'tenants/$tenantId/id_document_$timestamp.$extension'
          : 'tenants/$tenantId/guarantor_id_$timestamp.$extension';

      await _supabase.storage.from('documents').uploadBinary(
            path,
            documentBytes,
            fileOptions: FileOptions(
              contentType: _getMimeType(extension),
            ),
          );

      // Return storage path (NOT signed URL)
      return path;
    } on StorageException catch (e) {
      if (e.statusCode == '413') {
        throw const TenantDocumentTooLargeException();
      }
      throw const TenantDocumentUploadException();
    }
  }

  /// Get MIME type from extension
  String _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  /// Delete document from storage
  Future<void> deleteDocument(String storagePath) async {
    try {
      await _supabase.storage.from('documents').remove([storagePath]);
    } on StorageException {
      // Ignore errors when deleting - document might not exist
    }
  }

  /// Get signed URL for document (1 hour validity)
  Future<String> getDocumentUrl(String storagePath) async {
    try {
      // 3600 seconds = 1 hour
      final signedUrl = await _supabase.storage
          .from('documents')
          .createSignedUrl(storagePath, 3600);
      return signedUrl;
    } on StorageException {
      throw const TenantDocumentUploadException();
    }
  }

  /// Check for duplicate phone number
  Future<List<TenantModel>> checkPhoneDuplicate(
    String phone, {
    String? excludeTenantId,
  }) async {
    try {
      var query = _supabase
          .from('tenants')
          .select('id, first_name, last_name, phone')
          .eq('phone', phone);

      if (excludeTenantId != null) {
        query = query.neq('id', excludeTenantId);
      }

      final response = await query;
      return (response as List)
          .map((json) => TenantModel.fromJson({
                ...json,
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              }))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Check if tenant can be deleted (no active leases)
  /// For now, returns true since leases table doesn't exist yet
  Future<bool> canDeleteTenant(String tenantId) async {
    // TODO: When leases module is implemented, check for active leases:
    // final activeLeases = await _supabase
    //     .from('leases')
    //     .select('id')
    //     .eq('tenant_id', tenantId)
    //     .eq('status', 'active');
    // return (activeLeases as List).isEmpty;

    // For now, always allow deletion (leases module not yet implemented)
    return true;
  }

  /// Get tenants count
  Future<int> getTenantsCount() async {
    try {
      final response = await _supabase
          .from('tenants')
          .select('id');

      return (response as List).length;
    } on PostgrestException {
      return 0;
    }
  }

  /// Check if user can manage tenants (based on role)
  Future<bool> canManageTenants() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .single();

      final role = response['role'] as String?;
      // Admin and gestionnaire can manage (full CRUD)
      // Assistant can only read and create (not edit/delete)
      return role == 'admin' || role == 'gestionnaire';
    } catch (e) {
      return false;
    }
  }
}
