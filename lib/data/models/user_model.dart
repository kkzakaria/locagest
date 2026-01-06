import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/user.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

/// UserModel for Supabase profiles table (Data layer)
@freezed
class UserModel with _$UserModel {
  const UserModel._();

  const factory UserModel({
    required String id,
    required String email,
    @JsonKey(name: 'full_name') required String fullName,
    required String role,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'failed_login_attempts') @Default(0) int failedLoginAttempts,
    @JsonKey(name: 'locked_until') DateTime? lockedUntil,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  /// Convert to domain entity
  User toEntity() => User(
        id: id,
        email: email,
        fullName: fullName,
        role: UserRole.fromString(role),
        avatarUrl: avatarUrl,
        createdAt: createdAt,
      );

  /// Check if account is currently locked
  bool get isLocked {
    if (lockedUntil == null) return false;
    return lockedUntil!.isAfter(DateTime.now());
  }

  /// Get remaining lockout minutes
  int get lockoutMinutesRemaining {
    if (!isLocked) return 0;
    return lockedUntil!.difference(DateTime.now()).inMinutes + 1;
  }
}

/// Extension to create UserModel from User entity
extension UserModelFromEntity on User {
  UserModel toModel({
    int failedLoginAttempts = 0,
    DateTime? lockedUntil,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id,
      email: email,
      fullName: fullName,
      role: role.name,
      avatarUrl: avatarUrl,
      failedLoginAttempts: failedLoginAttempts,
      lockedUntil: lockedUntil,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
