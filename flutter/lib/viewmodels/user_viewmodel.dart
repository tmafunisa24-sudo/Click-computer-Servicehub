// lib/viewmodels/user_viewmodel.dart

import 'package:flutter/foundation.dart';
import '../models/profile.dart';
import '../services/user_service.dart';

class UserViewModel extends ChangeNotifier {
  final UserService _service;
  UserViewModel([UserService? service]) : _service = service ?? UserService();

  // ── List state ──
  List<Profile> _users = [];
  bool _isLoading = false;
  String? _error;
  String? _searchTerm;
  String? _roleFilter;
  String? _statusFilter;

  // ── Update state ──
  bool _isUpdating = false;
  String? _updateError;

  // ── Getters: list ──
  List<Profile> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get searchTerm => _searchTerm;
  String? get roleFilter => _roleFilter;
  String? get statusFilter => _statusFilter;

  // ── Getters: update ──
  bool get isUpdating => _isUpdating;
  String? get updateError => _updateError;

  // ── Derived: filtered list ──
  List<Profile> get filteredUsers {
    Iterable<Profile> list = _users;

    if (_searchTerm != null && _searchTerm!.isNotEmpty) {
      final q = _searchTerm!.toLowerCase();
      list = list.where((u) =>
          u.fullName.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q));
    }

    if (_roleFilter != null && _roleFilter!.isNotEmpty) {
      list = list.where((u) =>
          u.role.toLowerCase() == _roleFilter!.toLowerCase());
    }

    if (_statusFilter != null && _statusFilter!.isNotEmpty) {
      list = list.where((u) =>
          u.status.toLowerCase() == _statusFilter!.toLowerCase());
    }

    return list.toList();
  }

  // ── Derived: stats (from full list, not filtered) ──
  int get totalCount => _users.length;
  int get clientCount =>
      _users.where((u) => u.role.toLowerCase() == 'client').length;
  int get technicianCount =>
      _users.where((u) => u.role.toLowerCase() == 'technician').length;
  int get adminCount =>
      _users.where((u) => u.role.toLowerCase() == 'admin').length;
  int get pendingCount => _users
      .where((u) =>
          u.status.toLowerCase() == 'pending' ||
          u.status.toLowerCase() == 'awaiting approval')
      .length;

  // ── Actions ──

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _users = await _service.getUsers();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _users = [];
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

  void setRoleFilter(String? role) {
    _roleFilter = (role == null || role.isEmpty) ? null : role;
    notifyListeners();
  }

  void setStatusFilter(String? status) {
    _statusFilter = (status == null || status.isEmpty) ? null : status;
    notifyListeners();
  }

  Future<bool> updateUser({
    required String userId,
    String? role,
    String? status,
  }) async {
    _isUpdating = true;
    _updateError = null;
    notifyListeners();

    try {
      final updated = await _service.updateUser(
        userId: userId,
        role: role,
        status: status,
      );

      // Replace in list
      final idx = _users.indexWhere((u) => u.id == updated.id);
      if (idx >= 0) {
        final copy = List<Profile>.from(_users);
        copy[idx] = updated;
        _users = copy;
      }

      _isUpdating = false;
      notifyListeners();
      return true;
    } catch (e) {
      _updateError = e.toString();
      _isUpdating = false;
      notifyListeners();
      return false;
    }
  }

  void clearUpdateError() {
    _updateError = null;
    notifyListeners();
  }
}