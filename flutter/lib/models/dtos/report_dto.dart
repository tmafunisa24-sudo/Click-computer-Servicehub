// lib/models/dtos/report_dto.dart

class ReportPreview {
  final String reportType;
  final DateTime? startDate;
  final DateTime? endDate;
  final int rowCount;
  final List<Map<String, dynamic>> rows;

  const ReportPreview({
    required this.reportType,
    this.startDate,
    this.endDate,
    required this.rowCount,
    required this.rows,
  });

  factory ReportPreview.fromJson(Map<String, dynamic> json) {
    return ReportPreview(
      reportType: json['reportType'] as String? ?? 'Report',
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'] as String)
          : null,
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'] as String)
          : null,
      rowCount: (json['rowCount'] as num?)?.toInt() ?? 0,
      rows: (json['rows'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .toList() ??
          const [],
    );
  }

  /// Column headers — derived from the first row's keys, prettified.
  List<String> get columns {
    if (rows.isEmpty) return const [];
    return rows.first.keys.map(_prettify).toList();
  }

  /// Raw column keys (matching the original JSON).
  List<String> get rawColumns {
    if (rows.isEmpty) return const [];
    return rows.first.keys.toList();
  }

  static String _prettify(String key) {
    // "asset_name" -> "Asset Name"
    return key
        .split('_')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}

class ReportType {
  static const assets = 'Assets';
  static const clients = 'Clients';
  static const tickets = 'Tickets';
  static const departments = 'Departments';
  static const maintenance = 'Maintenance';
  static const technicianPerformance = 'Technician Performance';

  static const all = [
    assets,
    clients,
    tickets,
    departments,
    maintenance,
    technicianPerformance,
  ];
}