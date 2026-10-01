// lib/viewmodels/auth_viewmodel.dart

import 'package:flutter/foundation.dart';
import '../models/profile.dart';
import '../services/auth_service.dart';


enum AuthState {
  /// App just started, we don't know if user is logged in yet.
  unknown,

  /// User is authenticated.
  authenticated,

  /// User is not authenticated.
  unauthenticated,
}

class AuthViewModel extends ChangeNotifier {
  final AuthService _service;
  AuthViewModel([AuthService? service]) : _service = service ?? AuthService();

  AuthState _state = AuthState.unknown;
  Profile? _user;
  String? _error;
  bool _isLoading = false;
  bool _isUpdating = false;
  String? _updateError;
  bool _isRegistering = false;
  String? _registerError;
  bool _isSendingReset = false;
  String? _resetError;
  bool _resetSent = false;
    bool _registrationEmailSent = false;
  bool _registrationNeedsConfirmation = false;
  String? _pendingConfirmationEmail;


  // ── Getters ──
  AuthState get state => _state;
  Profile? get user => _user;
  String? get error => _error;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isTechnician => _user?.isTechnician ?? false;
  bool get isClient => _user?.isClient ?? false;
  bool get isUpdating => _isUpdating;
  String? get updateError => _updateError;
  bool get isRegistering => _isRegistering;
  String? get registerError => _registerError;
  bool get isSendingReset => _isSendingReset;
  String? get resetError => _resetError;
  bool get resetSent => _resetSent;
    bool get registrationEmailSent => _registrationEmailSent;
  bool get registrationNeedsConfirmation => _registrationNeedsConfirmation;
  String? get pendingConfirmationEmail => _pendingConfirmationEmail;
  
  /// Called once at app startup.
  /// Tries to fetch the current user using any stored cookie.
  Future<void> bootstrap() async {
    try {
      final user = await _service.getCurrentUser();
      _user = user;
      _state = AuthState.authenticated;
    } catch (_) {
      _user = null;
      _state = AuthState.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _service.login(
        email: email,
        password: password,
        rememberMe: rememberMe,
      );
      _user = user;
      _state = AuthState.authenticated;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _user = null;
      _state = AuthState.unauthenticated;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _service.logout();
    _user = null;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }
  
  /// Register a new account. On success, the user is auto-logged-in
  /// (the backend sets the auth cookie during registration).
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    _isRegistering = true;
    _registerError = null;
    _registrationEmailSent = false;
    _registrationNeedsConfirmation = false;
    _pendingConfirmationEmail = null;
    notifyListeners();

    try {
      final (registeredEmail, requiresConfirmation, error) =
          await _service.register(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );

      _isRegistering = false;

      if (error != null) {
        _registerError = error;
        notifyListeners();
        return false;
      }

      _registrationEmailSent = true;
      _registrationNeedsConfirmation = requiresConfirmation;
      _pendingConfirmationEmail = registeredEmail;
      notifyListeners();
      return false;
    } catch (e) {
      _registerError = e.toString();
      _isRegistering = false;
      notifyListeners();
      return false;
    }
  }

  /// Request a password-reset email. On success, [resetSent] becomes true
  /// and the UI should display a "check your email" confirmation.
  /// We never reveal whether the email exists (security).
  Future<bool> forgotPassword({required String email}) async {
    _isSendingReset = true;
    _resetError = null;
    _resetSent = false;
    notifyListeners();

    try {
      await _service.forgotPassword(email: email);
      _isSendingReset = false;
      _resetSent = true;
      notifyListeners();
      return true;
    } catch (e) {
      _resetError = e.toString();
      _isSendingReset = false;
      notifyListeners();
      return false;
    }
  }

  void clearRegisterError() {
    _registerError = null;
    _registrationEmailSent = false;
    _registrationNeedsConfirmation = false;
    _pendingConfirmationEmail = null;
    notifyListeners();
  }

  void clearResetState() {
    _resetError = null;
    _resetSent = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Update the current user's profile.
  /// On success, refreshes `_user` in place.
  Future<bool> updateProfile({
    String? fullName,
    String? phone,
    String? position,
  }) async {
    _isUpdating = true;
    _updateError = null;
    notifyListeners();

    try {
      final updated = await _service.updateProfile(
        fullName: fullName,
        phone: phone,
        position: position,
      );
      _user = updated;
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