/// Authentication and security constants for LocaGest
class AppConstants {
  AppConstants._();

  // Lockout configuration (FR-006)
  static const int maxLoginAttempts = 5;
  static const int lockoutDurationMinutes = 15;

  // Session configuration (FR-005)
  static const int sessionDurationDays = 30;

  // Password requirements (FR-003)
  static const int minPasswordLength = 8;
  static const String passwordPattern =
      r'^(?=.*[0-9])(?=.*[!@#$%^&*(),.?":{}|<>]).{8,}$';

  // Password reset link expiry (FR-008)
  static const int resetLinkExpiryHours = 1;

  // User roles (FR-009)
  static const String roleAdmin = 'admin';
  static const String roleGestionnaire = 'gestionnaire';
  static const String roleAssistant = 'assistant';

  // Deep link schemes
  static const String appScheme = 'locagest';
  static const String resetPasswordPath = 'reset-password';

  // OTP configuration
  static const int otpLength = 6;
  static const int otpResendDelaySeconds = 60;
  static const int otpExpiryMinutes = 60;
}
