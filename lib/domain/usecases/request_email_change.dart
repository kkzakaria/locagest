import '../repositories/auth_repository.dart';

/// Use case for requesting an email change
/// Sends OTP to the new email address for verification
class RequestEmailChange {
  final AuthRepository _repository;

  RequestEmailChange({required AuthRepository repository})
      : _repository = repository;

  /// Execute the email change request
  /// [newEmail] - The new email address
  Future<void> call({required String newEmail}) async {
    await _repository.requestEmailChange(newEmail: newEmail);
  }
}
