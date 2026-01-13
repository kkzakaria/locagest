import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Use case for verifying OTP code
/// Used for signup confirmation, password recovery, and email change
class VerifyOtp {
  final AuthRepository _repository;

  VerifyOtp({required AuthRepository repository}) : _repository = repository;

  /// Execute the OTP verification
  /// [type] - Type of OTP: 'signup', 'recovery', or 'email_change'
  /// [email] - Email address that received the OTP
  /// [token] - The 6-digit OTP code
  /// Returns the authenticated user on success
  Future<User?> call({
    required String type,
    required String email,
    required String token,
  }) async {
    return await _repository.verifyOtp(
      type: type,
      email: email,
      token: token,
    );
  }
}
