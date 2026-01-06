// Building-specific exceptions (Domain layer)
// All messages are in French per constitution requirements

/// Base exception for building operations
class BuildingException implements Exception {
  final String message;
  final String? code;

  const BuildingException(this.message, {this.code});

  @override
  String toString() => message;
}

/// Thrown when a building is not found
class BuildingNotFoundException extends BuildingException {
  const BuildingNotFoundException()
      : super('Immeuble non trouvé.', code: 'BUILDING_NOT_FOUND');
}

/// Thrown when trying to delete a building that has units
class BuildingHasUnitsException extends BuildingException {
  const BuildingHasUnitsException()
      : super(
          'Impossible de supprimer cet immeuble car il contient des lots.',
          code: 'BUILDING_HAS_UNITS',
        );
}

/// Thrown when user doesn't have permission for the operation
class BuildingUnauthorizedException extends BuildingException {
  const BuildingUnauthorizedException([String? operation])
      : super(
          operation != null
              ? "Vous n'avez pas les droits pour $operation."
              : "Vous n'avez pas les droits pour cette opération.",
          code: 'BUILDING_UNAUTHORIZED',
        );
}

/// Thrown when building data validation fails
class BuildingValidationException extends BuildingException {
  final Map<String, String> fieldErrors;

  const BuildingValidationException(this.fieldErrors)
      : super(
          'Données invalides. Veuillez vérifier les champs.',
          code: 'BUILDING_VALIDATION_ERROR',
        );

  /// Get error message for a specific field
  String? getFieldError(String field) => fieldErrors[field];

  /// Check if a specific field has an error
  bool hasFieldError(String field) => fieldErrors.containsKey(field);
}

/// Thrown when photo upload fails
class BuildingPhotoUploadException extends BuildingException {
  const BuildingPhotoUploadException([String? details])
      : super(
          details ?? 'Échec du téléchargement de la photo. Veuillez réessayer.',
          code: 'PHOTO_UPLOAD_FAILED',
        );
}

/// Thrown when photo is too large
class BuildingPhotoTooLargeException extends BuildingException {
  const BuildingPhotoTooLargeException()
      : super(
          "L'image est trop volumineuse. Maximum 5 Mo.",
          code: 'PHOTO_TOO_LARGE',
        );
}

/// Thrown when photo format is not supported
class BuildingPhotoInvalidFormatException extends BuildingException {
  const BuildingPhotoInvalidFormatException()
      : super(
          "Format d'image non supporté. Utilisez JPG ou PNG.",
          code: 'PHOTO_INVALID_FORMAT',
        );
}

/// Thrown when network error occurs during building operations
class BuildingNetworkException extends BuildingException {
  const BuildingNetworkException([String? details])
      : super(
          details ?? 'Erreur réseau. Veuillez vérifier votre connexion.',
          code: 'NETWORK_ERROR',
        );
}

/// Thrown when a generic server error occurs
class BuildingServerException extends BuildingException {
  const BuildingServerException([String? details])
      : super(
          details ?? "Une erreur s'est produite. Veuillez réessayer.",
          code: 'SERVER_ERROR',
        );
}
