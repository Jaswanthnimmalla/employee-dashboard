import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  bool _isEditing = false;

  String name = '';
  String email = '';
  String role = '';
  String adminLevel = '';
  String permissions = '';
  String phone = '';
  String profileImageUrl = '';
  String employeeCount = '0';
  String departmentCount = '0';

  File? _selectedImage;

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _adminLevelController = TextEditingController();
  final TextEditingController _permissionsController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAdminProfile();
  }

  Future<void> _loadAdminProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    DocumentSnapshot doc =
        await _firestore.collection('Admin').doc(user.uid).get();

    if (!doc.exists) {
      doc = await _firestore.collection('users').doc(user.uid).get();
    }

    final data = doc.data() as Map<String, dynamic>?;

    if (data != null) {
      final employeesCount = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'Team Member')
          .count()
          .get();

      final departments =
          await _firestore.collection('departments').count().get();

      setState(() {
        name = data['name'] ?? 'Admin User';
        email = data['email'] ?? user.email ?? '';
        role = data['role'] ?? 'Super Admin';
        adminLevel = data['adminLevel'] ?? 'Full Access';
        permissions = data['permissions'] ?? 'All Permissions';
        phone = data['phone'] ?? '';
        profileImageUrl = data['profileImageUrl'] ?? '';
        employeeCount = employeesCount.count.toString();
        departmentCount = departments.count.toString();

        _nameController.text = name;
        _adminLevelController.text = adminLevel;
        _permissionsController.text = permissions;
        _phoneController.text = phone;

        _isLoading = false;
      });
    }
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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _auth.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedData = {
        'name': _nameController.text.trim(),
        'adminLevel': _adminLevelController.text.trim(),
        'permissions': _permissionsController.text.trim(),
        'phone': _phoneController.text.trim(),
      };

      final adminDoc = await _firestore.collection('Admin').doc(user.uid).get();

      if (adminDoc.exists) {
        await _firestore.collection('Admin').doc(user.uid).update(updatedData);
      } else {
        await _firestore.collection('users').doc(user.uid).update(updatedData);
      }

      setState(() {
        _isEditing = false;
        _isLoading = false;
      });

      await _loadAdminProfile();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admin profile updated successfully!'),
          backgroundColor: Color(0xFF27AE60),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error updating profile'),
          backgroundColor: Color(0xFFE74C3C),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.2),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool enabled = false,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          prefixIcon: Icon(icon, color: const Color(0xFFE74C3C)),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.grey.shade400,
              width: 1.3,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.grey.shade400,
              width: 1.3,
            ),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(
              color: Color(0xFFE74C3C),
              width: 1.6,
            ),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Required field';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFE74C3C),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        elevation: 6,
        centerTitle: true,
        title: const Text(
          'Admin Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: const Color(0xFFE74C3C),
        actions: [
          IconButton(
            icon: Icon(
              _isEditing ? Icons.close : Icons.edit,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
                if (!_isEditing) {
                  _nameController.text = name;
                  _adminLevelController.text = adminLevel;
                  _permissionsController.text = permissions;
                  _phoneController.text = phone;
                }
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(size.width < 600 ? 16 : 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Employees Managed',
                          employeeCount,
                          Icons.people_alt,
                          const Color(0xFF3498DB),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Departments',
                          departmentCount,
                          Icons.business,
                          const Color(0xFF27AE60),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFE74C3C),
                            width: 3,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: size.width < 600 ? 55 : 65,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: _selectedImage != null
                              ? FileImage(_selectedImage!)
                              : (profileImageUrl.isNotEmpty
                                  ? NetworkImage(profileImageUrl)
                                  : null) as ImageProvider?,
                          child:
                              profileImageUrl.isEmpty && _selectedImage == null
                                  ? const Icon(
                                      Icons.admin_panel_settings,
                                      size: 55,
                                      color: Colors.grey,
                                    )
                                  : null,
                        ),
                      ),
                      if (_isEditing)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFFE74C3C),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE74C3C), Color(0xFFC0392B)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      role,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE74C3C).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFFE74C3C).withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.verified,
                            color: Color(0xFFE74C3C), size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Verified Administrator',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFE74C3C),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildField(
                    label: 'Full Name',
                    icon: Icons.person,
                    controller: _nameController,
                    enabled: _isEditing,
                  ),
                  _buildField(
                    label: 'Admin Level',
                    icon: Icons.verified_user,
                    controller: _adminLevelController,
                    enabled: _isEditing,
                    hint: 'Super Admin / Manager / Viewer',
                  ),
                  _buildField(
                    label: 'Permissions',
                    icon: Icons.security,
                    controller: _permissionsController,
                    enabled: _isEditing,
                    hint: 'Full Access / Limited Access',
                  ),
                  _buildField(
                    label: 'Phone Number',
                    icon: Icons.phone,
                    controller: _phoneController,
                    enabled: _isEditing,
                  ),
                  _buildField(
                    label: 'Email Address',
                    icon: Icons.email,
                    controller: TextEditingController(text: email),
                    enabled: false,
                  ),
                  const SizedBox(height: 22),
                  if (_isEditing)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _saveProfile,
                        icon: const Icon(Icons.save),
                        label: const Text(
                          'Update Admin Profile',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.4,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE74C3C),
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: const Color(0xFFE74C3C).withOpacity(0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: const Color(0xFFE74C3C), size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Admin Information',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow('Last Login',
                            DateTime.now().toString().substring(0, 16)),
                        _buildInfoRow('Account Status', 'Active'),
                        _buildInfoRow('2FA Status', 'Enabled'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
          ),
        ],
      ),
    );
  }
}
