import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Use case for user registration
/// Returns the newly created User on success
/// Throws [AuthException] on failure
class SignUp {
  final AuthRepository _repository;

  SignUp({required AuthRepository repository}) : _repository = repository;

  /// Execute the sign up use case
  /// [email] - User's email address
  /// [password] - User's password
  /// [fullName] - User's full name
  Future<User> call({
    required String email,
    required String password,
    required String fullName,
  }) async {
    return await _repository.signUp(
      email: email,
      password: password,
      fullName: fullName,
    );
  }
}
