import '../../data/models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel> signup(String email, String password, String name);
  Future<UserModel> login(String email, String password);
  Future<void> logout();
  Stream<UserModel?> get authStateChanges;
  UserModel? getCurrentUser();
}
