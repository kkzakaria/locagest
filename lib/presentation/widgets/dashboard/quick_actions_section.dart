import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../domain/entities/user.dart';
import 'quick_action_card.dart';

/// Quick actions section for dashboard
/// Displays navigation buttons with RBAC filtering
class QuickActionsSection extends StatelessWidget {
  final User? user;

  const QuickActionsSection({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions rapides',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: _buildActions(context),
        ),
      ],
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    final actions = <Widget>[];

    // Add building (gestionnaire and admin only - T055)
    if (user?.canManageBuildings ?? false) {
      actions.add(QuickActionCard(
        icon: Icons.add_home_work,
        label: 'Ajouter un immeuble',
        iconColor: Colors.green,
        onTap: () => context.push(AppRoutes.buildingNew),
      ));
    }

    // View buildings (all users - T054)
    actions.add(QuickActionCard(
      icon: Icons.home_work,
      label: 'Voir les immeubles',
      onTap: () => context.push(AppRoutes.buildings),
    ));

    // View tenants (all users - T054)
    actions.add(QuickActionCard(
      icon: Icons.people,
      label: 'Voir les locataires',
      onTap: () => context.push(AppRoutes.tenants),
    ));

    // View leases (all users - T054)
    actions.add(QuickActionCard(
      icon: Icons.description,
      label: 'Voir les baux',
      onTap: () => context.push(AppRoutes.leases),
    ));

    // View payments (all users - T054)
    actions.add(QuickActionCard(
      icon: Icons.payments,
      label: 'Paiements',
      onTap: () => context.push(AppRoutes.payments),
    ));

    // User management (admin only - T056)
    if (user?.canManageUsers ?? false) {
      actions.add(QuickActionCard(
        icon: Icons.manage_accounts,
        label: 'Gerer les utilisateurs',
        iconColor: Colors.red,
        onTap: () => context.go(AppRoutes.userManagement),
      ));
    }

    return actions;
  }
}
