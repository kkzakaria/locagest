import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/building_remote_datasource.dart';
import '../../data/repositories/building_repository_impl.dart';
import '../../domain/entities/building.dart';
import '../../domain/repositories/building_repository.dart';
import '../../domain/usecases/create_building.dart';
import '../../domain/usecases/delete_building.dart';
import '../../domain/usecases/update_building.dart';
import '../../domain/usecases/upload_building_photo.dart';

// =============================================================================
// DEPENDENCY PROVIDERS
// =============================================================================

/// Provider for BuildingRemoteDatasource
final buildingDatasourceProvider = Provider<BuildingRemoteDatasource>((ref) {
  return BuildingRemoteDatasource(Supabase.instance.client);
});

/// Provider for BuildingRepository
final buildingRepositoryProvider = Provider<BuildingRepository>((ref) {
  return BuildingRepositoryImpl(ref.read(buildingDatasourceProvider));
});

/// Provider for CreateBuilding use case
final createBuildingUseCaseProvider = Provider<CreateBuilding>((ref) {
  return CreateBuilding(ref.read(buildingRepositoryProvider));
});

/// Provider for UploadBuildingPhoto use case
final uploadBuildingPhotoUseCaseProvider = Provider<UploadBuildingPhoto>((ref) {
  return UploadBuildingPhoto(ref.read(buildingRepositoryProvider));
});

/// Provider for UpdateBuilding use case
final updateBuildingUseCaseProvider = Provider<UpdateBuilding>((ref) {
  return UpdateBuilding(ref.read(buildingRepositoryProvider));
});

/// Provider for DeleteBuilding use case
final deleteBuildingUseCaseProvider = Provider<DeleteBuilding>((ref) {
  return DeleteBuilding(ref.read(buildingRepositoryProvider));
});

// =============================================================================
// STATE CLASSES
// =============================================================================

/// State for the buildings list
class BuildingsState {
  final List<Building> buildings;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? error;

  const BuildingsState({
    this.buildings = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.error,
  });

  BuildingsState copyWith({
    List<Building>? buildings,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) {
    return BuildingsState(
      buildings: buildings ?? this.buildings,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
    );
  }
}

// =============================================================================
// BUILDINGS LIST PROVIDER
// =============================================================================

/// Provider for managing the buildings list
class BuildingsNotifier extends StateNotifier<BuildingsState> {
  final BuildingRepository _repository;
  static const int _pageSize = 20;

  BuildingsNotifier(this._repository) : super(const BuildingsState());

  /// Load initial buildings
  Future<void> loadBuildings() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final buildings = await _repository.getBuildings(page: 1, limit: _pageSize);
      state = BuildingsState(
        buildings: buildings,
        isLoading: false,
        hasMore: buildings.length >= _pageSize,
        currentPage: 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load more buildings (pagination)
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final nextPage = state.currentPage + 1;
      final newBuildings = await _repository.getBuildings(
        page: nextPage,
        limit: _pageSize,
      );

      state = state.copyWith(
        buildings: [...state.buildings, ...newBuildings],
        isLoading: false,
        hasMore: newBuildings.length >= _pageSize,
        currentPage: nextPage,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh the buildings list
  Future<void> refresh() async {
    state = const BuildingsState();
    await loadBuildings();
  }

  /// Add a newly created building to the list
  void addBuilding(Building building) {
    state = state.copyWith(
      buildings: [building, ...state.buildings],
    );
  }

  /// Update a building in the list
  void updateBuilding(Building building) {
    final index = state.buildings.indexWhere((b) => b.id == building.id);
    if (index != -1) {
      final updatedList = List<Building>.from(state.buildings);
      updatedList[index] = building;
      state = state.copyWith(buildings: updatedList);
    }
  }

  /// Remove a building from the list
  void removeBuilding(String id) {
    state = state.copyWith(
      buildings: state.buildings.where((b) => b.id != id).toList(),
    );
  }
}

/// Provider for BuildingsNotifier
final buildingsProvider =
    StateNotifierProvider<BuildingsNotifier, BuildingsState>((ref) {
  return BuildingsNotifier(ref.read(buildingRepositoryProvider));
});

// =============================================================================
// SINGLE BUILDING PROVIDER
// =============================================================================

/// Provider for fetching a single building by ID
final buildingByIdProvider =
    FutureProvider.family<Building, String>((ref, id) async {
  final repository = ref.read(buildingRepositoryProvider);
  return repository.getBuildingById(id);
});

// =============================================================================
// CREATE BUILDING PROVIDER
// =============================================================================

/// State for building creation
class CreateBuildingState {
  final bool isLoading;
  final bool isUploadingPhoto;
  final String? photoUrl;
  final String? error;
  final Building? createdBuilding;

  const CreateBuildingState({
    this.isLoading = false,
    this.isUploadingPhoto = false,
    this.photoUrl,
    this.error,
    this.createdBuilding,
  });

  CreateBuildingState copyWith({
    bool? isLoading,
    bool? isUploadingPhoto,
    String? photoUrl,
    String? error,
    Building? createdBuilding,
  }) {
    return CreateBuildingState(
      isLoading: isLoading ?? this.isLoading,
      isUploadingPhoto: isUploadingPhoto ?? this.isUploadingPhoto,
      photoUrl: photoUrl ?? this.photoUrl,
      error: error,
      createdBuilding: createdBuilding ?? this.createdBuilding,
    );
  }
}

/// Notifier for building creation
class CreateBuildingNotifier extends StateNotifier<CreateBuildingState> {
  final CreateBuilding _createBuilding;
  final UploadBuildingPhoto _uploadPhoto;
  final BuildingsNotifier _buildingsNotifier;

  CreateBuildingNotifier(
    this._createBuilding,
    this._uploadPhoto,
    this._buildingsNotifier,
  ) : super(const CreateBuildingState());

  /// Upload a photo before creating the building
  Future<void> uploadPhoto(Uint8List imageBytes, String fileName) async {
    state = state.copyWith(isUploadingPhoto: true, error: null);

    try {
      final url = await _uploadPhoto.call(
        buildingId: 'new',
        imageBytes: imageBytes,
        fileName: fileName,
      );
      state = state.copyWith(isUploadingPhoto: false, photoUrl: url);
    } catch (e) {
      state = state.copyWith(
        isUploadingPhoto: false,
        error: e.toString(),
      );
    }
  }

  /// Remove the uploaded photo
  void removePhoto() {
    state = state.copyWith(photoUrl: null);
  }

  /// Create a new building
  Future<Building?> createBuilding({
    required String name,
    required String address,
    required String city,
    String? postalCode,
    String? country,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final building = await _createBuilding.call(
        name: name,
        address: address,
        city: city,
        postalCode: postalCode,
        country: country,
        photoUrl: state.photoUrl,
        notes: notes,
      );

      // Add to the buildings list
      _buildingsNotifier.addBuilding(building);

      state = state.copyWith(
        isLoading: false,
        createdBuilding: building,
      );

      return building;
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
    state = const CreateBuildingState();
  }
}

/// Provider for CreateBuildingNotifier
final createBuildingProvider =
    StateNotifierProvider<CreateBuildingNotifier, CreateBuildingState>((ref) {
  return CreateBuildingNotifier(
    ref.read(createBuildingUseCaseProvider),
    ref.read(uploadBuildingPhotoUseCaseProvider),
    ref.read(buildingsProvider.notifier),
  );
});

// =============================================================================
// EDIT BUILDING PROVIDER
// =============================================================================

/// State for building editing
class EditBuildingState {
  final bool isLoading;
  final bool isUploadingPhoto;
  final String? newPhotoUrl;
  final String? error;
  final Building? updatedBuilding;

  const EditBuildingState({
    this.isLoading = false,
    this.isUploadingPhoto = false,
    this.newPhotoUrl,
    this.error,
    this.updatedBuilding,
  });

  EditBuildingState copyWith({
    bool? isLoading,
    bool? isUploadingPhoto,
    String? newPhotoUrl,
    String? error,
    Building? updatedBuilding,
    bool clearPhotoUrl = false,
  }) {
    return EditBuildingState(
      isLoading: isLoading ?? this.isLoading,
      isUploadingPhoto: isUploadingPhoto ?? this.isUploadingPhoto,
      newPhotoUrl: clearPhotoUrl ? null : (newPhotoUrl ?? this.newPhotoUrl),
      error: error,
      updatedBuilding: updatedBuilding ?? this.updatedBuilding,
    );
  }
}

/// Notifier for building editing
class EditBuildingNotifier extends StateNotifier<EditBuildingState> {
  final UpdateBuilding _updateBuilding;
  final UploadBuildingPhoto _uploadPhoto;
  final BuildingsNotifier _buildingsNotifier;

  EditBuildingNotifier(
    this._updateBuilding,
    this._uploadPhoto,
    this._buildingsNotifier,
  ) : super(const EditBuildingState());

  /// Upload a new photo for the building
  Future<void> uploadPhoto(String buildingId, Uint8List imageBytes, String fileName) async {
    state = state.copyWith(isUploadingPhoto: true, error: null);

    try {
      final url = await _uploadPhoto.call(
        buildingId: buildingId,
        imageBytes: imageBytes,
        fileName: fileName,
      );
      state = state.copyWith(isUploadingPhoto: false, newPhotoUrl: url);
    } catch (e) {
      state = state.copyWith(
        isUploadingPhoto: false,
        error: e.toString(),
      );
    }
  }

  /// Remove the new photo (revert to existing or no photo)
  void removeNewPhoto() {
    state = state.copyWith(clearPhotoUrl: true);
  }

  /// Update an existing building
  Future<Building?> updateBuilding({
    required String id,
    String? name,
    String? address,
    String? city,
    String? postalCode,
    String? country,
    String? notes,
    bool useNewPhoto = false,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final building = await _updateBuilding.call(
        id: id,
        name: name,
        address: address,
        city: city,
        postalCode: postalCode,
        country: country,
        photoUrl: useNewPhoto ? state.newPhotoUrl : null,
        notes: notes,
      );

      // Update in the buildings list with optimistic update
      _buildingsNotifier.updateBuilding(building);

      state = state.copyWith(
        isLoading: false,
        updatedBuilding: building,
      );

      return building;
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
    state = const EditBuildingState();
  }
}

/// Provider for EditBuildingNotifier
final editBuildingProvider =
    StateNotifierProvider<EditBuildingNotifier, EditBuildingState>((ref) {
  return EditBuildingNotifier(
    ref.read(updateBuildingUseCaseProvider),
    ref.read(uploadBuildingPhotoUseCaseProvider),
    ref.read(buildingsProvider.notifier),
  );
});

// =============================================================================
// DELETE BUILDING PROVIDER
// =============================================================================

/// State for building deletion
class DeleteBuildingState {
  final bool isLoading;
  final String? error;
  final bool isDeleted;

  const DeleteBuildingState({
    this.isLoading = false,
    this.error,
    this.isDeleted = false,
  });

  DeleteBuildingState copyWith({
    bool? isLoading,
    String? error,
    bool? isDeleted,
  }) {
    return DeleteBuildingState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

/// Notifier for building deletion
class DeleteBuildingNotifier extends StateNotifier<DeleteBuildingState> {
  final DeleteBuilding _deleteBuilding;
  final BuildingsNotifier _buildingsNotifier;

  DeleteBuildingNotifier(
    this._deleteBuilding,
    this._buildingsNotifier,
  ) : super(const DeleteBuildingState());

  /// Delete a building by ID
  Future<bool> deleteBuilding(String id) async {
    state = state.copyWith(isLoading: true, error: null, isDeleted: false);

    try {
      await _deleteBuilding.call(id);

      // Remove from the buildings list
      _buildingsNotifier.removeBuilding(id);

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
    state = const DeleteBuildingState();
  }
}

/// Provider for DeleteBuildingNotifier
final deleteBuildingProvider =
    StateNotifierProvider<DeleteBuildingNotifier, DeleteBuildingState>((ref) {
  return DeleteBuildingNotifier(
    ref.read(deleteBuildingUseCaseProvider),
    ref.read(buildingsProvider.notifier),
  );
});

// =============================================================================
// PERMISSION PROVIDER
// =============================================================================

/// Provider for checking if user can manage buildings
final canManageBuildingsProvider = FutureProvider<bool>((ref) async {
  final repository = ref.read(buildingRepositoryProvider);
  return repository.canManageBuildings();
});
