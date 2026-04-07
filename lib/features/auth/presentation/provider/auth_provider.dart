import 'package:flutter/material.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository authRepository;

  UserModel? _user;
  bool _isLoading = true;
  bool _isAuthenticated = false;

  AuthProvider({required this.authRepository}) {
    _initAuth();
  }

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;

  void _initAuth() {
    // Listen to auth state changes
    authRepository.authStateChanges.listen((UserModel? user) {
      _user = user;
      _isAuthenticated = user != null;
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<bool> signup(String email, String password, String name) async {
    _setLoading(true);

    try {
      final user = await authRepository.signup(email, password, name);
      _user = user;
      _isAuthenticated = true;
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);

    try {
      final user = await authRepository.login(email, password);
      _user = user;
      _isAuthenticated = true;
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> logout() async {
    _setLoading(true);

    try {
      await authRepository.logout();
      _user = null;
      _isAuthenticated = false;
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
