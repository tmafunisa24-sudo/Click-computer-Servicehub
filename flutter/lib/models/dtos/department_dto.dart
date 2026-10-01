// lib/models/dtos/department_dto.dart

class DepartmentDto {
  final String id;
  final String name;
  final String? description;
  final int employeeCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DepartmentDto({
    required this.id,
    required this.name,
    this.description,
    this.employeeCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory DepartmentDto.fromJson(Map<String, dynamic> json) {
    return DepartmentDto(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      employeeCount: (json['employeeCount'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }
}

class DepartmentRequest {
  final String name;
  final String? description;

  const DepartmentRequest({
    required this.name,
    this.description,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        if (description != null && description!.trim().isNotEmpty)
          'description': description!.trim(),
      };
}