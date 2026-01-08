import 'dart:typed_data';
import '../entities/tenant.dart';

/// Document type for tenant uploads
enum DocumentType {
  idDocument,
  guarantorId,
}

/// Tenant repository interface (Domain layer)
/// Defines the contract for tenant operations
abstract class TenantRepository {
  /// Create a new tenant
  /// Throws [TenantValidationException] if data is invalid
  /// Throws [TenantUnauthorizedException] if user doesn't have permission
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
  });

  /// Get all tenants (paginated)
  /// [page] starts at 1
  /// [limit] defaults to 20 items per page
  /// Returns empty list if no tenants found
  Future<List<Tenant>> getTenants({
    int page = 1,
    int limit = 20,
  });

  /// Get tenant by ID
  /// Throws [TenantNotFoundException] if not found
  /// Throws [TenantUnauthorizedException] if user doesn't have access
  Future<Tenant> getTenantById(String id);

  /// Update existing tenant
  /// Only provided fields will be updated
  /// Throws [TenantNotFoundException] if not found
  /// Throws [TenantUnauthorizedException] if user doesn't have permission
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
  });

  /// Delete tenant by ID
  /// Throws [TenantNotFoundException] if not found
  /// Throws [TenantHasActiveLeaseException] if tenant has active leases
  /// Throws [TenantUnauthorizedException] if user doesn't have permission
  Future<void> deleteTenant(String id);

  /// Search tenants by name or phone
  /// Returns matching tenants (up to 50 results)
  Future<List<Tenant>> searchTenants(String query);

  /// Upload tenant document (ID or guarantor ID)
  /// [documentBytes] is the raw document data
  /// Returns the storage path (not signed URL)
  /// Throws [TenantDocumentUploadException] on failure
  /// Throws [TenantDocumentTooLargeException] if document exceeds 5MB
  /// Throws [TenantDocumentInvalidFormatException] if format not supported
  Future<String> uploadDocument({
    required String tenantId,
    required Uint8List documentBytes,
    required String fileName,
    required DocumentType documentType,
  });

  /// Delete document from storage
  /// [storagePath] is the storage path (not the signed URL)
  Future<void> deleteDocument(String storagePath);

  /// Get signed URL for document access (1 hour validity)
  Future<String> getDocumentUrl(String storagePath);

  /// Check if phone number already exists
  /// Returns list of tenants with same phone (for duplicate warning)
  /// [excludeTenantId] can be provided when editing to exclude the current tenant
  Future<List<Tenant>> checkPhoneDuplicate(String phone, {String? excludeTenantId});

  /// Check if tenant can be deleted (no active leases)
  /// Returns true if deletion is allowed
  Future<bool> canDeleteTenant(String tenantId);

  /// Get total count of tenants
  Future<int> getTenantsCount();

  /// Check if current user can manage tenants (create/edit/delete)
  /// Returns false for assistant role (read-only + create)
  Future<bool> canManageTenants();
}
