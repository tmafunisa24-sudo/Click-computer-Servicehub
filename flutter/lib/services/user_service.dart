// lib/services/user_service.dart

import '../api/user_api.dart';
import '../models/profile.dart';

class UserService {
  final UserApi _api;
  UserService([UserApi? api]) : _api = api ?? UserApi();

  Future<List<Profile>> getUsers() => _api.getAll();

  Future<Profile> updateUser({
    required String userId,
    String? role,
    String? status,
  }) {
    return _api.updateUser(userId: userId, role: role, status: status);
  }
}