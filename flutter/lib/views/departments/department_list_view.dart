// lib/views/departments/department_list_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_radius.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/widgets/app_badge.dart';
import '../../core/design/widgets/app_header.dart';
import '../../core/design/widgets/app_top_bar.dart';
import '../../models/dtos/department_dto.dart';
import '../../viewmodels/department_viewmodel.dart';
import 'department_form_sheet.dart';

class DepartmentListView extends StatefulWidget {
  const DepartmentListView({super.key});

  @override
  State<DepartmentListView> createState() => _DepartmentListViewState();
}

class _DepartmentListViewState extends State<DepartmentListView> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DepartmentViewModel>().load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DepartmentViewModel>();

    return Scaffold(
      appBar: AppTopBar(
        title: 'Departments',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: vm.isLoading ? null : () => vm.refresh(),
          ),
        ],
      ),
      body: SafeArea(child: _buildBody(vm)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context, null),
        icon: const Icon(Icons.add),
        label: const Text('New Department'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildBody(DepartmentViewModel vm) {
    if (vm.isLoading && vm.departments.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    if (vm.error != null && vm.departments.isEmpty) {
      return _ErrorState(message: vm.error!, onRetry: () => vm.refresh());
    }

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
                badge: 'Organization',
                badgeIcon: Icons.business_outlined,
                title: 'Departments',
                description: 'Manage departments and their staffing.',
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
              child: _SearchBar(
                controller: _searchController,
                onChanged: vm.setSearchTerm,
              ),
            ),
          ),

          if (vm.filteredDepartments.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(),
            )
          else
            SliverList.separated(
              itemCount: vm.filteredDepartments.length,
              separatorBuilder: (_, _) => const Divider(
                height: 1,
                indent: AppSpacing.md,
                endIndent: AppSpacing.md,
                color: AppColors.border,
              ),
              itemBuilder: (context, i) => _DepartmentTile(
                department: vm.filteredDepartments[i],
                onTap: () => _showForm(context, vm.filteredDepartments[i]),
              ),
            ),

          const SliverPadding(
            padding: EdgeInsets.only(bottom: AppSpacing.xl),
          ),
        ],
      ),
    );
  }

  static void _showForm(BuildContext context, DepartmentDto? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DepartmentFormSheet(existing: existing),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final DepartmentViewModel vm;
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
          _StatCard(
            label: 'Departments',
            value: vm.totalCount,
            color: AppColors.primary,
          ),
          _StatCard(
            label: 'Employees',
            value: vm.totalEmployees,
            color: AppColors.secondary,
          ),
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
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSubtle,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Search departments...',
          prefixIcon: const Icon(Icons.search, size: 20),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: AppRadius.borderLg,
            borderSide: const BorderSide(color: AppColors.borderInput),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.borderLg,
            borderSide: const BorderSide(color: AppColors.borderInput),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.borderLg,
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: AppColors.surface,
        ),
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
      ),
    );
  }
}

class _DepartmentTile extends StatelessWidget {
  final DepartmentDto department;
  final VoidCallback onTap;

  const _DepartmentTile({required this.department, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(
                Icons.business_outlined,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    department.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (department.description != null &&
                      department.description!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      department.description!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSubtle,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  AppBadge(
                    label:
                        '${department.employeeCount} ${department.employeeCount == 1 ? 'employee' : 'employees'}',
                    variant: AppBadgeVariant.secondary,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSubtle),
          ],
        ),
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
              const Text('Unable to load departments',
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
          Icon(Icons.business_outlined, size: 72,
              color: AppColors.primary.withValues(alpha: 0.4)),
          const SizedBox(height: AppSpacing.md),
          const Text('No departments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.xs),
          const Text('Tap "New Department" to add one.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSubtle)),
        ],
      ),
    );
  }
}