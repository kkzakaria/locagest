import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/building_exceptions.dart';
import '../models/building_model.dart';

/// Remote datasource for building operations using Supabase
class BuildingRemoteDatasource {
  final SupabaseClient _supabase;

  BuildingRemoteDatasource(this._supabase);

  /// Get current user ID
  String get _currentUserId {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const BuildingUnauthorizedException('accéder aux immeubles');
    }
    return user.id;
  }

  /// Create a new building
  Future<BuildingModel> createBuilding({
    required String name,
    required String address,
    required String city,
    String? postalCode,
    String? country,
    String? photoUrl,
    String? notes,
  }) async {
    try {
      final response = await _supabase
          .from('buildings')
          .insert({
            'name': name.trim(),
            'address': address.trim(),
            'city': city.trim(),
            'postal_code': postalCode?.trim(),
            'country': country ?? "Côte d'Ivoire",
            'photo_url': photoUrl,
            'notes': notes?.trim(),
            'created_by': _currentUserId,
          })
          .select()
          .single();

      return BuildingModel.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == '42501') {
        throw const BuildingUnauthorizedException('créer un immeuble');
      }
      if (e.code == '23514') {
        // Check constraint violation
        throw const BuildingValidationException({
          'general': 'Données invalides. Veuillez vérifier les champs.',
        });
      }
      throw BuildingServerException(e.message);
    } catch (e) {
      throw BuildingServerException(e.toString());
    }
  }

  /// Get buildings with pagination
  Future<List<BuildingModel>> getBuildings({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final offset = (page - 1) * limit;
      final response = await _supabase
          .from('buildings')
          .select()
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => BuildingModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw BuildingServerException(e.message);
    } catch (e) {
      throw BuildingServerException(e.toString());
    }
  }

  /// Get building by ID
  Future<BuildingModel> getBuildingById(String id) async {
    try {
      final response = await _supabase
          .from('buildings')
          .select()
          .eq('id', id)
          .single();

      return BuildingModel.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw const BuildingNotFoundException();
      }
      throw BuildingServerException(e.message);
    } catch (e) {
      throw BuildingServerException(e.toString());
    }
  }

  /// Update building
  Future<BuildingModel> updateBuilding({
    required String id,
    String? name,
    String? address,
    String? city,
    String? postalCode,
    String? country,
    String? photoUrl,
    String? notes,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (name != null) updateData['name'] = name.trim();
      if (address != null) updateData['address'] = address.trim();
      if (city != null) updateData['city'] = city.trim();
      if (postalCode != null) updateData['postal_code'] = postalCode.trim();
      if (country != null) updateData['country'] = country;
      if (photoUrl != null) updateData['photo_url'] = photoUrl;
      if (notes != null) updateData['notes'] = notes.trim();

      if (updateData.isEmpty) {
        return getBuildingById(id);
      }

      final response = await _supabase
          .from('buildings')
          .update(updateData)
          .eq('id', id)
          .select()
          .single();

      return BuildingModel.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw const BuildingNotFoundException();
      }
      if (e.code == '42501') {
        throw const BuildingUnauthorizedException('modifier cet immeuble');
      }
      if (e.code == '23514') {
        throw const BuildingValidationException({
          'general': 'Données invalides. Veuillez vérifier les champs.',
        });
      }
      throw BuildingServerException(e.message);
    } catch (e) {
      throw BuildingServerException(e.toString());
    }
  }

  /// Delete building
  Future<void> deleteBuilding(String id) async {
    try {
      // First check if building has units
      final building = await getBuildingById(id);
      if (building.totalUnits > 0) {
        throw const BuildingHasUnitsException();
      }

      await _supabase.from('buildings').delete().eq('id', id);
    } on BuildingException {
      rethrow;
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw const BuildingNotFoundException();
      }
      if (e.code == '42501') {
        throw const BuildingUnauthorizedException('supprimer cet immeuble');
      }
      if (e.code == '23503') {
        // Foreign key constraint (units exist)
        throw const BuildingHasUnitsException();
      }
      throw BuildingServerException(e.message);
    } catch (e) {
      throw BuildingServerException(e.toString());
    }
  }

  /// Upload and compress photo
  Future<String> uploadPhoto({
    required String buildingId,
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    try {
      // Compress image to max 1MB
      final compressedBytes = await FlutterImageCompress.compressWithList(
        imageBytes,
        minWidth: 1024,
        minHeight: 1024,
        quality: 85,
        format: CompressFormat.jpeg,
      );

      // Generate unique path
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = 'buildings/$_currentUserId/${buildingId}_$timestamp.jpg';

      // Upload to Supabase Storage
      await _supabase.storage.from('photos').uploadBinary(
            path,
            compressedBytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      // Get signed URL (valid for 1 year)
      final signedUrl = await _supabase.storage
          .from('photos')
          .createSignedUrl(path, 60 * 60 * 24 * 365);

      return signedUrl;
    } on StorageException catch (e) {
      if (e.statusCode == '413') {
        throw const BuildingPhotoTooLargeException();
      }
      throw BuildingPhotoUploadException(e.message);
    } catch (e) {
      throw BuildingPhotoUploadException(e.toString());
    }
  }

  /// Delete photo from storage
  Future<void> deletePhoto(String photoPath) async {
    try {
      await _supabase.storage.from('photos').remove([photoPath]);
    } catch (e) {
      // Ignore errors on delete - photo might not exist
    }
  }

  /// Get total buildings count
  Future<int> getBuildingsCount() async {
    try {
      final response = await _supabase
          .from('buildings')
          .select('id')
          .count(CountOption.exact);

      return response.count;
    } catch (e) {
      return 0;
    }
  }

  /// Check if current user can manage buildings
  Future<bool> canManageBuildings() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', _currentUserId)
          .single();

      final role = response['role'] as String?;
      return role == 'admin' || role == 'gestionnaire';
    } catch (e) {
      return false;
    }
  }
}
