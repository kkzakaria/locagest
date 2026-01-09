/// Payment module exceptions
///
/// All exceptions are in French for user display.
library;

/// Base exception for all payment-related errors.
abstract class PaymentException implements Exception {
  final String message;
  const PaymentException(this.message);

  @override
  String toString() => message;
}

/// Thrown when a payment is not found in the database.
class PaymentNotFoundException extends PaymentException {
  const PaymentNotFoundException() : super('Paiement non trouvé');
}

/// Thrown when user doesn't have permission to perform the operation.
class PaymentUnauthorizedException extends PaymentException {
  const PaymentUnauthorizedException()
      : super("Vous n'avez pas la permission d'effectuer cette action");
}

/// Thrown when payment data validation fails.
class PaymentValidationException extends PaymentException {
  const PaymentValidationException(super.message);

  /// Factory for common validation errors
  factory PaymentValidationException.invalidAmount() =>
      const PaymentValidationException('Le montant doit être supérieur à 0');

  factory PaymentValidationException.amountExceedsBalance(double balance) =>
      PaymentValidationException(
          'Le montant dépasse le solde restant (${balance.toStringAsFixed(0)} FCFA)');

  factory PaymentValidationException.missingCheckNumber() =>
      const PaymentValidationException(
          'Le numéro de chèque est requis pour un paiement par chèque');

  factory PaymentValidationException.missingReference() =>
      const PaymentValidationException(
          'La référence est requise pour ce mode de paiement');

  factory PaymentValidationException.scheduleNotFound() =>
      const PaymentValidationException('Échéance non trouvée');

  factory PaymentValidationException.scheduleCancelled() =>
      const PaymentValidationException(
          'Impossible d\'enregistrer un paiement sur une échéance annulée');

  factory PaymentValidationException.scheduleAlreadyPaid() =>
      const PaymentValidationException('Cette échéance est déjà entièrement payée');
}

/// Thrown when trying to modify a payment that cannot be modified.
class PaymentCannotBeModifiedException extends PaymentException {
  const PaymentCannotBeModifiedException()
      : super('Ce paiement ne peut pas être modifié');
}

/// Thrown when trying to delete a payment that cannot be deleted.
class PaymentCannotBeDeletedException extends PaymentException {
  const PaymentCannotBeDeletedException()
      : super('Ce paiement ne peut pas être supprimé');
}
