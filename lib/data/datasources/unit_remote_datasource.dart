import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/unit_exceptions.dart';
import '../models/unit_model.dart';

/// Remote datasource for unit operations via Supabase
class UnitRemoteDatasource {
  final SupabaseClient _supabase;

  UnitRemoteDatasource(this._supabase);

  /// Create a new unit
  Future<UnitModel> createUnit(CreateUnitInput input) async {
    try {
      final response = await _supabase
          .from('units')
          .insert(input.toJson())
          .select()
          .single();

      return UnitModel.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        // Unique constraint violation
        throw const UnitDuplicateReferenceException();
      } else if (e.code == '23503') {
        // Foreign key violation - building doesn't exist
        throw const UnitBuildingNotFoundException();
      } else if (e.code == '42501') {
        // Insufficient privilege
        throw const UnitUnauthorizedException();
      }
      throw UnitValidationException(e.message);
    }
  }

  /// Get all units for a building with pagination
  Future<List<UnitModel>> getUnitsByBuilding({
    required String buildingId,
    int page = 1,
    int limit = 20,
  }) async {
    final offset = (page - 1) * limit;

    try {
      final response = await _supabase
          .from('units')
          .select()
          .eq('building_id', buildingId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => UnitModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw UnitValidationException(e.message);
    }
  }

  /// Get unit by ID
  Future<UnitModel> getUnitById(String id) async {
    try {
      final response = await _supabase
          .from('units')
          .select()
          .eq('id', id)
          .single();

      return UnitModel.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw const UnitNotFoundException();
      } else if (e.code == '42501') {
        throw const UnitUnauthorizedException();
      }
      throw UnitValidationException(e.message);
    }
  }

  /// Update unit
  Future<UnitModel> updateUnit({
    required String id,
    required UpdateUnitInput input,
  }) async {
    try {
      final updateMap = input.toUpdateMap();
      if (updateMap.isEmpty) {
        // Nothing to update, return current unit
        return getUnitById(id);
      }

      final response = await _supabase
          .from('units')
          .update(updateMap)
          .eq('id', id)
          .select()
          .single();

      return UnitModel.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw const UnitNotFoundException();
      } else if (e.code == '23505') {
        throw const UnitDuplicateReferenceException();
      } else if (e.code == '42501') {
        throw const UnitUnauthorizedException();
      }
      throw UnitValidationException(e.message);
    }
  }

  /// Delete unit
  Future<void> deleteUnit(String id) async {
    try {
      await _supabase.from('units').delete().eq('id', id);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw const UnitNotFoundException();
      } else if (e.code == '23503') {
        // Foreign key violation - has active leases
        throw const UnitHasActiveLeaseException();
      } else if (e.code == '42501') {
        throw const UnitUnauthorizedException();
      }
      throw UnitValidationException(e.message);
    }
  }

  /// Upload photo to storage
  Future<String> uploadPhoto({
    required String unitId,
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    try {
      final path =
          'units/$unitId/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      await _supabase.storage.from('photos').uploadBinary(path, imageBytes);

      // Get signed URL valid for 1 year (365 days = 31536000 seconds)
      final signedUrl =
          await _supabase.storage.from('photos').createSignedUrl(path, 31536000);

      return signedUrl;
    } on StorageException {
      throw UnitPhotoUploadException();
    }
  }

  /// Delete photo from storage
  Future<void> deletePhoto(String photoPath) async {
    try {
      await _supabase.storage.from('photos').remove([photoPath]);
    } on StorageException {
      // Ignore errors when deleting - photo might not exist
    }
  }

  /// Get units count for a building
  Future<int> getUnitsCount(String buildingId) async {
    try {
      final response = await _supabase
          .from('units')
          .select('id')
          .eq('building_id', buildingId);

      return (response as List).length;
    } on PostgrestException {
      return 0;
    }
  }

  /// Check if user can manage units (based on role)
  Future<bool> canManageUnits() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .single();

      final role = response['role'] as String?;
      // Assistant role is read-only
      return role == 'admin' || role == 'gestionnaire';
    } catch (e) {
      return false;
    }
  }

  /// Check if reference is unique within building
  Future<bool> isReferenceUnique({
    required String buildingId,
    required String reference,
    String? excludeUnitId,
  }) async {
    try {
      var query = _supabase
          .from('units')
          .select('id')
          .eq('building_id', buildingId)
          .eq('reference', reference);

      if (excludeUnitId != null) {
        query = query.neq('id', excludeUnitId);
      }

      final response = await query;
      return (response as List).isEmpty;
    } catch (e) {
      return false;
    }
  }
}
