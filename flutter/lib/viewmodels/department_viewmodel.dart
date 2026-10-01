// lib/viewmodels/department_viewmodel.dart

import 'package:flutter/foundation.dart';
import '../models/dtos/department_dto.dart';
import '../services/department_service.dart';

class DepartmentViewModel extends ChangeNotifier {
  final DepartmentService _service;
  DepartmentViewModel([DepartmentService? service])
      : _service = service ?? DepartmentService();

  List<DepartmentDto> _departments = [];
  bool _isLoading = false;
  String? _error;
  String? _searchTerm;

  bool _isSubmitting = false;
  String? _submitError;

  List<DepartmentDto> get departments => _departments;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get searchTerm => _searchTerm;
  bool get isSubmitting => _isSubmitting;
  String? get submitError => _submitError;

  List<DepartmentDto> get filteredDepartments {
    if (_searchTerm == null || _searchTerm!.isEmpty) return _departments;
    final q = _searchTerm!.toLowerCase();
    return _departments
        .where((d) =>
            d.name.toLowerCase().contains(q) ||
            (d.description ?? '').toLowerCase().contains(q))
        .toList();
  }

  int get totalCount => _departments.length;
  int get totalEmployees =>
      _departments.fold(0, (sum, d) => sum + d.employeeCount);

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _departments = await _service.getAll();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _departments = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load();

  void setSearchTerm(String? term) {
    _searchTerm = (term == null || term.trim().isEmpty) ? null : term.trim();
    notifyListeners();
  }

  Future<bool> create({required String name, String? description}) async {
    _isSubmitting = true;
    _submitError = null;
    notifyListeners();

    try {
      await _service.create(DepartmentRequest(name: name, description: description));
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

  Future<bool> update({
    required String id,
    required String name,
    String? description,
  }) async {
    _isSubmitting = true;
    _submitError = null;
    notifyListeners();

    try {
      await _service.update(
        id,
        DepartmentRequest(name: name, description: description),
      );
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

  Future<bool> delete(String id) async {
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