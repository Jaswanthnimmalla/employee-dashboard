import 'package:firebase_auth/firebase_auth.dart';
import 'package:employee_dashboard_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:employee_dashboard_app/features/auth/data/models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  @override
  Future<UserModel> signup(String email, String password, String name) async {
    try {
      print('📝 Attempting to signup: $email');

      UserCredential userCredential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        await user.updateDisplayName(name);
        await user.reload();

        print('✅ Signup successful: ${user.email}');
        return UserModel(
          id: user.uid,
          email: user.email ?? email,
          name: name,
          avatar: user.photoURL,
        );
      } else {
        throw Exception('Signup failed - user is null');
      }
    } on FirebaseAuthException catch (e) {
      print('❌ Signup error: ${e.code} - ${e.message}');
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'This email is already registered. Please login instead.';
          break;
        case 'invalid-email':
          message = 'Invalid email address. Please enter a valid email.';
          break;
        case 'weak-password':
          message = 'Password is too weak. Please use at least 6 characters.';
          break;
        case 'operation-not-allowed':
          message =
              'Email/Password signup is not enabled. Please contact support.';
          break;
        default:
          message = 'Signup failed: ${e.message}';
      }
      throw Exception(message);
    } catch (e) {
      print('❌ Signup unexpected error: $e');
      throw Exception('Signup failed: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      print('🔐 Attempting login: $email');

      UserCredential userCredential =
          await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        print('✅ Login successful: ${user.email}');
        return UserModel(
          id: user.uid,
          email: user.email ?? email,
          name: user.displayName ?? 'Employee',
          avatar: user.photoURL,
        );
      } else {
        throw Exception('Login failed - user is null');
      }
    } on FirebaseAuthException catch (e) {
      print('❌ Login error: ${e.code} - ${e.message}');
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No account found with this email. Please sign up first.';
          break;
        case 'wrong-password':
          message = 'Wrong password. Please try again.';
          break;
        case 'invalid-email':
          message = 'Invalid email address. Please check and try again.';
          break;
        case 'user-disabled':
          message = 'This account has been disabled. Please contact support.';
          break;
        case 'too-many-requests':
          message = 'Too many failed attempts. Please try again later.';
          break;
        default:
          message = 'Login failed: ${e.message}';
      }
      throw Exception(message);
    } catch (e) {
      print('❌ Login unexpected error: $e');
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
      print('✅ Logout successful');
    } catch (e) {
      print('❌ Logout error: $e');
      throw Exception('Logout failed: ${e.toString()}');
    }
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((User? user) {
      if (user != null) {
        print('👤 Auth state changed: ${user.email} - Logged in');
        return UserModel(
          id: user.uid,
          email: user.email ?? '',
          name: user.displayName ?? 'Employee',
          avatar: user.photoURL,
        );
      } else {
        print('👤 Auth state changed: No user logged in');
        return null;
      }
    });
  }

  @override
  UserModel? getCurrentUser() {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      return UserModel(
        id: user.uid,
        email: user.email ?? '',
        name: user.displayName ?? 'Employee',
        avatar: user.photoURL,
      );
    }
    return null;
  }
}
