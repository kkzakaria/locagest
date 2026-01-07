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

// ============================================================================
// UNIT VALIDATORS
// ============================================================================

/// Validation utilities for unit forms
class UnitValidators {
  UnitValidators._();

  /// Maximum lengths for unit fields
  static const int maxReferenceLength = 50;
  static const int maxDescriptionLength = 2000;

  /// Maximum photo size in bytes (5MB before compression)
  static const int maxPhotoSizeBytes = 5 * 1024 * 1024;

  /// Validates unit reference
  /// Returns null if valid, French error message if invalid
  static String? validateReference(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La référence est requise';
    }
    if (value.trim().length > maxReferenceLength) {
      return 'La référence ne doit pas dépasser $maxReferenceLength caractères';
    }
    return null;
  }

  /// Validates base rent (required, must be positive)
  /// Returns null if valid, French error message if invalid
  static String? validateBaseRent(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le loyer de base est requis';
    }
    // Remove spaces for parsing (French thousand separator)
    final cleanValue = value.replaceAll(' ', '').replaceAll(',', '.');
    final rent = double.tryParse(cleanValue);
    if (rent == null) {
      return 'Le loyer doit être un nombre valide';
    }
    if (rent <= 0) {
      return 'Le loyer doit être un nombre positif';
    }
    return null;
  }

  /// Validates surface area (optional, must be positive if provided)
  /// Returns null if valid, French error message if invalid
  static String? validateSurfaceArea(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    final cleanValue = value.replaceAll(' ', '').replaceAll(',', '.');
    final area = double.tryParse(cleanValue);
    if (area == null) {
      return 'La surface doit être un nombre valide';
    }
    if (area <= 0) {
      return 'La surface doit être un nombre positif';
    }
    return null;
  }

  /// Validates rooms count (optional, must be non-negative if provided)
  /// Returns null if valid, French error message if invalid
  static String? validateRoomsCount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    final rooms = int.tryParse(value.trim());
    if (rooms == null) {
      return 'Le nombre de pièces doit être un nombre entier';
    }
    if (rooms < 0) {
      return 'Le nombre de pièces doit être positif ou zéro';
    }
    return null;
  }

  /// Validates charges amount (optional, must be non-negative if provided)
  /// Returns null if valid, French error message if invalid
  static String? validateChargesAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field, defaults to 0
    }
    final cleanValue = value.replaceAll(' ', '').replaceAll(',', '.');
    final charges = double.tryParse(cleanValue);
    if (charges == null) {
      return 'Les charges doivent être un nombre valide';
    }
    if (charges < 0) {
      return 'Les charges doivent être un nombre positif ou zéro';
    }
    return null;
  }

  /// Validates floor number (optional, can be negative for basement)
  /// Returns null if valid, French error message if invalid
  static String? validateFloor(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    final floor = int.tryParse(value.trim());
    if (floor == null) {
      return "L'étage doit être un nombre entier";
    }
    return null;
  }

  /// Validates description (optional, max length)
  /// Returns null if valid, French error message if invalid
  static String? validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    if (value.trim().length > maxDescriptionLength) {
      return 'La description ne peut pas dépasser $maxDescriptionLength caractères';
    }
    return null;
  }

  /// Validates photo size before upload
  /// Returns null if valid, French error message if invalid
  static String? validatePhotoSize(int sizeInBytes) {
    if (sizeInBytes > maxPhotoSizeBytes) {
      return 'La photo est trop volumineuse (max 5 Mo)';
    }
    return null;
  }

  /// Check if all required fields are valid
  static bool isValidUnit({
    required String? reference,
    required String? baseRent,
  }) {
    return validateReference(reference) == null &&
        validateBaseRent(baseRent) == null;
  }

  /// Parse currency string to double (handles French format with spaces)
  static double? parseAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final cleanValue = value.replaceAll(' ', '').replaceAll(',', '.');
    return double.tryParse(cleanValue);
  }

  /// Parse integer string
  static int? parseInt(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return int.tryParse(value.trim());
  }
}
