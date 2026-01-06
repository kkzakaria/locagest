import '../constants/app_constants.dart';

/// Validation utilities for authentication forms
class Validators {
  Validators._();

  /// Email validation regex pattern
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Password validation regex pattern (8+ chars, 1 number, 1 special char)
  static final RegExp _passwordRegex = RegExp(
    AppConstants.passwordPattern,
  );

  /// Validates email format
  /// Returns null if valid, French error message if invalid
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre email';
    }
    if (!_emailRegex.hasMatch(value)) {
      return 'Veuillez entrer une adresse email valide';
    }
    return null;
  }

  /// Validates password meets requirements
  /// Returns null if valid, French error message if invalid
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre mot de passe';
    }
    if (value.length < AppConstants.minPasswordLength) {
      return 'Le mot de passe doit contenir au moins ${AppConstants.minPasswordLength} caracteres';
    }
    if (!_passwordRegex.hasMatch(value)) {
      return 'Le mot de passe doit contenir au moins un chiffre et un caractere special';
    }
    return null;
  }

  /// Validates password confirmation matches
  /// Returns null if valid, French error message if invalid
  static String? validatePasswordConfirmation(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Veuillez confirmer votre mot de passe';
    }
    if (value != password) {
      return 'Les mots de passe ne correspondent pas';
    }
    return null;
  }

  /// Validates full name is not empty
  /// Returns null if valid, French error message if invalid
  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Veuillez entrer votre nom complet';
    }
    if (value.trim().length < 2) {
      return 'Le nom doit contenir au moins 2 caracteres';
    }
    return null;
  }

  /// Check if email format is valid (returns bool)
  static bool isValidEmail(String email) {
    return _emailRegex.hasMatch(email);
  }

  /// Check if password meets all requirements (returns bool)
  static bool isValidPassword(String password) {
    return password.length >= AppConstants.minPasswordLength &&
        _passwordRegex.hasMatch(password);
  }

  /// Get password strength indicators
  static PasswordStrength getPasswordStrength(String password) {
    return PasswordStrength(
      hasMinLength: password.length >= AppConstants.minPasswordLength,
      hasNumber: RegExp(r'[0-9]').hasMatch(password),
      hasSpecialChar: RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password),
    );
  }
}

/// Password strength indicator
class PasswordStrength {
  final bool hasMinLength;
  final bool hasNumber;
  final bool hasSpecialChar;

  const PasswordStrength({
    required this.hasMinLength,
    required this.hasNumber,
    required this.hasSpecialChar,
  });

  bool get isValid => hasMinLength && hasNumber && hasSpecialChar;

  int get score {
    int s = 0;
    if (hasMinLength) s++;
    if (hasNumber) s++;
    if (hasSpecialChar) s++;
    return s;
  }
}

// ============================================================================
// BUILDING VALIDATORS
// ============================================================================

/// Validation utilities for building forms
class BuildingValidators {
  BuildingValidators._();

  /// Maximum lengths for building fields
  static const int maxNameLength = 100;
  static const int maxAddressLength = 200;
  static const int maxCityLength = 100;
  static const int maxPostalCodeLength = 20;
  static const int maxNotesLength = 1000;

  /// Maximum photo size in bytes (5MB before compression)
  static const int maxPhotoSizeBytes = 5 * 1024 * 1024;

  /// Validates building name
  /// Returns null if valid, French error message if invalid
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Le nom de l'immeuble est requis";
    }
    if (value.trim().length > maxNameLength) {
      return 'Le nom ne peut pas dépasser $maxNameLength caractères';
    }
    return null;
  }

  /// Validates building address
  /// Returns null if valid, French error message if invalid
  static String? validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "L'adresse est requise";
    }
    if (value.trim().length > maxAddressLength) {
      return "L'adresse ne peut pas dépasser $maxAddressLength caractères";
    }
    return null;
  }

  /// Validates building city
  /// Returns null if valid, French error message if invalid
  static String? validateCity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La ville est requise';
    }
    if (value.trim().length > maxCityLength) {
      return 'Le nom de la ville ne peut pas dépasser $maxCityLength caractères';
    }
    return null;
  }

  /// Validates building postal code (optional)
  /// Returns null if valid, French error message if invalid
  static String? validatePostalCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    if (value.trim().length > maxPostalCodeLength) {
      return 'Le code postal ne peut pas dépasser $maxPostalCodeLength caractères';
    }
    return null;
  }

  /// Validates building notes (optional)
  /// Returns null if valid, French error message if invalid
  static String? validateNotes(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    if (value.trim().length > maxNotesLength) {
      return 'Les notes ne peuvent pas dépasser $maxNotesLength caractères';
    }
    return null;
  }

  /// Validates photo size before upload
  /// Returns null if valid, French error message if invalid
  static String? validatePhotoSize(int sizeInBytes) {
    if (sizeInBytes > maxPhotoSizeBytes) {
      return "L'image est trop volumineuse. Maximum 5 Mo.";
    }
    return null;
  }

  /// Check if all required fields are valid
  static bool isValidBuilding({
    required String? name,
    required String? address,
    required String? city,
  }) {
    return validateName(name) == null &&
        validateAddress(address) == null &&
        validateCity(city) == null;
  }
}
