import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../domain/entities/user.dart';
import '../../providers/auth_provider.dart';

/// Main dashboard page after login
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('LocaGest'),
        actions: [
          // User menu
          PopupMenuButton<String>(
            icon: const CircleAvatar(
              child: Icon(Icons.person),
            ),
            onSelected: (value) async {
              switch (value) {
                case 'users':
                  context.go(AppRoutes.userManagement);
                  break;
                case 'logout':
                  await _handleLogout(context, ref);
                  break;
              }
            },
            itemBuilder: (context) => [
              // User info header
              PopupMenuItem<String>(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.fullName ?? 'Utilisateur',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      user?.email ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getRoleColor(user?.role),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        user?.role.displayName ?? '',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              // User management (admin only)
              if (user?.canManageUsers ?? false)
                const PopupMenuItem<String>(
                  value: 'users',
                  child: ListTile(
                    leading: Icon(Icons.people),
                    title: Text('Gestion des utilisateurs'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              // Logout
              const PopupMenuItem<String>(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text('Deconnexion', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(authProvider.notifier).refreshUser();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome message
              Text(
                'Bonjour, ${user?.fullName ?? 'Utilisateur'}!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bienvenue sur votre tableau de bord',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 24),

              // Quick stats cards (placeholder for now)
              _buildQuickStats(context, user),

              const SizedBox(height: 24),

              // Quick actions
              Text(
                'Actions rapides',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              _buildQuickActions(context, user),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, User? user) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          context,
          icon: Icons.home_work,
          label: 'Immeubles',
          value: '0',
          color: Colors.blue,
        ),
        _buildStatCard(
          context,
          icon: Icons.people,
          label: 'Locataires',
          value: '0',
          color: Colors.green,
        ),
        _buildStatCard(
          context,
          icon: Icons.receipt,
          label: 'Loyers ce mois',
          value: '0 FCFA',
          color: Colors.orange,
        ),
        _buildStatCard(
          context,
          icon: Icons.warning,
          label: 'Impayes',
          value: '0',
          color: Colors.red,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 28),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, User? user) {
    final actions = <Widget>[];

    // Building management (gestionnaire and admin)
    if (user?.canManageBuildings ?? false) {
      actions.add(_buildActionCard(
        context,
        icon: Icons.add_home_work,
        label: 'Ajouter un immeuble',
        onTap: () {
          // TODO: Navigate to add building
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fonctionnalite a venir')),
          );
        },
      ));
    }

    // View buildings (all users)
    actions.add(_buildActionCard(
      context,
      icon: Icons.home_work,
      label: 'Voir les immeubles',
      onTap: () {
        // TODO: Navigate to buildings list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fonctionnalite a venir')),
        );
      },
    ));

    // User management (admin only)
    if (user?.canManageUsers ?? false) {
      actions.add(_buildActionCard(
        context,
        icon: Icons.manage_accounts,
        label: 'Gerer les utilisateurs',
        onTap: () => context.go(AppRoutes.userManagement),
      ));
    }

    // Reports (gestionnaire and admin)
    if (user?.canGenerateReports ?? false) {
      actions.add(_buildActionCard(
        context,
        icon: Icons.assessment,
        label: 'Rapports',
        onTap: () {
          // TODO: Navigate to reports
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fonctionnalite a venir')),
          );
        },
      ));
    }

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: actions,
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(UserRole? role) {
    switch (role) {
      case UserRole.admin:
        return Colors.red;
      case UserRole.gestionnaire:
        return Colors.blue;
      case UserRole.assistant:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deconnexion'),
        content: const Text('Voulez-vous vraiment vous deconnecter?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Deconnexion'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authProvider.notifier).signOut();
      // Navigation is handled by GoRouter redirect
    }
  }
}
