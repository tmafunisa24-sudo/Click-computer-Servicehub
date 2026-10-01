// lib/views/maintenance/maintenance_form_sheet.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_radius.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/widgets/app_text_field.dart';
import '../../models/asset.dart';
import '../../models/dtos/maintenance_dto.dart';
import '../../models/profile.dart';
import '../../services/asset_service.dart';
import '../../services/user_service.dart';
import '../../viewmodels/maintenance_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../core/network/api_exception.dart';

class MaintenanceFormSheet extends StatefulWidget {
  final MaintenanceRecord? existing;
  const MaintenanceFormSheet({super.key, this.existing});

  @override
  State<MaintenanceFormSheet> createState() => _MaintenanceFormSheetState();
}

class _MaintenanceFormSheetState extends State<MaintenanceFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _problemController;
  late TextEditingController _solutionController;
  late TextEditingController _costController;

  String? _selectedAssetId;
  String? _selectedTechnicianId;
  late String _selectedStatus;
  DateTime? _maintenanceDate;
  DateTime? _nextServiceDate;

  // Data for dropdowns
  List<Asset> _assets = [];
  List<Profile> _technicians = [];
  bool _isLoadingData = true;
  String? _loadError;

  static const _statuses = [
    'Pending',
    'In Progress',
    'Completed',
    'Cancelled',
  ];

  bool get isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;

    _problemController =
        TextEditingController(text: existing?.problem ?? '');
    _solutionController =
        TextEditingController(text: existing?.solution ?? '');
    _costController = TextEditingController(
      text: existing?.maintenanceCost?.toString() ?? '',
    );

    _selectedAssetId = existing?.assetId;
    _selectedTechnicianId = existing?.technicianId;
    _maintenanceDate = existing?.maintenanceDate;
    _nextServiceDate = existing?.nextServiceDate;

    // Normalize status on edit
    if (existing != null) {
      final s = existing.status.toLowerCase();
      final mapped = switch (s) {
        'open' => 'Pending',
        'closed' => 'Completed',
        'due' => 'Completed',
        _ => null,
      };
      if (mapped != null) {
        _selectedStatus = mapped;
      } else if (_statuses.any((x) => x.toLowerCase() == s)) {
        _selectedStatus =
            _statuses.firstWhere((x) => x.toLowerCase() == s);
      } else {
        _selectedStatus = _statuses.first;
      }
    } else {
      _selectedStatus = _statuses.first;
    }

    _loadDropdowns();
  }

  @override
  void dispose() {
    _problemController.dispose();
    _solutionController.dispose();
    _costController.dispose();
    super.dispose();
  }

  Future<void> _loadDropdowns() async {
    try {
      final assetService = AssetService();
      final userService = UserService();
      final current = context.read<AuthViewModel>().user;

      final assets = await assetService.getAssets();

      // Try to load the full user list. Admin-only endpoint.
      // For technicians, this returns 403 — fall back to self-assignment.
      List<Profile> technicians = [];
      try {
        final users = await userService.getUsers();
        technicians = users
            .where((u) => u.role.toLowerCase() == 'technician')
            .toList();
      } on ApiException catch (e) {
        if (e.isForbidden) {
          if (current != null &&
              current.role.toLowerCase() == 'technician') {
            technicians = [current];

            // Also include the currently assigned tech (if different)
            // so the edit form can display them even if they can't be
            // re-assigned by this user.
            final existing = widget.existing;
            if (existing != null &&
                existing.technicianId != current.id) {
              technicians.add(Profile(
                id: existing.technicianId,
                fullName: existing.technicianName,
                email: '',
                role: 'Technician',
                status: 'Active',
                createdAt: DateTime.now(),
              ));
            }
          } else {
            rethrow;
          }
        } else {
          rethrow;
        }
      }

      if (!mounted) return;
      setState(() {
        _assets = assets;
        _technicians = technicians;
        _isLoadingData = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _isLoadingData = false;
      });
    }
  }

  Future<void> _pickDate({required bool isNext}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          (isNext ? _nextServiceDate : _maintenanceDate) ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked == null) return;

    setState(() {
      if (isNext) {
        _nextServiceDate = picked;
      } else {
        _maintenanceDate = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAssetId == null) {
      _showError('Please select an asset.');
      return;
    }
    if (_selectedTechnicianId == null) {
      _showError('Please select a technician.');
      return;
    }

    final cost = _costController.text.trim().isEmpty
        ? null
        : double.tryParse(_costController.text.trim());

    final request = MaintenanceRequest(
      assetId: _selectedAssetId,
      technicianId: _selectedTechnicianId,
      problem: _problemController.text.trim(),
      solution: _solutionController.text.trim().isEmpty
          ? null
          : _solutionController.text.trim(),
      maintenanceDate: _maintenanceDate,
      nextServiceDate: _nextServiceDate,
      maintenanceCost: cost,
      status: _selectedStatus,
    );

    final vm = context.read<MaintenanceViewModel>();
    final ok = isEdit
        ? await vm.updateRecord(widget.existing!.id, request)
        : await vm.createRecord(request);

    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit ? 'Record updated.' : 'Record created.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.danger),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MaintenanceViewModel>();

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
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
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin:
                    const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        isEdit ? 'Edit Record' : 'New Maintenance',
                        style: const TextStyle(
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
                child: _isLoadingData
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      )
                    : _loadError != null
                        ? _buildLoadError()
                        : _buildForm(scrollController, vm),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: AppColors.danger.withValues(alpha: 0.7),
              size: 48,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Unable to load form data',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _loadError!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSubtle,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoadingData = true;
                  _loadError = null;
                });
                _loadDropdowns();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(
    ScrollController scrollController,
    MaintenanceViewModel vm,
  ) {
    return Form(
      key: _formKey,
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Asset
          _FormLabel(text: 'Asset', required: true),
          DropdownButtonFormField<String>(
            initialValue: _selectedAssetId,
            isExpanded: true,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.inventory_2_outlined),
            ),
            items: _assets
                .where((a) => a.id != null)
                .map((a) => DropdownMenuItem(
                      value: a.id,
                      child: Text(
                        a.assetName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _selectedAssetId = v),
            validator: (v) => v == null ? 'Asset is required' : null,
          ),
          const SizedBox(height: AppSpacing.md),

          // Technician
          _FormLabel(text: 'Technician', required: true),
          DropdownButtonFormField<String>(
            initialValue: _selectedTechnicianId,
            isExpanded: true,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.engineering_outlined),
            ),
            items: _technicians
                .map((t) => DropdownMenuItem(
                      value: t.id,
                      child: Text(
                        t.fullName.isEmpty ? t.email : t.fullName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _selectedTechnicianId = v),
            validator: (v) => v == null ? 'Technician is required' : null,
          ),
          const SizedBox(height: AppSpacing.md),

          // Problem
          _FormLabel(text: 'Problem', required: true),
          AppTextField(
            controller: _problemController,
            hint: 'What is the issue?',
            maxLines: 3,
            minLines: 3,
          ),
          const SizedBox(height: AppSpacing.md),

          // Solution
          _FormLabel(text: 'Solution'),
          AppTextField(
            controller: _solutionController,
            hint: 'How was it resolved?',
            maxLines: 3,
            minLines: 3,
          ),
          const SizedBox(height: AppSpacing.md),

          // Status
          _FormLabel(text: 'Status', required: true),
          DropdownButtonFormField<String>(
            initialValue: _selectedStatus,
            isExpanded: true,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.flag_outlined),
            ),
            items: _statuses
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _selectedStatus = v);
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Maintenance date
          _FormLabel(text: 'Maintenance Date'),
          _DatePicker(
            value: _maintenanceDate,
            onTap: () => _pickDate(isNext: false),
            onClear: () => setState(() => _maintenanceDate = null),
          ),
          const SizedBox(height: AppSpacing.md),

          // Next service date
          _FormLabel(text: 'Next Service Date'),
          _DatePicker(
            value: _nextServiceDate,
            onTap: () => _pickDate(isNext: true),
            onClear: () => setState(() => _nextServiceDate = null),
          ),
          const SizedBox(height: AppSpacing.md),

          // Cost
          _FormLabel(text: 'Maintenance Cost (R)'),
          AppTextField(
            controller: _costController,
            hint: '0.00',
            prefixIcon: Icons.attach_money,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
          ),

          // Error
          if (vm.submitError != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.dangerAlpha(0.08),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.dangerAlpha(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.danger,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      vm.submitError!,
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
              onPressed: vm.isSubmitting ? null : _submit,
              child: vm.isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(isEdit ? 'Save Changes' : 'Create Record'),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────
// Form label
// ────────────────────────────────────────────────────────
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
            const Text(
              ' *',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────
// Date picker field
// ────────────────────────────────────────────────────────
class _DatePicker extends StatelessWidget {
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _DatePicker({
    required this.value,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.borderInput),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              color: AppColors.textSubtle,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                value == null ? 'Select date' : _formatDate(value!),
                style: TextStyle(
                  fontSize: 14,
                  color: value == null
                      ? AppColors.textPlaceholder
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (value != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(
                  Icons.clear,
                  size: 18,
                  color: AppColors.textSubtle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}