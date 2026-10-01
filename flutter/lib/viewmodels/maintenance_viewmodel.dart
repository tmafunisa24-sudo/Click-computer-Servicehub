// lib/viewmodels/maintenance_viewmodel.dart

import 'package:flutter/foundation.dart';
import '../models/dtos/maintenance_dto.dart';
import '../services/maintenance_service.dart';

class MaintenanceViewModel extends ChangeNotifier {
  final MaintenanceService _service;
  MaintenanceViewModel([MaintenanceService? service])
      : _service = service ?? MaintenanceService();

  // ── List ──
  List<MaintenanceRecord> _records = [];
  bool _isLoading = false;
  String? _error;
  String? _statusFilter;

  // ── Detail ──
  MaintenanceRecord? _current;
  bool _isLoadingDetail = false;
  String? _detailError;

  // ── Submit ──
  bool _isSubmitting = false;
  String? _submitError;

  // ── Getters: list ──
  List<MaintenanceRecord> get records => _records;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get statusFilter => _statusFilter;

  List<MaintenanceRecord> get filteredRecords {
    if (_statusFilter == null || _statusFilter!.isEmpty) return _records;
    return _records
        .where((r) => r.status.toLowerCase() == _statusFilter!.toLowerCase())
        .toList();
  }

  // ── Getters: detail ──
  MaintenanceRecord? get current => _current;
  bool get isLoadingDetail => _isLoadingDetail;
  String? get detailError => _detailError;

  // ── Getters: submit ──
  bool get isSubmitting => _isSubmitting;
  String? get submitError => _submitError;

  // ── Derived stats ──
  int get totalCount => _records.length;
  int get pendingCount => _records
      .where((r) => r.status.toLowerCase() == 'pending')
      .length;
  int get inProgressCount =>
      _records.where((r) => r.status.toLowerCase() == 'in progress').length;
  int get completedCount =>
      _records.where((r) => r.status.toLowerCase() == 'completed').length;
  int get cancelledCount =>
      _records.where((r) => r.status.toLowerCase() == 'cancelled').length;

  // ── Actions ──

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _records = await _service.getAll();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _records = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load();

  void setStatusFilter(String? status) {
    _statusFilter = (status == null || status.isEmpty) ? null : status;
    notifyListeners();
  }

  Future<void> loadRecord(String id) async {
    _isLoadingDetail = true;
    _detailError = null;
    _current = null;
    notifyListeners();

    try {
      _current = await _service.getById(id);
      _detailError = null;
    } catch (e) {
      _detailError = e.toString();
      _current = null;
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  Future<bool> createRecord(MaintenanceRequest request) async {
    _isSubmitting = true;
    _submitError = null;
    notifyListeners();

    try {
      await _service.create(request);
      await load(); // refresh list
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _submitError = e.toString();
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateRecord(String id, MaintenanceRequest request) async {
    _isSubmitting = true;
    _submitError = null;
    notifyListeners();

    try {
      await _service.update(id, request);
      await loadRecord(id);
      await load();
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _submitError = e.toString();
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteRecord(String id) async {
    try {
      await _service.delete(id);
      await load();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearSubmitError() {
    _submitError = null;
    notifyListeners();
  }
}