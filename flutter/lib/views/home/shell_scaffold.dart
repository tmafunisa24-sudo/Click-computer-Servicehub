// lib/views/home/shell_scaffold.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_radius.dart';
import '../../core/design/app_spacing.dart';
import '../../viewmodels/auth_viewmodel.dart';

/// Shell hosting the bottom navigation bar for authenticated screens.
///
/// All roles use 4 branches. The 4th branch is role-specific:
/// - Admin: opens a "More" bottom sheet (intercepts the tap)
/// - Technician / Client: shows a real screen
class ShellScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ShellScaffold({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthViewModel>().user?.role ?? '';
    final tabs = _tabsForRole(role);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          // Admin's 4th tab ("More") opens a bottom sheet instead of
          // navigating to a branch.
          if (index == 3 && role == 'Admin') {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (_) => const AdminMoreSheet(),
            );
            return;
          }
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: tabs
            .map(
              (t) => NavigationDestination(
                icon: Icon(t.icon, color: AppColors.textSubtle),
                selectedIcon: Icon(t.icon, color: AppColors.primary),
                label: t.label,
              ),
            )
            .toList(),
      ),
    );
  }

  static List<_Tab> _tabsForRole(String role) {
    switch (role) {
      case 'Admin':
        return const [
          _Tab(icon: Icons.speed_outlined, label: 'Home'),
          _Tab(icon: Icons.confirmation_number_outlined, label: 'Tickets'),
          _Tab(icon: Icons.inventory_2_outlined, label: 'Assets'),
          _Tab(icon: Icons.more_horiz, label: 'More'),
        ];
      case 'Technician':
        return const [
          _Tab(icon: Icons.speed_outlined, label: 'Home'),
          _Tab(icon: Icons.confirmation_number_outlined, label: 'Tickets'),
          _Tab(icon: Icons.build_outlined, label: 'Maintenance'),
          _Tab(icon: Icons.notifications_outlined, label: 'Alerts'),
        ];
      case 'Client':
      default:
        return const [
          _Tab(icon: Icons.home_outlined, label: 'Home'),
          _Tab(icon: Icons.add_circle_outline, label: 'New'),
          _Tab(icon: Icons.confirmation_number_outlined, label: 'Requests'),
          _Tab(icon: Icons.notifications_outlined, label: 'Alerts'),
        ];
    }
  }
}

class _Tab {
  final IconData icon;
  final String label;

  const _Tab({required this.icon, required this.label});
}

// ═══════════════════════════════════════════════════════════
// Admin "More" bottom sheet
// ═══════════════════════════════════════════════════════════
class AdminMoreSheet extends StatelessWidget {
  const AdminMoreSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadius.xl),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'More',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _MoreItem(
              icon: Icons.people_outline,
              label: 'Users',
              onTap: () {
                Navigator.of(context).pop();
                context.push('/users');
              },
            ),
            _MoreItem(
              icon: Icons.bar_chart_outlined,
              label: 'Reports',
              onTap: () {
                Navigator.of(context).pop();
                context.push('/reports');
              },
            ),
            _MoreItem(
              icon: Icons.business_outlined,
              label: 'Departments',
              onTap: () {
                Navigator.of(context).pop();
                context.push('/departments');
              },
            ),
            _MoreItem(
              icon: Icons.build_outlined,
              label: 'Maintenance',
              onTap: () {
                Navigator.of(context).pop();
                context.push('/maintenance');
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

class _MoreItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MoreItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.textSubtle,
      ),
      onTap: onTap,
    );
  }
}