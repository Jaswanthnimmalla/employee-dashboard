import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:employee_dashboard_app/admin/data/presentation/screens/admin_dashboard_screen.dart';
import 'package:employee_dashboard_app/core/services/cloudinary_service.dart';
import 'package:employee_dashboard_app/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isSignup = false;
  File? _selectedImage;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _selectedRole = 'Team Member';

  final Color _primaryColor = const Color(0xFF6C5CE7);
  final Color _adminColor = const Color(0xFFE74C3C);
  final Color _userColor = const Color(0xFF00B894);
  final Color _backgroundColor = const Color(0xFFF5F6FA);
  final Color _textColor = const Color(0xFF2D3436);
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _departmentFocus = FocusNode();
  final FocusNode _positionFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();

  String _greetingMessage = '';
  String _greetingEmoji = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
    _updateGreeting();
  }

  void _updateGreeting() {
    final hour = DateTime.now().hour;
    setState(() {
      if (hour < 12) {
        _greetingMessage = 'Good Morning';
        _greetingEmoji = '🌅';
      } else if (hour < 17) {
        _greetingMessage = 'Good Afternoon';
        _greetingEmoji = '☀️';
      } else {
        _greetingMessage = 'Good Evening';
        _greetingEmoji = '🌙';
      }
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _nameFocus.dispose();
    _departmentFocus.dispose();
    _positionFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  Color get _currentRoleColor =>
      _selectedRole == 'admin' ? _adminColor : _userColor;

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isSignup) {
        if (_selectedImage == null) {
          _showSnackbar('Please upload profile photo', Colors.red);
          setState(() => _isLoading = false);
          return;
        }

        final email = _emailController.text.trim().toLowerCase();
        final password = _passwordController.text.trim();
        final name = _nameController.text.trim();

        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (userCredential.user != null) {
          await userCredential.user!.updateDisplayName(name);

          String imageUrl = '';
          if (_selectedImage != null) {
            final uploadedUrl = await CloudinaryService.uploadProfilePhoto(
              _selectedImage!,
              userId: userCredential.user!.uid,
            );
            if (uploadedUrl != null) {
              imageUrl = uploadedUrl;
            }
          }

          final userData = {
            'name': name,
            'email': email,
            'role': _selectedRole == 'admin' ? 'admin' : 'Team Member',
            'department': _departmentController.text.trim(),
            'position': _positionController.text.trim(),
            'phone': _phoneController.text.trim(),
            'profileImageUrl': imageUrl,
            'isActive': true,
            'joinDate': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
          };

          if (_selectedRole == 'admin') {
            await _firestore
                .collection('Admin')
                .doc(userCredential.user!.uid)
                .set(userData);
          } else {
            await _firestore
                .collection('users')
                .doc(userCredential.user!.uid)
                .set(userData);
          }

          setState(() {
            _isLoading = false;
            _isSignup = false;
            _emailController.clear();
            _passwordController.clear();
            _nameController.clear();
            _departmentController.clear();
            _positionController.clear();
            _phoneController.clear();
            _selectedImage = null;
          });

          _showSnackbar(
              'Account created successfully. Please login.', Colors.green);
        }
      } else {
        final email = _emailController.text.trim().toLowerCase();
        final password = _passwordController.text.trim();

        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (userCredential.user != null) {
          String userRole =
              await _checkUserRole(email, userCredential.user!.uid);

          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('userEmail', email);
          await prefs.setString('userRole', userRole);
          await prefs.setString('userId', userCredential.user!.uid);
          await prefs.setString(
              'userName', userCredential.user!.displayName ?? '');

          setState(() {
            _isLoading = false;
          });

          await _showSuccessAnimation();

          if (mounted) {
            if (userRole == 'admin') {
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const AdminDashboardScreen(),
                  transitionDuration: const Duration(milliseconds: 300),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                ),
              );
            } else {
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const DashboardScreen(),
                  transitionDuration: const Duration(milliseconds: 300),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                ),
              );
            }
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);

      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'Email already registered. Please login.';
          break;
        case 'user-not-found':
          errorMessage = 'No account found. Please sign up first.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address format.';
          break;
        case 'weak-password':
          errorMessage = 'Password should be at least 6 characters.';
          break;
        case 'network-request-failed':
          errorMessage = 'Network error. Check your internet connection.';
          break;
        default:
          errorMessage = 'Authentication failed. Please try again.';
      }
      _showSnackbar(errorMessage, Colors.red);
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackbar(
          'An unexpected error occurred. Please try again.', Colors.red);
    }
  }

  Future<void> _showSuccessAnimation() async {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (context) => Center(
        child: TweenAnimationBuilder(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 300),
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: const Icon(Icons.check_circle,
                    color: Colors.green, size: 50),
              ),
            );
          },
        ),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<String> _checkUserRole(String email, String uid) async {
    try {
      final adminDoc = await _firestore.collection('Admin').doc(uid).get();
      if (adminDoc.exists) {
        await _firestore.collection('users').doc(uid).set({
          'role': 'admin',
        }, SetOptions(merge: true));
        return 'admin';
      }

      final adminQuery = await _firestore
          .collection('Admin')
          .where('email', isEqualTo: email)
          .get();

      if (adminQuery.docs.isNotEmpty) {
        await _firestore.collection('users').doc(uid).set({
          'role': 'admin',
        }, SetOptions(merge: true));
        return 'admin';
      }

      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final role = userDoc.data()?['role'] ?? 'user';
        return role == 'admin' ? 'admin' : 'user';
      }

      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return 'user';
    } catch (e) {
      return 'user';
    }
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Minimum 8 characters required';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Must contain uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Must contain lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Must contain number';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Must contain special character';
    }
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }
    return null;
  }

  Future<void> _sendPasswordResetEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnackbar('Please enter your email', Colors.red);
      return;
    }
    if (_validateEmail(email) != null) {
      _showSnackbar('Please enter a valid email address', Colors.red);
      return;
    }
    try {
      await _auth.sendPasswordResetEmail(email: email);
      _showSnackbar('Password reset email sent to $email', Colors.green);
    } catch (e) {
      _showSnackbar(
          'Failed to send reset email. Please try again.', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 600;
    final currentColor = _isSignup
        ? _currentRoleColor
        : (_selectedRole == 'admin' ? _adminColor : _primaryColor);

    return Scaffold(
      backgroundColor: _backgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: _isSignup
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: currentColor),
                onPressed: () => setState(() => _isSignup = false),
              )
            : null,
        title: Text(
          _isSignup ? 'Create Account' : 'Employee Dashboard',
          style: TextStyle(
            color: currentColor,
            fontWeight: FontWeight.bold,
            fontSize: isSmall ? 22 : 24,
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            // Background decorative circles
            Positioned(
              top: -50,
              right: -30,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: currentColor.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              left: -40,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  color: currentColor.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmall ? 24 : size.width * 0.25,
                    vertical: 20,
                  ),
                  child: FadeTransition(
                    opacity: _opacityAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildRoleSelector(currentColor, isSmall),
                          const SizedBox(height: 20),
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      currentColor,
                                      currentColor.withOpacity(0.8),
                                    ],
                                  ),
                                ),
                                child: _selectedRole == 'admin'
                                    ? Image.asset(
                                        'assets/admin_profile.png',
                                        width: 90,
                                        height: 90,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Icon(
                                            Icons.admin_panel_settings,
                                            size: 45,
                                            color: Colors.white,
                                          );
                                        },
                                      )
                                    : Image.asset(
                                        'assets/user_logo.png',
                                        width: 90,
                                        height: 90,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Icon(
                                            Icons.person,
                                            size: 45,
                                            color: Colors.white,
                                          );
                                        },
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _isSignup ? 'Create Account' : 'Welcome Back',
                            style: TextStyle(
                              fontSize: isSmall ? 26 : 30,
                              fontWeight: FontWeight.bold,
                              color: _textColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _isSignup
                                ? 'Sign up to continue'
                                : 'Sign in to continue',
                            style: TextStyle(
                              fontSize: isSmall ? 13 : 15,
                              color: _textColor.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: EdgeInsets.all(isSmall ? 20 : 24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  if (_isSignup) ...[
                                    Center(
                                      child: GestureDetector(
                                        onTap: _pickImage,
                                        child: CircleAvatar(
                                          radius: 45,
                                          backgroundColor: Colors.grey.shade200,
                                          backgroundImage:
                                              _selectedImage != null
                                                  ? FileImage(_selectedImage!)
                                                  : null,
                                          child: _selectedImage == null
                                              ? const Icon(Icons.camera_alt,
                                                  size: 28)
                                              : null,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    TextFormField(
                                      controller: _nameController,
                                      focusNode: _nameFocus,
                                      textInputAction: TextInputAction.next,
                                      onFieldSubmitted: (_) {
                                        FocusScope.of(context)
                                            .requestFocus(_departmentFocus);
                                      },
                                      decoration: InputDecoration(
                                        labelText: 'Full Name',
                                        prefixIcon: Icon(Icons.person_outline,
                                            color: currentColor, size: 20),
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                      ),
                                      validator: _validateName,
                                    ),
                                    const SizedBox(height: 14),
                                    TextFormField(
                                      controller: _departmentController,
                                      focusNode: _departmentFocus,
                                      textInputAction: TextInputAction.next,
                                      onFieldSubmitted: (_) {
                                        FocusScope.of(context)
                                            .requestFocus(_positionFocus);
                                      },
                                      decoration: InputDecoration(
                                        labelText: 'Department',
                                        prefixIcon: Icon(Icons.business,
                                            color: currentColor, size: 20),
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                      ),
                                      validator: (value) {
                                        if (_isSignup &&
                                            (value == null ||
                                                value.trim().isEmpty)) {
                                          return 'Department is required';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 14),
                                    TextFormField(
                                      controller: _positionController,
                                      focusNode: _positionFocus,
                                      textInputAction: TextInputAction.next,
                                      onFieldSubmitted: (_) {
                                        FocusScope.of(context)
                                            .requestFocus(_phoneFocus);
                                      },
                                      decoration: InputDecoration(
                                        labelText: 'Position',
                                        prefixIcon: Icon(Icons.work,
                                            color: currentColor, size: 20),
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                      ),
                                      validator: (value) {
                                        if (_isSignup &&
                                            (value == null ||
                                                value.trim().isEmpty)) {
                                          return 'Position is required';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 14),
                                    TextFormField(
                                      controller: _phoneController,
                                      focusNode: _phoneFocus,
                                      keyboardType: TextInputType.phone,
                                      textInputAction: TextInputAction.next,
                                      onFieldSubmitted: (_) {
                                        FocusScope.of(context)
                                            .requestFocus(_emailFocus);
                                      },
                                      decoration: InputDecoration(
                                        labelText: 'Phone',
                                        prefixIcon: Icon(Icons.phone,
                                            color: currentColor, size: 20),
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                      ),
                                      validator: (value) {
                                        if (_isSignup &&
                                            (value == null ||
                                                value.trim().isEmpty)) {
                                          return 'Phone number is required';
                                        }
                                        if (_isSignup &&
                                            !RegExp(r'^[0-9]{10}$').hasMatch(
                                                value?.trim() ?? '')) {
                                          return 'Enter valid 10-digit phone number';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 14),
                                  ],
                                  TextFormField(
                                    controller: _emailController,
                                    focusNode: _emailFocus,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    onFieldSubmitted: (_) =>
                                        FocusScope.of(context)
                                            .requestFocus(_passwordFocus),
                                    decoration: InputDecoration(
                                      labelText: 'Email',
                                      prefixIcon: Icon(Icons.email,
                                          color: currentColor, size: 20),
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                    validator: _validateEmail,
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _passwordController,
                                    focusNode: _passwordFocus,
                                    obscureText: !_isPasswordVisible,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _handleAuth(),
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      prefixIcon: Icon(Icons.lock,
                                          color: currentColor, size: 20),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _isPasswordVisible
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                          color: currentColor,
                                        ),
                                        onPressed: () {
                                          setState(() => _isPasswordVisible =
                                              !_isPasswordVisible);
                                        },
                                      ),
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                    validator: _validatePassword,
                                  ),
                                  if (!_isSignup) ...[
                                    const SizedBox(height: 10),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: _sendPasswordResetEmail,
                                        child: Text(
                                          'Forgot Password?',
                                          style: TextStyle(
                                            color: currentColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: _isLoading
                                        ? Center(
                                            child: SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(currentColor),
                                              ),
                                            ),
                                          )
                                        : ElevatedButton(
                                            onPressed: _handleAuth,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: _isSignup
                                                  ? (_selectedRole == 'admin'
                                                      ? _adminColor
                                                      : _userColor)
                                                  : currentColor,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              elevation: 2,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  _isSignup
                                                      ? Icons.person_add
                                                      : Icons.login,
                                                  color: Colors.white,
                                                  size: 18,
                                                ),
                                                const SizedBox(width: 10),
                                                Text(
                                                  _isSignup
                                                      ? 'SIGN UP'
                                                      : 'LOGIN',
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _isSignup
                                    ? 'Already have an account? '
                                    : "Don't have an account? ",
                                style: TextStyle(
                                    color: _textColor.withOpacity(0.6),
                                    fontSize: 12),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isSignup = !_isSignup;
                                    _emailController.clear();
                                    _passwordController.clear();
                                    _nameController.clear();
                                    _departmentController.clear();
                                    _positionController.clear();
                                    _phoneController.clear();
                                    _selectedImage = null;
                                    _isLoading = false;
                                  });
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                ),
                                child: Text(
                                  _isSignup ? 'Login' : 'Sign Up',
                                  style: TextStyle(
                                    color: currentColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '© 2025 Employee Dashboard',
                            style: TextStyle(
                                color: _textColor.withOpacity(0.4),
                                fontSize: 10),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSelector(Color currentColor, bool isSmall) {
    if (_isSignup) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildRoleOption(
              'User',
              Icons.person,
              _userColor,
              _selectedRole == 'user',
              () => setState(() => _selectedRole = 'user'),
              isSmall),
          _buildRoleOption(
              'Admin',
              Icons.admin_panel_settings,
              _adminColor,
              _selectedRole == 'admin',
              () => setState(() => _selectedRole = 'admin'),
              isSmall),
        ],
      ),
    );
  }

  Widget _buildRoleOption(String label, IconData icon, Color color,
      bool isSelected, VoidCallback onTap, bool isSmall) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: isSmall ? 8 : 10),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: isSelected ? Colors.white : color,
                  size: isSmall ? 16 : 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : color,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: isSmall ? 12 : 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
