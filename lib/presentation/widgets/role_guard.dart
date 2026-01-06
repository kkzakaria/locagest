import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/user.dart';
import '../providers/auth_provider.dart';

/// Widget that shows content only when user has required role(s)
/// Hides content (or shows fallback) for users without required role
class RoleGuard extends ConsumerWidget {
  final List<UserRole> allowedRoles;
  final Widget child;
  final Widget? fallback;

  const RoleGuard({
    super.key,
    required this.allowedRoles,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return fallback ?? const SizedBox.shrink();
    }

    if (!allowedRoles.contains(user.role)) {
      return fallback ?? const SizedBox.shrink();
    }

    return child;
  }
}

/// Widget that shows content only for admin users
class AdminOnly extends ConsumerWidget {
  final Widget child;
  final Widget? fallback;

  const AdminOnly({
    super.key,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RoleGuard(
      allowedRoles: const [UserRole.admin],
      fallback: fallback,
      child: child,
    );
  }
}

/// Widget that shows content for users who can manage buildings
class CanManageBuildings extends ConsumerWidget {
  final Widget child;
  final Widget? fallback;

  const CanManageBuildings({
    super.key,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RoleGuard(
      allowedRoles: const [UserRole.admin, UserRole.gestionnaire],
      fallback: fallback,
      child: child,
    );
  }
}

/// Widget that shows content for users who can generate reports
class CanGenerateReports extends ConsumerWidget {
  final Widget child;
  final Widget? fallback;

  const CanGenerateReports({
    super.key,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RoleGuard(
      allowedRoles: const [UserRole.admin, UserRole.gestionnaire],
      fallback: fallback,
      child: child,
    );
  }
}

/// Widget that hides content from assistant users (for edit/delete buttons)
class HideFromAssistant extends ConsumerWidget {
  final Widget child;

  const HideFromAssistant({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user?.role == UserRole.assistant) {
      return const SizedBox.shrink();
    }

    return child;
  }
}
