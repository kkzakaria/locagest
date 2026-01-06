import '../repositories/auth_repository.dart';

/// Use case for requesting a password reset email
class RequestPasswordReset {
  final AuthRepository _repository;

  RequestPasswordReset({required AuthRepository repository})
      : _repository = repository;

  /// Execute the password reset request
  /// [email] - User's email address
  Future<void> call({required String email}) async {
    await _repository.resetPasswordForEmail(email: email);
  }
}

/// Use case for updating password with a new value
/// Called after user clicks reset link and enters new password
class UpdatePassword {
  final AuthRepository _repository;

  UpdatePassword({required AuthRepository repository})
      : _repository = repository;

  /// Execute the password update
  /// [newPassword] - The new password
  Future<void> call({required String newPassword}) async {
    await _repository.updatePassword(newPassword: newPassword);
  }
}
