// lib/views/maintenance/maintenance_list_view.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_radius.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/widgets/app_badge.dart';
import '../../core/design/widgets/app_header.dart';
import '../../core/design/widgets/app_top_bar.dart';
import '../../models/dtos/maintenance_dto.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/maintenance_viewmodel.dart';
import 'maintenance_form_sheet.dart';

class MaintenanceListView extends StatefulWidget {
  const MaintenanceListView({super.key});

  @override
  State<MaintenanceListView> createState() => _MaintenanceListViewState();
}

class _MaintenanceListViewState extends State<MaintenanceListView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MaintenanceViewModel>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MaintenanceViewModel>();
    final isAdmin = context.watch<AuthViewModel>().isAdmin;

    return Scaffold(
      appBar: AppTopBar(
        title: 'Maintenance',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: vm.isLoading ? null : () => vm.refresh(),
          ),
        ],
      ),
      body: SafeArea(child: _buildBody(vm, isAdmin)),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showForm(context, null),
              icon: const Icon(Icons.add),
              label: const Text('New Record'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _buildBody(MaintenanceViewModel vm, bool isAdmin) {
    if (vm.isLoading && vm.records.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    if (vm.error != null && vm.records.isEmpty) {
      return _ErrorState(message: vm.error!, onRetry: () => vm.refresh());
    }

    final list = vm.filteredRecords;

    return RefreshIndicator(
      onRefresh: () => vm.refresh(),
      color: AppColors.primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: AppHeader(
                badge: 'Service Records',
                badgeIcon: Icons.build_outlined,
                title: 'Maintenance',
                description: 'Track scheduled and completed maintenance.',
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: _StatsRow(vm: vm),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: _StatusFilters(vm: vm),
            ),
          ),

          if (list.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(),
            )
          else
            SliverList.separated(
              itemCount: list.length,
              separatorBuilder: (_, _) => const Divider(
                height: 1,
                indent: AppSpacing.md,
                endIndent: AppSpacing.md,
                color: AppColors.border,
              ),
              itemBuilder: (context, i) => _MaintenanceTile(
                record: list[i],
                onTap: () => context.push('/maintenance/${list[i].id}'),
              ),
            ),

          const SliverPadding(
            padding: EdgeInsets.only(bottom: AppSpacing.xl),
          ),
        ],
      ),
    );
  }

  static void _showForm(BuildContext context, MaintenanceRecord? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MaintenanceFormSheet(existing: existing),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final MaintenanceViewModel vm;
  const _StatsRow({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          _StatCard(label: 'Total', value: vm.totalCount, color: AppColors.primary),
          _StatCard(label: 'Pending', value: vm.pendingCount, color: AppColors.secondary),
          _StatCard(label: 'In Progress', value: vm.inProgressCount, color: AppColors.warning),
          _StatCard(label: 'Done', value: vm.completedCount, color: AppColors.success),
          _StatCard(label: 'Cancelled', value: vm.cancelledCount, color: AppColors.danger),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSubtle,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StatusFilters extends StatelessWidget {
  final MaintenanceViewModel vm;
  const _StatusFilters({required this.vm});

  static const _statuses = ['', 'Pending', 'In Progress', 'Completed', 'Cancelled'];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        itemCount: _statuses.length,
        itemBuilder: (context, i) {
          final s = _statuses[i];
          final isSelected = (vm.statusFilter ?? '') == s;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: ChoiceChip(
              label: Text(s.isEmpty ? 'All' : s),
              selected: isSelected,
              onSelected: (_) => vm.setStatusFilter(s.isEmpty ? null : s),
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surface,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.borderPill),
            ),
          );
        },
      ),
    );
  }
}

class _MaintenanceTile extends StatelessWidget {
  final MaintenanceRecord record;
  final VoidCallback onTap;

  const _MaintenanceTile({required this.record, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    record.problem,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                AppBadge.forStatus(record.status),
              ],
            ),
            const SizedBox(height: 6),
            _MetaRow(
              icon: Icons.inventory_2_outlined,
              text: record.assetName,
            ),
            const SizedBox(height: 4),
            _MetaRow(
              icon: Icons.engineering_outlined,
              text: record.technicianName,
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (record.maintenanceDate != null)
                  _InfoChip(
                    icon: Icons.calendar_today_outlined,
                    label: _formatDate(record.maintenanceDate!),
                  ),
                if (record.maintenanceCost != null)
                  _InfoChip(
                    icon: Icons.attach_money,
                    label: 'R ${record.maintenanceCost!.toStringAsFixed(2)}',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${local.day} ${months[local.month - 1]} ${local.year}';
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.textSubtle),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: AppColors.textSubtle),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSubtle),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSubtle,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xxxl),
              Icon(Icons.error_outline, size: 64,
                  color: AppColors.danger.withValues(alpha: 0.6)),
              const SizedBox(height: AppSpacing.md),
              const Text('Unable to load maintenance',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.xs),
              Text(message, textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSubtle)),
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.build_outlined, size: 72,
              color: AppColors.primary.withValues(alpha: 0.4)),
          const SizedBox(height: AppSpacing.md),
          const Text('No maintenance records',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.xs),
          const Text('Maintenance records will appear here once created.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSubtle)),
        ],
      ),
    );
  }
}