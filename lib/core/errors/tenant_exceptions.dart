// Tenant-specific exceptions for error handling
// All messages are in French for user-facing display

abstract class TenantException implements Exception {
  final String message;
  const TenantException(this.message);

  @override
  String toString() => message;
}

/// Thrown when a tenant is not found in the database
class TenantNotFoundException extends TenantException {
  const TenantNotFoundException() : super('Locataire non trouvé');
}

/// Thrown when user doesn't have access to a tenant
class TenantUnauthorizedException extends TenantException {
  const TenantUnauthorizedException()
      : super('Vous n\'avez pas accès à ce locataire');
}

/// Thrown when tenant data validation fails
class TenantValidationException extends TenantException {
  const TenantValidationException(super.message);
}

/// Thrown when trying to delete a tenant that has an active lease
class TenantHasActiveLeaseException extends TenantException {
  const TenantHasActiveLeaseException()
      : super('Ce locataire ne peut pas être supprimé car il a un bail actif');
}

/// Thrown when document upload fails
class TenantDocumentUploadException extends TenantException {
  const TenantDocumentUploadException()
      : super('Échec du téléchargement du document');
}

/// Thrown when document exceeds size limit (5MB)
class TenantDocumentTooLargeException extends TenantException {
  const TenantDocumentTooLargeException()
      : super('Le document est trop volumineux (max 5 Mo)');
}

/// Thrown when document format is not supported
class TenantDocumentInvalidFormatException extends TenantException {
  const TenantDocumentInvalidFormatException()
      : super('Format de document non supporté (JPEG, PNG ou PDF attendu)');
}

/// Thrown when phone format is invalid
class TenantPhoneInvalidException extends TenantException {
  const TenantPhoneInvalidException()
      : super('Format de téléphone invalide');
}

/// Thrown when email format is invalid
class TenantEmailInvalidException extends TenantException {
  const TenantEmailInvalidException()
      : super('Format d\'email invalide');
}

/// Thrown for general server errors
class TenantServerException extends TenantException {
  const TenantServerException([super.message = 'Une erreur serveur est survenue']);
}
