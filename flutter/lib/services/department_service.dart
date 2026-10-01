// lib/services/department_service.dart

import '../api/department_api.dart';
import '../models/dtos/department_dto.dart';

class DepartmentService {
  final DepartmentApi _api;
  DepartmentService([DepartmentApi? api]) : _api = api ?? DepartmentApi();

  Future<List<DepartmentDto>> getAll() => _api.getAll();
  Future<void> create(DepartmentRequest request) => _api.create(request);
  Future<void> update(String id, DepartmentRequest request) =>
      _api.update(id, request);
  Future<void> delete(String id) => _api.delete(id);
}