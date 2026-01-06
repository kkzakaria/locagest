import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../domain/entities/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/users_provider.dart';
import '../../widgets/auth_widgets.dart';

/// Page for managing users (admin only)
class UserManagementPage extends ConsumerStatefulWidget {
  const UserManagementPage({super.key});

  @override
  ConsumerState<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends ConsumerState<UserManagementPage> {
  @override
  void initState() {
    super.initState();
    // Load users on page open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(usersProvider.notifier).loadUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final usersState = ref.watch(usersProvider);
    final users = usersState.value?.users ?? [];
    final isLoading = usersState.value?.isLoading ?? false;
    final error = usersState.value?.error;

    // Check if current user is admin
    if (currentUser == null || !currentUser.isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Gestion des utilisateurs'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go(AppRoutes.dashboard),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Acces reserve aux administrateurs',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des utilisateurs'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.dashboard),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: isLoading
                ? null
                : () => ref.read(usersProvider.notifier).loadUsers(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Error display
          if (error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ErrorDisplay(message: error.messageFr),
            ),

          // Users list
          Expanded(
            child: isLoading && users.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : users.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucun utilisateur trouve',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          await ref.read(usersProvider.notifier).loadUsers();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final user = users[index];
                            final isCurrentUser = user.id == currentUser.id;
                            final isOnlyAdmin = user.isAdmin &&
                                users.where((u) => u.isAdmin).length == 1;

                            return _UserCard(
                              user: user,
                              isCurrentUser: isCurrentUser,
                              isOnlyAdmin: isOnlyAdmin,
                              isLoading: isLoading,
                              onRoleChanged: (newRole) async {
                                await _handleRoleChange(user, newRole);
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRoleChange(User user, UserRole newRole) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le role'),
        content: Text(
          'Voulez-vous vraiment changer le role de ${user.fullName} de ${user.role.displayName} a ${newRole.displayName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref.read(usersProvider.notifier).updateUserRole(
            userId: user.id,
            newRole: newRole,
          );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Role de ${user.fullName} modifie en ${newRole.displayName}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}

/// Card displaying user info with role dropdown
class _UserCard extends StatelessWidget {
  final User user;
  final bool isCurrentUser;
  final bool isOnlyAdmin;
  final bool isLoading;
  final Function(UserRole) onRoleChanged;

  const _UserCard({
    required this.user,
    required this.isCurrentUser,
    required this.isOnlyAdmin,
    required this.isLoading,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Determine if role can be changed
    final canChangeRole = !isLoading && !isCurrentUser && !isOnlyAdmin;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: _getRoleColor(user.role).withValues(alpha: 0.2),
              child: Text(
                _getInitials(user.fullName),
                style: TextStyle(
                  color: _getRoleColor(user.role),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCurrentUser) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Vous',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue[800],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Role dropdown
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isOnlyAdmin)
                  Tooltip(
                    message: 'Dernier administrateur',
                    child: Icon(Icons.shield, color: Colors.orange[700], size: 20),
                  ),
                const SizedBox(height: 4),
                DropdownButton<UserRole>(
                  value: user.role,
                  underline: const SizedBox(),
                  icon: canChangeRole
                      ? const Icon(Icons.arrow_drop_down)
                      : const SizedBox.shrink(),
                  items: UserRole.values.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getRoleColor(role),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          role.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: canChangeRole
                      ? (newRole) {
                          if (newRole != null && newRole != user.role) {
                            onRoleChanged(newRole);
                          }
                        }
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.red;
      case UserRole.gestionnaire:
        return Colors.blue;
      case UserRole.assistant:
        return Colors.green;
    }
  }
}
