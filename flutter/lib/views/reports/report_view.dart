// lib/views/reports/report_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_radius.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/widgets/app_header.dart';
import '../../core/design/widgets/app_top_bar.dart';
import '../../models/dtos/report_dto.dart';
import '../../viewmodels/report_viewmodel.dart';

class ReportView extends StatelessWidget {
  const ReportView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReportViewModel>();

    return Scaffold(
      appBar: const AppTopBar(title: 'Reports'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppHeader(
                badge: 'Analytics',
                badgeIcon: Icons.bar_chart_outlined,
                title: 'Reports',
                description:
                    'Generate and export operational reports.',
              ),
              const SizedBox(height: AppSpacing.md),
              _FilterCard(vm: vm),
              const SizedBox(height: AppSpacing.md),
              if (vm.isGenerating)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                )
              else if (vm.error != null)
                _ErrorCard(message: vm.error!)
              else if (vm.preview != null)
                _PreviewCard(preview: vm.preview!, vm: vm)
              else
                const _EmptyState(),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterCard extends StatelessWidget {
  final ReportViewModel vm;
  const _FilterCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderCard,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'REPORT OPTIONS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textSubtle,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const _FormLabel(text: 'Report Type', required: true),
          DropdownButtonFormField<String>(
            initialValue: vm.reportType,
            isExpanded: true,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.bar_chart_outlined),
            ),
            items: ReportType.all
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) {
              if (v != null) vm.setReportType(v);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _DatePicker(
                  label: 'Start Date',
                  value: vm.startDate,
                  onPick: () => _pickDate(context, vm, isStart: true),
                  onClear: () => vm.setStartDate(null),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _DatePicker(
                  label: 'End Date',
                  value: vm.endDate,
                  onPick: () => _pickDate(context, vm, isStart: false),
                  onClear: () => vm.setEndDate(null),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 52,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: vm.isGenerating ? null : () => vm.generate(),
              icon: const Icon(Icons.play_arrow),
              label: Text(vm.isGenerating ? 'Generating...' : 'Generate Report'),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _pickDate(
    BuildContext context,
    ReportViewModel vm, {
    required bool isStart,
  }) async {
    final initial = (isStart ? vm.startDate : vm.endDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    if (isStart) {
      vm.setStartDate(picked);
    } else {
      vm.setEndDate(picked);
    }
  }
}

class _PreviewCard extends StatelessWidget {
  final ReportPreview preview;
  final ReportViewModel vm;

  const _PreviewCard({required this.preview, required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderCard,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preview.reportType,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${preview.rowCount} ${preview.rowCount == 1 ? 'row' : 'rows'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSubtle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: vm.isExporting ? null : () => _exportCsv(context),
                  icon: const Icon(Icons.file_download_outlined, size: 18),
                  label: const Text('CSV'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    foregroundColor: AppColors.success,
                    side: const BorderSide(color: AppColors.success),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: vm.isExporting ? null : () => _exportExcel(context),
                  icon: const Icon(Icons.file_download_outlined, size: 18),
                  label: const Text('Excel'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    foregroundColor: AppColors.success,
                    side: const BorderSide(color: AppColors.success),
                  ),
                ),
              ),
            ],
          ),
          if (vm.isExporting) ...[
            const SizedBox(height: AppSpacing.sm),
            const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          ],
          if (vm.exportError != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _Banner(
              icon: Icons.error_outline,
              color: AppColors.danger,
              message: vm.exportError!,
            ),
          ],
          if (vm.lastExportedPath != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _Banner(
              icon: Icons.check_circle_outline,
              color: AppColors.success,
              message: 'Saved to:\n${vm.lastExportedPath!}',
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),
          if (preview.rows.isEmpty)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: Text(
                  'No data for the selected filters.',
                  style: TextStyle(color: AppColors.textSubtle),
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  AppColors.primary.withValues(alpha: 0.08),
                ),
                headingTextStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: AppColors.textPrimary,
                ),
                dataTextStyle: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                ),
                columns: preview.columns
                    .map((c) => DataColumn(label: Text(c)))
                    .toList(),
                rows: preview.rows.map((row) {
                  return DataRow(
                    cells: preview.rawColumns.map((key) {
                      final v = row[key];
                      return DataCell(Text(_formatCell(v)));
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  static String _formatCell(dynamic v) {
    if (v == null) return '—';
    final s = v.toString();
    if (s.isEmpty) return '—';
    if (s.length > 19 && s.contains('T') && s.contains(':')) {
      return s.substring(0, 10);
    }
    return s;
  }

  Future<void> _exportCsv(BuildContext context) async {
    final path = await vm.exportCsv();
    if (path != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CSV file saved.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _exportExcel(BuildContext context) async {
    final path = await vm.exportExcel();
    if (path != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Excel file saved.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
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

class _DatePicker extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _DatePicker({
    required this.label,
    required this.value,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onPick,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: AppColors.textSubtle,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value == null ? 'Optional' : _fmt(value!),
                    style: TextStyle(
                      fontSize: 13,
                      color: value == null
                          ? AppColors.textSubtle
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (value != null)
                  GestureDetector(
                    onTap: onClear,
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: AppColors.textSubtle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _fmt(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

class _Banner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String message;

  const _Banner({
    required this.icon,
    required this.color,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderCard,
        border: Border.all(color: AppColors.dangerAlpha(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: AppColors.danger.withValues(alpha: 0.6),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Unable to generate report',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSubtle),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        children: [
          Icon(
            Icons.bar_chart_outlined,
            size: 72,
            color: AppColors.primary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'No report generated yet',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Choose a report type and tap Generate Report.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSubtle),
          ),
        ],
      ),
    );
  }
}