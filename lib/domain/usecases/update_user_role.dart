import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Use case for updating a user's role (admin only)
/// Throws [UnauthorizedException] if caller is not admin
/// Throws [LastAdminException] if trying to demote the last admin
class UpdateUserRole {
  final AuthRepository _repository;

  UpdateUserRole({required AuthRepository repository})
      : _repository = repository;

  /// Execute the role update
  /// [userId] - ID of the user to update
  /// [newRole] - The new role to assign
  Future<void> call({
    required String userId,
    required UserRole newRole,
  }) async {
    await _repository.updateUserRole(
      userId: userId,
      newRole: newRole,
    );
  }
}
