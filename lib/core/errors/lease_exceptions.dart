/// Lease module exceptions
///
/// All exceptions are in French for user display.
library;

/// Base exception for all lease-related errors.
abstract class LeaseException implements Exception {
  final String message;
  const LeaseException(this.message);

  @override
  String toString() => message;
}

/// Thrown when a lease is not found in the database.
class LeaseNotFoundException extends LeaseException {
  const LeaseNotFoundException() : super('Bail non trouvé');
}

/// Thrown when user doesn't have permission to perform the operation.
class LeaseUnauthorizedException extends LeaseException {
  const LeaseUnauthorizedException()
      : super("Vous n'avez pas la permission d'effectuer cette action");
}

/// Thrown when lease data validation fails.
class LeaseValidationException extends LeaseException {
  const LeaseValidationException(super.message);

  /// Factory for common validation errors
  factory LeaseValidationException.invalidRentAmount() =>
      const LeaseValidationException('Le montant du loyer doit être supérieur à 0');

  factory LeaseValidationException.invalidPaymentDay() =>
      const LeaseValidationException('Le jour de paiement doit être entre 1 et 28');

  factory LeaseValidationException.invalidDates() =>
      const LeaseValidationException('La date de fin doit être après la date de début');

  factory LeaseValidationException.missingRequiredFields() =>
      const LeaseValidationException('Veuillez remplir tous les champs obligatoires');

  factory LeaseValidationException.tenantNotFound() =>
      const LeaseValidationException('Locataire non trouvé');

  factory LeaseValidationException.unitNotFound() =>
      const LeaseValidationException('Lot non trouvé');
}

/// Thrown when trying to create a lease for a unit that already has an active lease.
class LeaseUnitOccupiedException extends LeaseException {
  const LeaseUnitOccupiedException() : super('Ce lot a déjà un bail actif');
}

/// Thrown when trying to terminate a lease that cannot be terminated.
class LeaseCannotBeTerminatedException extends LeaseException {
  const LeaseCannotBeTerminatedException()
      : super('Ce bail ne peut pas être résilié');

  /// Factory for specific reasons
  factory LeaseCannotBeTerminatedException.alreadyTerminated() =>
      const LeaseCannotBeTerminatedException();

  factory LeaseCannotBeTerminatedException.alreadyExpired() =>
      const LeaseCannotBeTerminatedException();
}

/// Thrown when trying to delete a lease that cannot be deleted.
class LeaseCannotBeDeletedException extends LeaseException {
  const LeaseCannotBeDeletedException()
      : super('Seuls les baux en attente peuvent être supprimés');
}

/// Thrown when a rent schedule is not found.
class RentScheduleNotFoundException extends LeaseException {
  const RentScheduleNotFoundException() : super('Échéance non trouvée');
}

/// Thrown when trying to modify a paid rent schedule.
class RentScheduleAlreadyPaidException extends LeaseException {
  const RentScheduleAlreadyPaidException()
      : super('Cette échéance a déjà été payée et ne peut pas être modifiée');
}
