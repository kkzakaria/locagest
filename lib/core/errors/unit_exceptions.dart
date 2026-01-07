// Unit-specific exceptions for error handling
// All messages are in French for user-facing display

abstract class UnitException implements Exception {
  final String message;
  const UnitException(this.message);

  @override
  String toString() => message;
}

/// Thrown when a unit is not found in the database
class UnitNotFoundException extends UnitException {
  const UnitNotFoundException() : super('Lot non trouvé');
}

/// Thrown when user doesn't have access to a unit
class UnitUnauthorizedException extends UnitException {
  const UnitUnauthorizedException()
      : super('Vous n\'avez pas accès à ce lot');
}

/// Thrown when trying to create a unit with a duplicate reference
class UnitDuplicateReferenceException extends UnitException {
  const UnitDuplicateReferenceException()
      : super('Cette référence existe déjà dans cet immeuble');
}

/// Thrown when unit data validation fails
class UnitValidationException extends UnitException {
  const UnitValidationException(super.message);
}

/// Thrown when trying to delete a unit that has an active lease
class UnitHasActiveLeaseException extends UnitException {
  const UnitHasActiveLeaseException()
      : super('Ce lot ne peut pas être supprimé car il a un bail actif');
}

/// Thrown when photo upload fails
class UnitPhotoUploadException extends UnitException {
  const UnitPhotoUploadException()
      : super('Échec du téléchargement de la photo');
}

/// Thrown when photo exceeds size limit
class UnitPhotoTooLargeException extends UnitException {
  const UnitPhotoTooLargeException()
      : super('La photo est trop volumineuse (max 5 Mo)');
}

/// Thrown when the building specified doesn't exist
class UnitBuildingNotFoundException extends UnitException {
  const UnitBuildingNotFoundException()
      : super('L\'immeuble spécifié n\'existe pas');
}
