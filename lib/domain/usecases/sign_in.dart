import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Use case for signing in with email and password
/// Returns the authenticated User on success
/// Throws [AuthException] on failure
class SignIn {
  final AuthRepository _repository;

  SignIn({required AuthRepository repository}) : _repository = repository;

  /// Execute the sign in use case
  /// [email] - User's email address
  /// [password] - User's password
  Future<User> call({
    required String email,
    required String password,
  }) async {
    return await _repository.signIn(
      email: email,
      password: password,
    );
  }
}
