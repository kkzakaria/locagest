import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Use case for getting the current authenticated user
/// Returns null if not authenticated
class GetCurrentUser {
  final AuthRepository _repository;

  GetCurrentUser({required AuthRepository repository})
      : _repository = repository;

  /// Execute the use case
  /// Returns the current user or null if not authenticated
  Future<User?> call() async {
    return await _repository.getCurrentUser();
  }
}
