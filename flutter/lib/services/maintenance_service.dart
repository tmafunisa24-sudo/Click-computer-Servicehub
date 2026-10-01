// lib/services/maintenance_service.dart

import '../api/maintenance_api.dart';
import '../models/dtos/maintenance_dto.dart';

class MaintenanceService {
  final MaintenanceApi _api;
  MaintenanceService([MaintenanceApi? api]) : _api = api ?? MaintenanceApi();

  Future<List<MaintenanceRecord>> getAll() => _api.getAll();
  Future<MaintenanceRecord> getById(String id) => _api.getById(id);
  Future<String> create(MaintenanceRequest request) => _api.create(request);
  Future<void> update(String id, MaintenanceRequest request) =>
      _api.update(id, request);
  Future<void> delete(String id) => _api.delete(id);
}