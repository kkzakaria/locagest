/// Base class for authentication exceptions
/// Named AppAuthException to avoid conflict with Supabase's AuthException
sealed class AppAuthException implements Exception {
  const AppAuthException();

  /// French user-facing error message
  String get messageFr;
}

/// Invalid email or password during login
class InvalidCredentialsException extends AppAuthException {
  const InvalidCredentialsException();

  @override
  String get messageFr => 'Email ou mot de passe incorrect';
}

/// Email already registered during signup
class EmailAlreadyInUseException extends AppAuthException {
  const EmailAlreadyInUseException();

  @override
  String get messageFr => 'Cette adresse email est deja utilisee';
}

/// Password does not meet requirements
class WeakPasswordException extends AppAuthException {
  final bool tooShort;
  final bool missingNumberOrSpecial;

  const WeakPasswordException({
    this.tooShort = false,
    this.missingNumberOrSpecial = false,
  });

  @override
  String get messageFr {
    if (tooShort) {
      return 'Le mot de passe doit contenir au moins 8 caracteres';
    }
    if (missingNumberOrSpecial) {
      return 'Le mot de passe doit contenir au moins un chiffre et un caractere special';
    }
    return 'Le mot de passe ne respecte pas les exigences de securite';
  }
}

/// Account is locked due to too many failed attempts
class AccountLockedException extends AppAuthException {
  final DateTime? lockedUntil;

  const AccountLockedException({this.lockedUntil});

  int get minutesRemaining {
    if (lockedUntil == null) return 15; // Default lockout duration
    final now = DateTime.now();
    if (lockedUntil!.isBefore(now)) return 0;
    return lockedUntil!.difference(now).inMinutes + 1;
  }

  @override
  String get messageFr =>
      'Compte temporairement bloque. Reessayez dans $minutesRemaining minutes';
}

/// Network connectivity issue
class NetworkException extends AppAuthException {
  final String? message;

  const NetworkException({this.message});

  @override
  String get messageFr => 'Connexion impossible. Verifiez votre connexion internet';
}

/// Too many requests (rate limited)
class TooManyRequestsException extends AppAuthException {
  const TooManyRequestsException();

  @override
  String get messageFr => 'Trop de tentatives. Veuillez patienter';
}

/// Password reset token has expired
class TokenExpiredException extends AppAuthException {
  const TokenExpiredException();

  @override
  String get messageFr => 'Ce lien a expire. Veuillez demander un nouveau lien';
}

/// Session has expired
class SessionExpiredException extends AppAuthException {
  const SessionExpiredException();

  @override
  String get messageFr => 'Votre session a expire. Veuillez vous reconnecter';
}

/// Invalid email format
class InvalidEmailException extends AppAuthException {
  const InvalidEmailException();

  @override
  String get messageFr => 'Veuillez entrer une adresse email valide';
}

/// User not authorized for this action
class UnauthorizedException extends AppAuthException {
  const UnauthorizedException();

  @override
  String get messageFr => 'Vous n\'avez pas les droits pour cette action';
}

/// Cannot demote the last admin
class LastAdminException extends AppAuthException {
  const LastAdminException();

  @override
  String get messageFr => 'Il doit y avoir au moins un administrateur';
}

/// Cannot delete own account
class CannotDeleteSelfException extends AppAuthException {
  const CannotDeleteSelfException();

  @override
  String get messageFr => 'Vous ne pouvez pas supprimer votre propre compte';
}

/// Generic server error
class ServerException extends AppAuthException {
  final String? details;

  const ServerException({this.details});

  @override
  String get messageFr => 'Une erreur est survenue. Veuillez reessayer';
}

/// Invalid OTP code
class InvalidOtpException extends AppAuthException {
  const InvalidOtpException();

  @override
  String get messageFr => 'Code invalide. Veuillez verifier et reessayer';
}

/// OTP code has expired
class OtpExpiredException extends AppAuthException {
  const OtpExpiredException();

  @override
  String get messageFr => 'Code expire. Veuillez demander un nouveau code';
}

/// Email already confirmed (user trying to verify again)
class EmailAlreadyConfirmedException extends AppAuthException {
  const EmailAlreadyConfirmedException();

  @override
  String get messageFr => 'Cette adresse email est deja verifiee';
}
