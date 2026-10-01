// lib/views/maintenance/maintenance_details_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_radius.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/widgets/app_badge.dart';
import '../../core/design/widgets/app_card.dart';
import '../../core/design/widgets/app_top_bar.dart';
import '../../models/dtos/maintenance_dto.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/maintenance_viewmodel.dart';
import 'maintenance_form_sheet.dart';

class MaintenanceDetailsView extends StatefulWidget {
  final String recordId;
  const MaintenanceDetailsView({super.key, required this.recordId});

  @override
  State<MaintenanceDetailsView> createState() =>
      _MaintenanceDetailsViewState();
}

class _MaintenanceDetailsViewState extends State<MaintenanceDetailsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MaintenanceViewModel>().loadRecord(widget.recordId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MaintenanceViewModel>();
    final isAdmin = context.watch<AuthViewModel>().isAdmin;

    return Scaffold(
      appBar: AppTopBar(
        title: 'Maintenance Details',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload',
            onPressed: vm.isLoadingDetail
                ? null
                : () => vm.loadRecord(widget.recordId),
          ),
        ],
      ),
      body: SafeArea(child: _buildBody(vm, isAdmin)),
    );
  }

  Widget _buildBody(MaintenanceViewModel vm, bool isAdmin) {
    if (vm.isLoadingDetail && vm.current == null) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    if (vm.detailError != null && vm.current == null) {
      return _ErrorState(
        message: vm.detailError!,
        onRetry: () => vm.loadRecord(widget.recordId),
      );
    }

    final record = vm.current;
    if (record == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () => vm.loadRecord(widget.recordId),
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MaintenanceHeaderCard(record: record),
            const SizedBox(height: AppSpacing.md),

            AppSectionCard(
              title: 'Assignment',
              child: Column(
                children: [
                  _DetailRow(
                    label: 'Asset',
                    value: record.assetName.isEmpty
                        ? '—'
                        : record.assetName,
                    isPlaceholder: record.assetName.isEmpty,
                  ),
                  _DetailRow(
                    label: 'Technician',
                    value: record.technicianName.isEmpty
                        ? 'Unassigned'
                        : record.technicianName,
                    isPlaceholder: record.technicianName.isEmpty,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            AppSectionCard(
              title: 'Problem',
              child: Text(
                record.problem,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  height: 1.5,
                ),
              ),
            ),

            if (record.solution != null && record.solution!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              AppSectionCard(
                title: 'Solution',
                child: Text(
                  record.solution!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.md),

            AppSectionCard(
              title: 'Timeline',
              child: Column(
                children: [
                  if (record.maintenanceDate != null)
                    _DetailRow(
                      label: 'Maintenance',
                      value: _formatDate(record.maintenanceDate!),
                    ),
                  if (record.nextServiceDate != null)
                    _DetailRow(
                      label: 'Next Service',
                      value: _formatDate(record.nextServiceDate!),
                      valueColor: AppColors.warning,
                    ),
                  if (record.createdAt != null)
                    _DetailRow(
                      label: 'Created',
                      value: _formatDate(record.createdAt!),
                    ),
                ],
              ),
            ),

            if (record.maintenanceCost != null) ...[
              const SizedBox(height: AppSpacing.md),
              AppSectionCard(
                title: 'Cost',
                child: _DetailRow(
                  label: 'Amount',
                  value:
                      'R ${record.maintenanceCost!.toStringAsFixed(2)}',
                  valueColor: AppColors.success,
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.xl),

            // ── Actions ──
            SizedBox(
              height: 52,
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showEditSheet(context, record),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit Record'),
              ),
            ),
            if (isAdmin) ...[
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 52,
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmDelete(context),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.danger,
                  ),
                  label: const Text(
                    'Delete',
                    style: TextStyle(color: AppColors.danger),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.danger),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.borderPill,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
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

  void _showEditSheet(BuildContext context, MaintenanceRecord record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MaintenanceFormSheet(existing: record),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete record?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style:
                TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final vm = context.read<MaintenanceViewModel>();
      final ok = await vm.deleteRecord(widget.recordId);
      if (ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Record deleted.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }
}

// ────────────────────────────────────────────────────────
// Maintenance header card — pale hero panel with status badge
// ────────────────────────────────────────────────────────
class _MaintenanceHeaderCard extends StatelessWidget {
  final MaintenanceRecord record;
  const _MaintenanceHeaderCard({required this.record});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ClipRRect(
        borderRadius: AppRadius.borderCard,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppColors.heroPanel,
                  borderRadius: AppRadius.borderCard,
                  border: Border.all(color: AppColors.border),
                ),
              ),
            ),
            Positioned(
              right: -40,
              bottom: -40,
              width: 160,
              height: 160,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppColors.heroGlow,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MAINTENANCE RECORD',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    record.problem,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      AppBadge.forStatus(record.status),
                      if (record.assetName.isNotEmpty)
                        AppBadge(
                          label: record.assetName,
                          variant: AppBadgeVariant.secondary,
                          icon: Icons.inventory_2_outlined,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────
// Detail row
// ────────────────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isPlaceholder;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isPlaceholder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSubtle,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: isPlaceholder
                    ? AppColors.textPlaceholder
                    : (valueColor ?? AppColors.textPrimary),
                fontWeight: FontWeight.w600,
                fontStyle:
                    isPlaceholder ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────
// Error state
// ────────────────────────────────────────────────────────
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
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.danger.withValues(alpha: 0.6),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Unable to load record',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSubtle,
                  fontSize: 14,
                ),
              ),
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