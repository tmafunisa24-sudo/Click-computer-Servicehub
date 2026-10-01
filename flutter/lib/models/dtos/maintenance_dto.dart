// lib/models/dtos/maintenance_dto.dart

class MaintenanceRecord {
  final String id;
  final String assetId;
  final String assetName;
  final String technicianId;
  final String technicianName;
  final String problem;
  final String? solution;
  final DateTime? maintenanceDate;
  final DateTime? nextServiceDate;
  final double? maintenanceCost;
  final String status;
  final DateTime? createdAt;

  const MaintenanceRecord({
    required this.id,
    required this.assetId,
    required this.assetName,
    required this.technicianId,
    required this.technicianName,
    required this.problem,
    this.solution,
    this.maintenanceDate,
    this.nextServiceDate,
    this.maintenanceCost,
    required this.status,
    this.createdAt,
  });

  factory MaintenanceRecord.fromJson(Map<String, dynamic> json) {
    return MaintenanceRecord(
      id: json['id'] as String? ?? '',
      assetId: json['assetId'] as String? ?? '',
      assetName: json['assetName'] as String? ?? 'Unknown asset',
      technicianId: json['technicianId'] as String? ?? '',
      technicianName: json['technicianName'] as String? ?? 'Unknown technician',
      problem: json['problem'] as String? ?? '',
      solution: json['solution'] as String?,
      maintenanceDate: json['maintenanceDate'] != null
          ? DateTime.tryParse(json['maintenanceDate'] as String)
          : null,
      nextServiceDate: json['nextServiceDate'] != null
          ? DateTime.tryParse(json['nextServiceDate'] as String)
          : null,
      maintenanceCost: json['maintenanceCost'] != null
          ? (json['maintenanceCost'] as num).toDouble()
          : null,
      status: json['status'] as String? ?? 'Open',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }
}

// Request shape for create/update
class MaintenanceRequest {
  final String? assetId;
  final String? technicianId;
  final String? problem;
  final String? solution;
  final DateTime? maintenanceDate;
  final DateTime? nextServiceDate;
  final double? maintenanceCost;
  final String? status;

  const MaintenanceRequest({
    this.assetId,
    this.technicianId,
    this.problem,
    this.solution,
    this.maintenanceDate,
    this.nextServiceDate,
    this.maintenanceCost,
    this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      if (assetId != null) 'assetId': assetId,
      if (technicianId != null) 'technicianId': technicianId,
      if (problem != null) 'problem': problem,
      if (solution != null) 'solution': solution,
      if (maintenanceDate != null)
        'maintenanceDate': maintenanceDate!.toIso8601String(),
      if (nextServiceDate != null)
        'nextServiceDate': nextServiceDate!.toIso8601String(),
      if (maintenanceCost != null) 'maintenanceCost': maintenanceCost,
      if (status != null) 'status': status,
    };
  }
}