import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/unit_remote_datasource.dart';
import '../../data/repositories/unit_repository_impl.dart';
import '../../domain/entities/unit.dart';
import '../../domain/repositories/unit_repository.dart';

// =============================================================================
// DEPENDENCY PROVIDERS
// =============================================================================

/// Provider for UnitRemoteDatasource
final unitDatasourceProvider = Provider<UnitRemoteDatasource>((ref) {
  return UnitRemoteDatasource(Supabase.instance.client);
});

/// Provider for UnitRepository
final unitRepositoryProvider = Provider<UnitRepository>((ref) {
  return UnitRepositoryImpl(ref.read(unitDatasourceProvider));
});

// =============================================================================
// STATE CLASSES
// =============================================================================

/// State for the units list (per building)
class UnitsState {
  final List<Unit> units;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? error;

  const UnitsState({
    this.units = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.error,
  });

  UnitsState copyWith({
    List<Unit>? units,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) {
    return UnitsState(
      units: units ?? this.units,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
    );
  }
}

// =============================================================================
// UNITS LIST PROVIDER (PER BUILDING)
// =============================================================================

/// Provider for managing units list for a specific building
class UnitsNotifier extends StateNotifier<UnitsState> {
  final UnitRepository _repository;
  final String buildingId;
  static const int _pageSize = 20;

  UnitsNotifier(this._repository, this.buildingId) : super(const UnitsState());

  /// Load initial units for the building
  Future<void> loadUnits() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final units = await _repository.getUnitsByBuilding(
        buildingId: buildingId,
        page: 1,
        limit: _pageSize,
      );
      state = UnitsState(
        units: units,
        isLoading: false,
        hasMore: units.length >= _pageSize,
        currentPage: 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load more units (pagination)
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final nextPage = state.currentPage + 1;
      final newUnits = await _repository.getUnitsByBuilding(
        buildingId: buildingId,
        page: nextPage,
        limit: _pageSize,
      );

      state = state.copyWith(
        units: [...state.units, ...newUnits],
        isLoading: false,
        hasMore: newUnits.length >= _pageSize,
        currentPage: nextPage,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh the units list
  Future<void> refresh() async {
    state = const UnitsState();
    await loadUnits();
  }

  /// Add a newly created unit to the list
  void addUnit(Unit unit) {
    state = state.copyWith(
      units: [unit, ...state.units],
    );
  }

  /// Update a unit in the list
  void updateUnit(Unit unit) {
    final index = state.units.indexWhere((u) => u.id == unit.id);
    if (index != -1) {
      final updatedList = List<Unit>.from(state.units);
      updatedList[index] = unit;
      state = state.copyWith(units: updatedList);
    }
  }

  /// Remove a unit from the list
  void removeUnit(String id) {
    state = state.copyWith(
      units: state.units.where((u) => u.id != id).toList(),
    );
  }
}

/// Provider family for UnitsNotifier - creates one notifier per building
final unitsByBuildingProvider = StateNotifierProvider.family<UnitsNotifier, UnitsState, String>(
  (ref, buildingId) {
    return UnitsNotifier(ref.read(unitRepositoryProvider), buildingId);
  },
);

// =============================================================================
// SINGLE UNIT PROVIDER
// =============================================================================

/// Provider for fetching a single unit by ID
final unitByIdProvider = FutureProvider.family<Unit, String>((ref, id) async {
  final repository = ref.read(unitRepositoryProvider);
  return repository.getUnitById(id);
});

// =============================================================================
// CREATE UNIT PROVIDER
// =============================================================================

/// State for unit creation
class CreateUnitState {
  final bool isLoading;
  final bool isUploadingPhoto;
  final List<String> photoUrls;
  final String? error;
  final Unit? createdUnit;

  const CreateUnitState({
    this.isLoading = false,
    this.isUploadingPhoto = false,
    this.photoUrls = const [],
    this.error,
    this.createdUnit,
  });

  CreateUnitState copyWith({
    bool? isLoading,
    bool? isUploadingPhoto,
    List<String>? photoUrls,
    String? error,
    Unit? createdUnit,
  }) {
    return CreateUnitState(
      isLoading: isLoading ?? this.isLoading,
      isUploadingPhoto: isUploadingPhoto ?? this.isUploadingPhoto,
      photoUrls: photoUrls ?? this.photoUrls,
      error: error,
      createdUnit: createdUnit ?? this.createdUnit,
    );
  }
}

/// Notifier for unit creation
class CreateUnitNotifier extends StateNotifier<CreateUnitState> {
  final UnitRepository _repository;

  CreateUnitNotifier(this._repository) : super(const CreateUnitState());

  /// Upload a photo for the unit
  Future<void> uploadPhoto(String unitId, Uint8List imageBytes, String fileName) async {
    state = state.copyWith(isUploadingPhoto: true, error: null);

    try {
      final url = await _repository.uploadPhoto(
        unitId: unitId,
        imageBytes: imageBytes,
        fileName: fileName,
      );
      state = state.copyWith(
        isUploadingPhoto: false,
        photoUrls: [...state.photoUrls, url],
      );
    } catch (e) {
      state = state.copyWith(
        isUploadingPhoto: false,
        error: e.toString(),
      );
    }
  }

  /// Remove a photo from the list
  void removePhoto(String url) {
    state = state.copyWith(
      photoUrls: state.photoUrls.where((u) => u != url).toList(),
    );
  }

  /// Clear all photos
  void clearPhotos() {
    state = state.copyWith(photoUrls: []);
  }

  /// Create a new unit
  Future<Unit?> createUnit({
    required String buildingId,
    required String reference,
    required double baseRent,
    String type = 'residential',
    int? floor,
    double? surfaceArea,
    int? roomsCount,
    double chargesAmount = 0,
    bool chargesIncluded = false,
    String? description,
    List<String> equipment = const [],
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final unit = await _repository.createUnit(
        buildingId: buildingId,
        reference: reference,
        baseRent: baseRent,
        type: type,
        floor: floor,
        surfaceArea: surfaceArea,
        roomsCount: roomsCount,
        chargesAmount: chargesAmount,
        chargesIncluded: chargesIncluded,
        description: description,
        equipment: equipment,
      );

      state = state.copyWith(
        isLoading: false,
        createdUnit: unit,
      );

      return unit;
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
    state = const CreateUnitState();
  }
}

/// Provider for CreateUnitNotifier
final createUnitProvider =
    StateNotifierProvider<CreateUnitNotifier, CreateUnitState>((ref) {
  return CreateUnitNotifier(ref.read(unitRepositoryProvider));
});

// =============================================================================
// EDIT UNIT PROVIDER
// =============================================================================

/// State for unit editing
class EditUnitState {
  final bool isLoading;
  final bool isUploadingPhoto;
  final List<String> newPhotoUrls;
  final String? error;
  final Unit? updatedUnit;

  const EditUnitState({
    this.isLoading = false,
    this.isUploadingPhoto = false,
    this.newPhotoUrls = const [],
    this.error,
    this.updatedUnit,
  });

  EditUnitState copyWith({
    bool? isLoading,
    bool? isUploadingPhoto,
    List<String>? newPhotoUrls,
    String? error,
    Unit? updatedUnit,
  }) {
    return EditUnitState(
      isLoading: isLoading ?? this.isLoading,
      isUploadingPhoto: isUploadingPhoto ?? this.isUploadingPhoto,
      newPhotoUrls: newPhotoUrls ?? this.newPhotoUrls,
      error: error,
      updatedUnit: updatedUnit ?? this.updatedUnit,
    );
  }
}

/// Notifier for unit editing
class EditUnitNotifier extends StateNotifier<EditUnitState> {
  final UnitRepository _repository;

  EditUnitNotifier(this._repository) : super(const EditUnitState());

  /// Upload a new photo for the unit
  Future<void> uploadPhoto(String unitId, Uint8List imageBytes, String fileName) async {
    state = state.copyWith(isUploadingPhoto: true, error: null);

    try {
      final url = await _repository.uploadPhoto(
        unitId: unitId,
        imageBytes: imageBytes,
        fileName: fileName,
      );
      state = state.copyWith(
        isUploadingPhoto: false,
        newPhotoUrls: [...state.newPhotoUrls, url],
      );
    } catch (e) {
      state = state.copyWith(
        isUploadingPhoto: false,
        error: e.toString(),
      );
    }
  }

  /// Remove a new photo
  void removeNewPhoto(String url) {
    state = state.copyWith(
      newPhotoUrls: state.newPhotoUrls.where((u) => u != url).toList(),
    );
  }

  /// Delete a photo from storage
  Future<void> deletePhoto(String photoPath) async {
    try {
      await _repository.deletePhoto(photoPath);
    } catch (e) {
      // Ignore delete errors - photo might not exist
    }
  }

  /// Update an existing unit
  Future<Unit?> updateUnit({
    required String id,
    String? reference,
    String? type,
    int? floor,
    double? surfaceArea,
    int? roomsCount,
    double? baseRent,
    double? chargesAmount,
    bool? chargesIncluded,
    String? status,
    String? description,
    List<String>? equipment,
    List<String>? photos,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Merge new photos if any
      final allPhotos = photos != null
          ? [...photos, ...state.newPhotoUrls]
          : (state.newPhotoUrls.isNotEmpty ? state.newPhotoUrls : null);

      final unit = await _repository.updateUnit(
        id: id,
        reference: reference,
        type: type,
        floor: floor,
        surfaceArea: surfaceArea,
        roomsCount: roomsCount,
        baseRent: baseRent,
        chargesAmount: chargesAmount,
        chargesIncluded: chargesIncluded,
        status: status,
        description: description,
        equipment: equipment,
        photos: allPhotos,
      );

      state = state.copyWith(
        isLoading: false,
        updatedUnit: unit,
      );

      return unit;
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
    state = const EditUnitState();
  }
}

/// Provider for EditUnitNotifier
final editUnitProvider =
    StateNotifierProvider<EditUnitNotifier, EditUnitState>((ref) {
  return EditUnitNotifier(ref.read(unitRepositoryProvider));
});

// =============================================================================
// DELETE UNIT PROVIDER
// =============================================================================

/// State for unit deletion
class DeleteUnitState {
  final bool isLoading;
  final String? error;
  final bool isDeleted;

  const DeleteUnitState({
    this.isLoading = false,
    this.error,
    this.isDeleted = false,
  });

  DeleteUnitState copyWith({
    bool? isLoading,
    String? error,
    bool? isDeleted,
  }) {
    return DeleteUnitState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

/// Notifier for unit deletion
class DeleteUnitNotifier extends StateNotifier<DeleteUnitState> {
  final UnitRepository _repository;

  DeleteUnitNotifier(this._repository) : super(const DeleteUnitState());

  /// Delete a unit by ID
  Future<bool> deleteUnit(String id) async {
    state = state.copyWith(isLoading: true, error: null, isDeleted: false);

    try {
      await _repository.deleteUnit(id);

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
    state = const DeleteUnitState();
  }
}

/// Provider for DeleteUnitNotifier
final deleteUnitProvider =
    StateNotifierProvider<DeleteUnitNotifier, DeleteUnitState>((ref) {
  return DeleteUnitNotifier(ref.read(unitRepositoryProvider));
});

// =============================================================================
// PERMISSION PROVIDER
// =============================================================================

/// Provider for checking if user can manage units
final canManageUnitsProvider = FutureProvider<bool>((ref) async {
  final repository = ref.read(unitRepositoryProvider);
  return repository.canManageUnits();
});

// =============================================================================
// UNITS COUNT PROVIDER
// =============================================================================

/// Provider for getting units count for a building
final unitsCountProvider = FutureProvider.family<int, String>((ref, buildingId) async {
  final repository = ref.read(unitRepositoryProvider);
  return repository.getUnitsCount(buildingId);
});

// =============================================================================
// REFERENCE UNIQUENESS PROVIDER
// =============================================================================

/// Parameters for checking reference uniqueness
class ReferenceCheckParams {
  final String buildingId;
  final String reference;
  final String? excludeUnitId;

  const ReferenceCheckParams({
    required this.buildingId,
    required this.reference,
    this.excludeUnitId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReferenceCheckParams &&
          runtimeType == other.runtimeType &&
          buildingId == other.buildingId &&
          reference == other.reference &&
          excludeUnitId == other.excludeUnitId;

  @override
  int get hashCode =>
      buildingId.hashCode ^ reference.hashCode ^ (excludeUnitId?.hashCode ?? 0);
}

/// Provider for checking if a reference is unique within a building
final isReferenceUniqueProvider =
    FutureProvider.family<bool, ReferenceCheckParams>((ref, params) async {
  final repository = ref.read(unitRepositoryProvider);
  return repository.isReferenceUnique(
    buildingId: params.buildingId,
    reference: params.reference,
    excludeUnitId: params.excludeUnitId,
  );
});
