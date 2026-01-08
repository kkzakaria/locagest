import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/tenant_remote_datasource.dart';
import '../../data/repositories/tenant_repository_impl.dart';
import '../../domain/entities/tenant.dart';
import '../../domain/repositories/tenant_repository.dart';

// =============================================================================
// DEPENDENCY PROVIDERS
// =============================================================================

/// Provider for TenantRemoteDatasource
final tenantDatasourceProvider = Provider<TenantRemoteDatasource>((ref) {
  return TenantRemoteDatasource(Supabase.instance.client);
});

/// Provider for TenantRepository
final tenantRepositoryProvider = Provider<TenantRepository>((ref) {
  return TenantRepositoryImpl(ref.read(tenantDatasourceProvider));
});

// =============================================================================
// STATE CLASSES
// =============================================================================

/// State for the tenants list
class TenantsState {
  final List<Tenant> tenants;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? error;
  final String searchQuery;

  const TenantsState({
    this.tenants = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.error,
    this.searchQuery = '',
  });

  TenantsState copyWith({
    List<Tenant>? tenants,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? error,
    String? searchQuery,
  }) {
    return TenantsState(
      tenants: tenants ?? this.tenants,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

// =============================================================================
// TENANTS LIST PROVIDER
// =============================================================================

/// Provider for managing tenants list
class TenantsNotifier extends StateNotifier<TenantsState> {
  final TenantRepository _repository;
  static const int _pageSize = 20;

  TenantsNotifier(this._repository) : super(const TenantsState());

  /// Load initial tenants
  Future<void> loadTenants() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final tenants = await _repository.getTenants(
        page: 1,
        limit: _pageSize,
      );
      state = TenantsState(
        tenants: tenants,
        isLoading: false,
        hasMore: tenants.length >= _pageSize,
        currentPage: 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load more tenants (pagination)
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore || state.searchQuery.isNotEmpty) return;

    state = state.copyWith(isLoading: true);

    try {
      final nextPage = state.currentPage + 1;
      final newTenants = await _repository.getTenants(
        page: nextPage,
        limit: _pageSize,
      );

      state = state.copyWith(
        tenants: [...state.tenants, ...newTenants],
        isLoading: false,
        hasMore: newTenants.length >= _pageSize,
        currentPage: nextPage,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Search tenants
  Future<void> searchTenants(String query) async {
    state = state.copyWith(searchQuery: query, isLoading: true, error: null);

    if (query.trim().isEmpty) {
      // Clear search, reload all tenants
      await loadTenants();
      return;
    }

    try {
      final results = await _repository.searchTenants(query);
      state = state.copyWith(
        tenants: results,
        isLoading: false,
        hasMore: false, // No pagination for search results
        currentPage: 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh the tenants list
  Future<void> refresh() async {
    state = const TenantsState();
    await loadTenants();
  }

  /// Add a newly created tenant to the list
  void addTenant(Tenant tenant) {
    state = state.copyWith(
      tenants: [tenant, ...state.tenants],
    );
  }

  /// Update a tenant in the list
  void updateTenant(Tenant tenant) {
    final index = state.tenants.indexWhere((t) => t.id == tenant.id);
    if (index != -1) {
      final updatedList = List<Tenant>.from(state.tenants);
      updatedList[index] = tenant;
      state = state.copyWith(tenants: updatedList);
    }
  }

  /// Remove a tenant from the list
  void removeTenant(String id) {
    state = state.copyWith(
      tenants: state.tenants.where((t) => t.id != id).toList(),
    );
  }
}

/// Provider for TenantsNotifier
final tenantsProvider = StateNotifierProvider<TenantsNotifier, TenantsState>((ref) {
  return TenantsNotifier(ref.read(tenantRepositoryProvider));
});

// =============================================================================
// SINGLE TENANT PROVIDER
// =============================================================================

/// Provider for fetching a single tenant by ID
final tenantByIdProvider = FutureProvider.family<Tenant, String>((ref, id) async {
  final repository = ref.read(tenantRepositoryProvider);
  return repository.getTenantById(id);
});

// =============================================================================
// SEARCH PROVIDER
// =============================================================================

/// Provider for searching tenants
final tenantSearchProvider = FutureProvider.family<List<Tenant>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];
  final repository = ref.read(tenantRepositoryProvider);
  return repository.searchTenants(query);
});

// =============================================================================
// CREATE TENANT PROVIDER
// =============================================================================

/// State for tenant creation
class CreateTenantState {
  final bool isLoading;
  final bool isUploadingDocument;
  final String? idDocumentPath;
  final String? guarantorIdPath;
  final String? error;
  final Tenant? createdTenant;

  const CreateTenantState({
    this.isLoading = false,
    this.isUploadingDocument = false,
    this.idDocumentPath,
    this.guarantorIdPath,
    this.error,
    this.createdTenant,
  });

  CreateTenantState copyWith({
    bool? isLoading,
    bool? isUploadingDocument,
    String? idDocumentPath,
    String? guarantorIdPath,
    String? error,
    Tenant? createdTenant,
  }) {
    return CreateTenantState(
      isLoading: isLoading ?? this.isLoading,
      isUploadingDocument: isUploadingDocument ?? this.isUploadingDocument,
      idDocumentPath: idDocumentPath ?? this.idDocumentPath,
      guarantorIdPath: guarantorIdPath ?? this.guarantorIdPath,
      error: error,
      createdTenant: createdTenant ?? this.createdTenant,
    );
  }
}

/// Notifier for tenant creation
class CreateTenantNotifier extends StateNotifier<CreateTenantState> {
  final TenantRepository _repository;

  CreateTenantNotifier(this._repository) : super(const CreateTenantState());

  /// Upload ID document
  Future<String?> uploadIdDocument(String tenantId, Uint8List documentBytes, String fileName) async {
    state = state.copyWith(isUploadingDocument: true, error: null);

    try {
      final path = await _repository.uploadDocument(
        tenantId: tenantId,
        documentBytes: documentBytes,
        fileName: fileName,
        documentType: DocumentType.idDocument,
      );
      state = state.copyWith(
        isUploadingDocument: false,
        idDocumentPath: path,
      );
      return path;
    } catch (e) {
      state = state.copyWith(
        isUploadingDocument: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Upload guarantor ID document
  Future<String?> uploadGuarantorIdDocument(String tenantId, Uint8List documentBytes, String fileName) async {
    state = state.copyWith(isUploadingDocument: true, error: null);

    try {
      final path = await _repository.uploadDocument(
        tenantId: tenantId,
        documentBytes: documentBytes,
        fileName: fileName,
        documentType: DocumentType.guarantorId,
      );
      state = state.copyWith(
        isUploadingDocument: false,
        guarantorIdPath: path,
      );
      return path;
    } catch (e) {
      state = state.copyWith(
        isUploadingDocument: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Create a new tenant
  Future<Tenant?> createTenant({
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
    state = state.copyWith(isLoading: true, error: null);

    try {
      final tenant = await _repository.createTenant(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        email: email,
        phoneSecondary: phoneSecondary,
        idType: idType,
        idNumber: idNumber,
        idDocumentUrl: idDocumentUrl ?? state.idDocumentPath,
        profession: profession,
        employer: employer,
        guarantorName: guarantorName,
        guarantorPhone: guarantorPhone,
        guarantorIdUrl: guarantorIdUrl ?? state.guarantorIdPath,
        notes: notes,
      );

      state = state.copyWith(
        isLoading: false,
        createdTenant: tenant,
      );

      return tenant;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Reset the state
  void reset() {
    state = const CreateTenantState();
  }
}

/// Provider for CreateTenantNotifier
final createTenantProvider =
    StateNotifierProvider<CreateTenantNotifier, CreateTenantState>((ref) {
  return CreateTenantNotifier(ref.read(tenantRepositoryProvider));
});

// =============================================================================
// EDIT TENANT PROVIDER
// =============================================================================

/// State for tenant editing
class EditTenantState {
  final bool isLoading;
  final bool isUploadingDocument;
  final String? newIdDocumentPath;
  final String? newGuarantorIdPath;
  final String? error;
  final Tenant? updatedTenant;

  const EditTenantState({
    this.isLoading = false,
    this.isUploadingDocument = false,
    this.newIdDocumentPath,
    this.newGuarantorIdPath,
    this.error,
    this.updatedTenant,
  });

  EditTenantState copyWith({
    bool? isLoading,
    bool? isUploadingDocument,
    String? newIdDocumentPath,
    String? newGuarantorIdPath,
    String? error,
    Tenant? updatedTenant,
  }) {
    return EditTenantState(
      isLoading: isLoading ?? this.isLoading,
      isUploadingDocument: isUploadingDocument ?? this.isUploadingDocument,
      newIdDocumentPath: newIdDocumentPath ?? this.newIdDocumentPath,
      newGuarantorIdPath: newGuarantorIdPath ?? this.newGuarantorIdPath,
      error: error,
      updatedTenant: updatedTenant ?? this.updatedTenant,
    );
  }
}

/// Notifier for tenant editing
class EditTenantNotifier extends StateNotifier<EditTenantState> {
  final TenantRepository _repository;

  EditTenantNotifier(this._repository) : super(const EditTenantState());

  /// Upload new ID document
  Future<String?> uploadIdDocument(String tenantId, Uint8List documentBytes, String fileName) async {
    state = state.copyWith(isUploadingDocument: true, error: null);

    try {
      final path = await _repository.uploadDocument(
        tenantId: tenantId,
        documentBytes: documentBytes,
        fileName: fileName,
        documentType: DocumentType.idDocument,
      );
      state = state.copyWith(
        isUploadingDocument: false,
        newIdDocumentPath: path,
      );
      return path;
    } catch (e) {
      state = state.copyWith(
        isUploadingDocument: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Upload new guarantor ID document
  Future<String?> uploadGuarantorIdDocument(String tenantId, Uint8List documentBytes, String fileName) async {
    state = state.copyWith(isUploadingDocument: true, error: null);

    try {
      final path = await _repository.uploadDocument(
        tenantId: tenantId,
        documentBytes: documentBytes,
        fileName: fileName,
        documentType: DocumentType.guarantorId,
      );
      state = state.copyWith(
        isUploadingDocument: false,
        newGuarantorIdPath: path,
      );
      return path;
    } catch (e) {
      state = state.copyWith(
        isUploadingDocument: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Delete old document before replacing
  Future<void> deleteDocument(String storagePath) async {
    try {
      await _repository.deleteDocument(storagePath);
    } catch (e) {
      // Ignore delete errors - document might not exist
    }
  }

  /// Update an existing tenant
  Future<Tenant?> updateTenant({
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
    state = state.copyWith(isLoading: true, error: null);

    try {
      final tenant = await _repository.updateTenant(
        id: id,
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        phoneSecondary: phoneSecondary,
        idType: idType,
        idNumber: idNumber,
        idDocumentUrl: idDocumentUrl ?? state.newIdDocumentPath,
        profession: profession,
        employer: employer,
        guarantorName: guarantorName,
        guarantorPhone: guarantorPhone,
        guarantorIdUrl: guarantorIdUrl ?? state.newGuarantorIdPath,
        notes: notes,
      );

      state = state.copyWith(
        isLoading: false,
        updatedTenant: tenant,
      );

      return tenant;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Reset the state
  void reset() {
    state = const EditTenantState();
  }
}

/// Provider for EditTenantNotifier
final editTenantProvider =
    StateNotifierProvider<EditTenantNotifier, EditTenantState>((ref) {
  return EditTenantNotifier(ref.read(tenantRepositoryProvider));
});

// =============================================================================
// DELETE TENANT PROVIDER
// =============================================================================

/// State for tenant deletion
class DeleteTenantState {
  final bool isLoading;
  final String? error;
  final bool isDeleted;

  const DeleteTenantState({
    this.isLoading = false,
    this.error,
    this.isDeleted = false,
  });

  DeleteTenantState copyWith({
    bool? isLoading,
    String? error,
    bool? isDeleted,
  }) {
    return DeleteTenantState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

/// Notifier for tenant deletion
class DeleteTenantNotifier extends StateNotifier<DeleteTenantState> {
  final TenantRepository _repository;

  DeleteTenantNotifier(this._repository) : super(const DeleteTenantState());

  /// Check if tenant can be deleted
  Future<bool> canDelete(String tenantId) async {
    return _repository.canDeleteTenant(tenantId);
  }

  /// Delete a tenant by ID
  Future<bool> deleteTenant(String id) async {
    state = state.copyWith(isLoading: true, error: null, isDeleted: false);

    try {
      await _repository.deleteTenant(id);

      state = state.copyWith(
        isLoading: false,
        isDeleted: true,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Reset the state
  void reset() {
    state = const DeleteTenantState();
  }
}

/// Provider for DeleteTenantNotifier
final deleteTenantProvider =
    StateNotifierProvider<DeleteTenantNotifier, DeleteTenantState>((ref) {
  return DeleteTenantNotifier(ref.read(tenantRepositoryProvider));
});

// =============================================================================
// PERMISSION PROVIDER
// =============================================================================

/// Provider for checking if user can manage tenants
final canManageTenantsProvider = FutureProvider<bool>((ref) async {
  final repository = ref.read(tenantRepositoryProvider);
  return repository.canManageTenants();
});

// =============================================================================
// PHONE DUPLICATE CHECK PROVIDER
// =============================================================================

/// Parameters for checking phone duplicate
class PhoneCheckParams {
  final String phone;
  final String? excludeTenantId;

  const PhoneCheckParams({
    required this.phone,
    this.excludeTenantId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhoneCheckParams &&
          runtimeType == other.runtimeType &&
          phone == other.phone &&
          excludeTenantId == other.excludeTenantId;

  @override
  int get hashCode => phone.hashCode ^ (excludeTenantId?.hashCode ?? 0);
}

/// Provider for checking if a phone number is duplicate
final phoneDuplicateProvider =
    FutureProvider.family<List<Tenant>, PhoneCheckParams>((ref, params) async {
  final repository = ref.read(tenantRepositoryProvider);
  return repository.checkPhoneDuplicate(
    params.phone,
    excludeTenantId: params.excludeTenantId,
  );
});

// =============================================================================
// DOCUMENT URL PROVIDER
// =============================================================================

/// Provider for getting signed document URL
final documentUrlProvider =
    FutureProvider.family<String, String>((ref, storagePath) async {
  final repository = ref.read(tenantRepositoryProvider);
  return repository.getDocumentUrl(storagePath);
});

// =============================================================================
// TENANTS COUNT PROVIDER
// =============================================================================

/// Provider for getting total tenants count
final tenantsCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.read(tenantRepositoryProvider);
  return repository.getTenantsCount();
});
