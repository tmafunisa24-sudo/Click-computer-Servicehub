// lib/models/maintenance.dart

class Maintenance {
  final String id;
  final String assetId;
  final String technicianId;
  final String problem;
  final String? solution;
  final DateTime? maintenanceDate;
  final DateTime? nextServiceDate;
  final double? maintenanceCost;
  final String status;
  final DateTime? createdAt;

  const Maintenance({
    required this.id,
    required this.assetId,
    required this.technicianId,
    required this.problem,
    this.solution,
    this.maintenanceDate,
    this.nextServiceDate,
    this.maintenanceCost,
    required this.status,
    this.createdAt,
  });

  factory Maintenance.fromJson(Map<String, dynamic> json) {
    return Maintenance(
      id: json['id'] as String,
      assetId: json['asset_id'] as String,
      technicianId: json['technician_id'] as String,
      problem: json['problem'] as String? ?? '',
      solution: json['solution'] as String?,
      maintenanceDate: json['maintenance_date'] != null
          ? DateTime.parse(json['maintenance_date'] as String)
          : null,
      nextServiceDate: json['next_service_date'] != null
          ? DateTime.parse(json['next_service_date'] as String)
          : null,
      maintenanceCost: json['maintenance_cost'] != null
          ? (json['maintenance_cost'] as num).toDouble()
          : null,
      status: json['status'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'asset_id': assetId,
      'technician_id': technicianId,
      'problem': problem,
      'solution': solution,
      'maintenance_date': maintenanceDate?.toIso8601String(),
      'next_service_date': nextServiceDate?.toIso8601String(),
      'maintenance_cost': maintenanceCost,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  Maintenance copyWith({
    String? id,
    String? assetId,
    String? technicianId,
    String? problem,
    String? solution,
    DateTime? maintenanceDate,
    DateTime? nextServiceDate,
    double? maintenanceCost,
    String? status,
    DateTime? createdAt,
  }) {
    return Maintenance(
      id: id ?? this.id,
      assetId: assetId ?? this.assetId,
      technicianId: technicianId ?? this.technicianId,
      problem: problem ?? this.problem,
      solution: solution ?? this.solution,
      maintenanceDate: maintenanceDate ?? this.maintenanceDate,
      nextServiceDate: nextServiceDate ?? this.nextServiceDate,
      maintenanceCost: maintenanceCost ?? this.maintenanceCost,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Maintenance &&
          other.id == id &&
          other.assetId == assetId &&
          other.technicianId == technicianId &&
          other.problem == problem &&
          other.solution == solution &&
          other.maintenanceDate == maintenanceDate &&
          other.nextServiceDate == nextServiceDate &&
          other.maintenanceCost == maintenanceCost &&
          other.status == status &&
          other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        assetId,
        technicianId,
        problem,
        solution,
        maintenanceDate,
        nextServiceDate,
        maintenanceCost,
        status,
        createdAt,
      );
}