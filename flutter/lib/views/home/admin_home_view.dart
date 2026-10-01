// lib/views/home/admin_home_view.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_radius.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/widgets/app_header.dart';
import '../../core/design/widgets/app_top_bar.dart';
import '../../models/dtos/dashboard_response.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import 'widgets/dashboard_widgets.dart';


class AdminHomeView extends StatefulWidget{
const AdminHomeView({super.key});

@override
State<AdminHomeView> createState() => _AdminHomeView();
}

class _AdminHomeView extends State<AdminHomeView> {
  

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final vm = context.watch<DashboardViewModel>();
    final data = vm.data;

    return Scaffold(
      appBar: AppTopBar(
        title: 'Admin Dashboard',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => context.read<AuthViewModel>().logout(),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => vm.refresh(),
          color: AppColors.primary,
          child: _buildBody(context, auth, vm, data),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AuthViewModel auth,
    DashboardViewModel vm,
    DashboardResponse? data,
  ) {
    if (vm.isLoading && data == null) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    if (vm.error != null && data == null) {
      return ErrorState(message: vm.error!, onRetry: () => vm.load());
    }

    if (data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final m = data.metrics;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        AppHeader(
          badge: 'Administrator',
          badgeIcon: Icons.shield_outlined,
          title: 'Welcome back, ${_firstName(auth.user?.fullName)}',
          description: 'Full control over tickets, assets, staff and service delivery.',
        ),
        const SizedBox(height: AppSpacing.xl),

        // ── Users ──
        const SectionTitle('Users'),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                label: 'Total',
                value: m.totalUsers,
                icon: Icons.people_outline,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: MetricCard(
                label: 'Clients',
                value: m.clients,
                icon: Icons.person_outline,
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                label: 'Technicians',
                value: m.technicians,
                icon: Icons.build_outlined,
                color: AppColors.purple,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: MetricCard(
                label: 'Pending',
                value: m.pendingApprovals,
                icon: Icons.hourglass_top_outlined,
                color: m.pendingApprovals > 0
                    ? AppColors.warning
                    : AppColors.textSubtle,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),

        // ── Tickets ──
        const SectionTitle('Tickets'),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                label: 'Total',
                value: m.totalTickets,
                icon: Icons.confirmation_number_outlined,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: MetricCard(
                label: 'Open',
                value: m.openTickets,
                icon: Icons.mail_outline,
                color: AppColors.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                label: 'Unresolved',
                value: m.unresolvedTickets,
                icon: Icons.timelapse_outlined,
                color: AppColors.purple,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: MetricCard(
                label: 'Resolved',
                value: m.resolvedTickets,
                icon: Icons.check_circle_outline,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),

        // ── Assets ──
        const SectionTitle('Assets'),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                label: 'Total',
                value: m.totalAssets,
                icon: Icons.inventory_2_outlined,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: MetricCard(
                label: 'Available',
                value: m.availableAssets,
                icon: Icons.check_outlined,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                label: 'Assigned',
                value: m.assignedAssets,
                icon: Icons.assignment_ind_outlined,
                color: AppColors.purple,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: MetricCard(
                label: 'Maintenance',
                value: m.maintenanceAssets,
                icon: Icons.build_outlined,
                color: AppColors.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),

        // ── Top technician ──
        if (data.topTechnician != null) ...[
          const SectionTitle('Top Performer'),
          const SizedBox(height: AppSpacing.xs),
          TopTechnicianCard(tech: data.topTechnician!),
          const SizedBox(height: AppSpacing.xl),
        ],

        // ── Recent tickets ──
        SectionTitle(
          'Recent Tickets',
          trailing: TextButton(
            onPressed: () => context.push('/tickets'),
            child: const Text('View All'),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        RecentTicketsList(tickets: data.recentTickets),
        const SizedBox(height: AppSpacing.xl),

        // ── Quick links ──
        const SectionTitle('Quick Access'),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: _QuickLinkButton(
                icon: Icons.people_outline,
                label: 'Users',
                onTap: () => context.push('/users'),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _QuickLinkButton(
                icon: Icons.business_outlined,
                label: 'Departments',
                onTap: () => context.push('/departments'),
              ),
            ),
          ],
        ),
               const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: _QuickLinkButton(
                icon: Icons.inventory_2_outlined,
                label: 'Assets',
                onTap: () => context.push('/assets'),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _QuickLinkButton(
                icon: Icons.build_outlined,
                label: 'Maintenance',
                onTap: () => context.push('/maintenance'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: _QuickLinkButton(
                icon: Icons.person_outline,
                label: 'Profile',
                onTap: () => context.push('/profile'),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _QuickLinkButton(
                icon: Icons.bar_chart_outlined,
                label: 'Reports',
                onTap: () => context.push('/reports'),
              ),
            ),
          ],
        )
      ]
    );
  }
  

  static String _firstName(String? fullName) {
    if (fullName == null || fullName.isEmpty) return 'Admin';
    return fullName.trim().split(RegExp(r'\s+')).first;
  }
}

// ────────────────────────────────────────────────────────
// Quick-link pill button (outlined primary)
// ────────────────────────────────────────────────────────
class _QuickLinkButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickLinkButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.borderPill,
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        ),
      ),
    );
  }
}