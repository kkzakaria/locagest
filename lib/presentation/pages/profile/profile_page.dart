import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth_widgets.dart';

/// Profile page showing user info with email change option
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.value?.user;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.dashboard),
        ),
        title: const Text('Mon profil'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      user.fullName.isNotEmpty
                          ? user.fullName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.fullName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getRoleColor(user.role.name).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getRoleLabel(user.role.name),
                      style: TextStyle(
                        color: _getRoleColor(user.role.name),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            // Info section
            Text(
              'Informations du compte',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // Email tile
            _buildInfoTile(
              context,
              icon: Icons.email_outlined,
              label: 'Email',
              value: user.email,
              trailing: TextButton(
                onPressed: () => _showChangeEmailDialog(context),
                child: const Text('Modifier'),
              ),
            ),

            const SizedBox(height: 12),

            // Full name tile
            _buildInfoTile(
              context,
              icon: Icons.person_outline,
              label: 'Nom complet',
              value: user.fullName,
            ),

            const SizedBox(height: 12),

            // Role tile
            _buildInfoTile(
              context,
              icon: Icons.badge_outlined,
              label: 'Role',
              value: _getRoleLabel(user.role.name),
            ),

            const SizedBox(height: 12),

            // Created at tile
            _buildInfoTile(
              context,
              icon: Icons.calendar_today_outlined,
              label: 'Membre depuis',
              value: _formatDate(user.createdAt),
            ),

            const SizedBox(height: 32),

            // Sign out button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authProvider.notifier).signOut();
                  if (context.mounted) {
                    context.go(AppRoutes.login);
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Deconnexion'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600]),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.purple;
      case 'gestionnaire':
        return Colors.blue;
      case 'assistant':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Administrateur';
      case 'gestionnaire':
        return 'Gestionnaire';
      case 'assistant':
        return 'Assistant';
      default:
        return role;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'janvier', 'fevrier', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'aout', 'septembre', 'octobre', 'novembre', 'decembre'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _showChangeEmailDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final emailController = TextEditingController();
    final error = ref.read(authProvider).value?.error;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Modifier l\'email',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Un code de verification sera envoye a votre nouvelle adresse email.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),

                    if (error != null) ...[
                      ErrorDisplay(message: error.messageFr),
                      const SizedBox(height: 16),
                    ],

                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Nouvel email',
                        hintText: 'exemple@email.com',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: Validators.validateEmail,
                    ),
                    const SizedBox(height: 24),

                    Consumer(
                      builder: (context, ref, _) {
                        final isLoading = ref.watch(authProvider).value?.isLoading ?? false;

                        return AuthButton(
                          label: 'Envoyer le code',
                          isLoading: isLoading,
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;

                            ref.read(authProvider.notifier).clearError();

                            final success = await ref
                                .read(authProvider.notifier)
                                .requestEmailChange(
                                  newEmail: emailController.text.trim(),
                                );

                            if (success && context.mounted) {
                              Navigator.of(context).pop();
                              context.go(
                                '${AppRoutes.otpVerification}?email=${Uri.encodeComponent(emailController.text.trim())}&type=email_change&redirect=${AppRoutes.profile}',
                              );
                            }
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Annuler'),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
