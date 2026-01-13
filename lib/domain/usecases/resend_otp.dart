import '../repositories/auth_repository.dart';

/// Use case for resending OTP code
/// Used when user hasn't received the code or it has expired
class ResendOtp {
  final AuthRepository _repository;

  ResendOtp({required AuthRepository repository}) : _repository = repository;

  /// Execute the OTP resend
  /// [type] - Type of OTP: 'signup', 'recovery', or 'email_change'
  /// [email] - Email address to send the OTP to
  Future<void> call({
    required String type,
    required String email,
  }) async {
    await _repository.resendOtp(
      type: type,
      email: email,
    );
  }
}
