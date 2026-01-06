import '../repositories/auth_repository.dart';

/// Use case for signing out the current user
class SignOut {
  final AuthRepository _repository;

  SignOut({required AuthRepository repository}) : _repository = repository;

  /// Execute the sign out use case
  /// Clears local session and invalidates tokens
  Future<void> call() async {
    await _repository.signOut();
  }
}
