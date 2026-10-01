// lib/views/users/user_list_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_radius.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/widgets/app_badge.dart';
import '../../core/design/widgets/app_header.dart';
import '../../core/design/widgets/app_top_bar.dart';
import '../../models/profile.dart';
import '../../viewmodels/user_viewmodel.dart';

class UserListView extends StatefulWidget {
  const UserListView({super.key});

  @override
  State<UserListView> createState() => _UserListViewState();
}

class _UserListViewState extends State<UserListView> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserViewModel>().load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<UserViewModel>();

    return Scaffold(
      appBar: AppTopBar(
        title: 'User Management',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: vm.isLoading ? null : () => vm.refresh(),
          ),
        ],
      ),
      body: SafeArea(child: _buildBody(vm)),
    );
  }

  Widget _buildBody(UserViewModel vm) {
    if (vm.isLoading && vm.users.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    if (vm.error != null && vm.users.isEmpty) {
      return _ErrorState(message: vm.error!, onRetry: () => vm.refresh());
    }

    final list = vm.filteredUsers;

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
                badge: 'Admin Access',
                badgeIcon: Icons.people_outline,
                title: 'User Management',
                description: 'Approve, assign roles, and manage access.',
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
              child: _SearchAndFilters(
                controller: _searchController,
                vm: vm,
                onSearch: (v) => vm.setSearchTerm(v),
              ),
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
              itemBuilder: (context, i) => _UserTile(
                user: list[i],
                onTap: () => _showEditSheet(context, list[i]),
              ),
            ),

          const SliverPadding(
            padding: EdgeInsets.only(bottom: AppSpacing.xl),
          ),
        ],
      ),
    );
  }

  static void _showEditSheet(BuildContext context, Profile user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditUserSheet(user: user),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final UserViewModel vm;
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
          _StatCard(label: 'Clients', value: vm.clientCount, color: AppColors.secondary),
          _StatCard(label: 'Techs', value: vm.technicianCount, color: AppColors.purple),
          _StatCard(label: 'Admins', value: vm.adminCount, color: AppColors.danger),
          _StatCard(
            label: 'Pending',
            value: vm.pendingCount,
            color: vm.pendingCount > 0 ? AppColors.warning : AppColors.textSubtle,
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

class _SearchAndFilters extends StatelessWidget {
  final TextEditingController controller;
  final UserViewModel vm;
  final ValueChanged<String> onSearch;

  const _SearchAndFilters({
    required this.controller,
    required this.vm,
    required this.onSearch,
  });

  static const _roles = ['', 'Admin', 'Technician', 'Client'];

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
      child: Column(
        children: [
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Search by name or email...',
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
            onChanged: onSearch,
            textInputAction: TextInputAction.search,
          ),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _roles.length,
              itemBuilder: (context, i) {
                final role = _roles[i];
                final isSelected = (vm.roleFilter ?? '') == role;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: ChoiceChip(
                    label: Text(role.isEmpty ? 'All' : role),
                    selected: isSelected,
                    onSelected: (_) => vm.setRoleFilter(role.isEmpty ? null : role),
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.borderPill,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final Profile user;
  final VoidCallback onTap;

  const _UserTile({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final initials = _initials(user.fullName.isEmpty ? user.email : user.fullName);

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
                color: _roleColor(user.role).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: TextStyle(
                    color: _roleColor(user.role),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName.isEmpty ? '—' : user.fullName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSubtle,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _RoleBadge(role: user.role),
                      AppBadge.forStatus(user.status),
                    ],
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

  static String _initials(String source) {
    final parts = source.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '?';
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  static Color _roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin': return AppColors.danger;
      case 'technician': return AppColors.purple;
      case 'client': return AppColors.primary;
      default: return AppColors.textSubtle;
    }
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final color = _UserTile._roleColor(role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.borderPill,
      ),
      child: Text(
        role,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _EditUserSheet extends StatefulWidget {
  final Profile user;
  const _EditUserSheet({required this.user});

  @override
  State<_EditUserSheet> createState() => _EditUserSheetState();
}

class _EditUserSheetState extends State<_EditUserSheet> {
  late String _selectedRole;
  late String _selectedStatus;

  static const _roles = ['Client', 'Technician', 'Admin'];
  static const _statuses = ['Active', 'Approved', 'Pending', 'Disabled'];

  @override
  void initState() {
    super.initState();
    _selectedRole = _roles.firstWhere(
      (r) => r.toLowerCase() == widget.user.role.toLowerCase(),
      orElse: () => 'Client',
    );
    _selectedStatus = _statuses.firstWhere(
      (s) => s.toLowerCase() == widget.user.status.toLowerCase(),
      orElse: () => 'Active',
    );
  }

  Future<void> _submit() async {
    final vm = context.read<UserViewModel>();
    final ok = await vm.updateUser(
      userId: widget.user.id,
      role: _selectedRole,
      status: _selectedStatus,
    );

    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User updated successfully.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<UserViewModel>();

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Edit User',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.user.fullName.isEmpty ? '—' : widget.user.fullName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.user.email,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSubtle,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const _FormLabel(text: 'Role', required: true),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedRole,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.shield_outlined),
                      ),
                      items: _roles
                          .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedRole = v);
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const _FormLabel(text: 'Status', required: true),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedStatus,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.toggle_on_outlined),
                      ),
                      items: _statuses
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedStatus = v);
                      },
                    ),
                    if (vm.updateError != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.dangerAlpha(0.08),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: AppColors.dangerAlpha(0.3),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.error_outline,
                                color: AppColors.danger, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                vm.updateError!,
                                style: const TextStyle(
                                  color: AppColors.danger,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: vm.isUpdating ? null : _submit,
                        child: vm.isUpdating
                            ? const SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FormLabel extends StatelessWidget {
  final String text;
  final bool required;
  const _FormLabel({required this.text, this.required = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          if (required)
            const Text(' *',
                style: TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w700,
                )),
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
              const Text('Unable to load users',
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
          Icon(Icons.people_outline, size: 72,
              color: AppColors.primary.withValues(alpha: 0.4)),
          const SizedBox(height: AppSpacing.md),
          const Text('No users found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.xs),
          const Text('Try a different filter or search term.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSubtle)),
        ],
      ),
    );
  }
}