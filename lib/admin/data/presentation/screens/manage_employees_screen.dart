import 'package:employee_dashboard_app/admin/data/models/employee_model.dart';
import 'package:employee_dashboard_app/admin/data/presentation/provider/admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageEmployeesScreen extends StatefulWidget {
  const ManageEmployeesScreen({super.key});

  @override
  State<ManageEmployeesScreen> createState() => _ManageEmployeesScreenState();
}

class _ManageEmployeesScreenState extends State<ManageEmployeesScreen> {
  String _searchText = '';
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void showSafeSnackBar(BuildContext context, String message, Color color) {
    Future.microtask(() {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: color,
            behavior: SnackBarBehavior.fixed, // prevents off-screen error
          ),
        );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Employees',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 4,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF8B0000),
                Color(0xFFC0392B),
                Color(0xFFE74C3C),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: () => _showAddEmployeeDialog(),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.person_add,
                        size: 18,
                        color: Color(0xFFC0392B),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Add Employee',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFC0392B),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        padding: EdgeInsets.all(isSmall ? 16 : 24),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFE74C3C).withOpacity(0.35),
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search employees...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon:
                      Icon(Icons.search, color: const Color(0xFFE74C3C)),
                  suffixIcon: _searchText.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey.shade600),
                          onPressed: () {
                            setState(() {
                              _searchText = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchText = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Consumer<AdminProvider>(
                builder: (context, provider, _) {
                  final filteredEmployees =
                      provider.getFilteredEmployees(_searchText);
                  if (filteredEmployees.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_outline,
                              size: 80, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No employees found',
                            style: TextStyle(
                                fontSize: 18, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: filteredEmployees.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final employeeData = filteredEmployees[index];
                      final Map<String, dynamic> map =
                          employeeData as Map<String, dynamic>;

                      final EmployeeModel employee = EmployeeModel(
                        id: map['id'] ?? map['uid'] ?? '',
                        name: map['name']?.toString() ?? '',
                        email: map['email']?.toString() ?? '',
                        role: map['role']?.toString() ?? 'Team Member',
                        department: map['department']?.toString() ?? '',
                        position: map['position']?.toString() ?? '',
                        phone: map['phone']?.toString() ?? '',
                        joinDate: map['joinDate'] is Timestamp
                            ? (map['joinDate'] as Timestamp).toDate()
                            : DateTime.now(),
                        isActive: map['isActive'] is bool
                            ? map['isActive']
                            : map['isActive'].toString() == 'true',
                        profileImageUrl:
                            map['profileImageUrl']?.toString() ?? '',
                      );

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: employee.isActive
                                ? const Color(0xFFE74C3C).withOpacity(0.3)
                                : Colors.grey.shade200,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade100,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _showEmployeeDetailsDialog(employee),
                            borderRadius: BorderRadius.circular(16),
                            splashColor:
                                const Color(0xFFE74C3C).withOpacity(0.1),
                            highlightColor:
                                const Color(0xFFE74C3C).withOpacity(0.05),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: employee.isActive
                                            ? [
                                                const Color(0xFFE74C3C),
                                                const Color(0xFFC0392B)
                                              ]
                                            : [
                                                Colors.grey.shade400,
                                                Colors.grey.shade600
                                              ],
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        employee.name.isNotEmpty
                                            ? employee.name[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          employee.name,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey.shade800,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          employee.position.isNotEmpty
                                              ? employee.position
                                              : 'Team Member',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: const Color(0xFFE74C3C),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.phone,
                                                size: 14,
                                                color: Colors.grey.shade500),
                                            const SizedBox(width: 4),
                                            Text(
                                              employee.phone.isNotEmpty
                                                  ? employee.phone
                                                  : 'Not provided',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE74C3C)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.arrow_forward_ios,
                                      size: 18,
                                      color: const Color(0xFFE74C3C),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEmployeeDetailsDialog(EmployeeModel employee) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                width: constraints.maxWidth * 0.9,
                constraints: BoxConstraints(
                  maxWidth: 450,
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: const Color(0xFFE74C3C).withOpacity(0.3),
                      width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE74C3C),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(23),
                          topRight: Radius.circular(23),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.person,
                                color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  employee.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    employee.role,
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            _buildDetailCard(
                              icon: Icons.email_outlined,
                              label: 'Email Address',
                              value: employee.email,
                              color: const Color(0xFFE74C3C),
                            ),
                            const SizedBox(height: 10),
                            _buildDetailCard(
                              icon: Icons.business_outlined,
                              label: 'Department',
                              value: employee.department.trim().isEmpty
                                  ? 'Not specified'
                                  : employee.department,
                              color: const Color(0xFFE74C3C),
                            ),
                            const SizedBox(height: 10),
                            _buildDetailCard(
                              icon: Icons.work_outline,
                              label: 'Position',
                              value: employee.position.trim().isEmpty
                                  ? 'Not specified'
                                  : employee.position,
                              color: const Color(0xFFE74C3C),
                            ),
                            const SizedBox(height: 10),
                            _buildDetailCard(
                              icon: Icons.phone_outlined,
                              label: 'Phone Number',
                              value: employee.phone.trim().isEmpty
                                  ? 'Not provided'
                                  : employee.phone,
                              color: const Color(0xFFE74C3C),
                            ),
                            const SizedBox(height: 10),
                            _buildDetailCard(
                              icon: Icons.calendar_today,
                              label: 'Join Date',
                              value:
                                  '${employee.joinDate.day}/${employee.joinDate.month}/${employee.joinDate.year}',
                              color: const Color(0xFFE74C3C),
                            ),
                            const SizedBox(height: 10),
                            _buildDetailCard(
                              icon: Icons.fiber_manual_record,
                              label: 'Status',
                              value: employee.isActive ? 'Active' : 'Inactive',
                              color:
                                  employee.isActive ? Colors.green : Colors.red,
                              valueColor:
                                  employee.isActive ? Colors.green : Colors.red,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                        border: Border(
                            top: BorderSide(color: Colors.grey.shade200)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _toggleStatus(employee);
                              },
                              icon: Icon(
                                  employee.isActive
                                      ? Icons.block
                                      : Icons.check_circle,
                                  size: 18),
                              label: Text(employee.isActive
                                  ? 'Deactivate'
                                  : 'Activate'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: employee.isActive
                                    ? Colors.orange
                                    : Colors.green,
                                side: BorderSide(
                                    color: employee.isActive
                                        ? Colors.orange
                                        : Colors.green),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _showEditEmployeeDialog(context, employee);
                              },
                              icon: const Icon(Icons.edit, size: 18),
                              label: const Text('Edit'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE74C3C),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _confirmDelete(context, employee);
                              },
                              icon: const Icon(Icons.delete,
                                  size: 18, color: Colors.red),
                              label: const Text('Delete'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: valueColor ?? Colors.grey.shade800,
                    fontWeight: valueColor != null
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddEmployeeDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final departmentController = TextEditingController();
    final positionController = TextEditingController();
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    width: constraints.maxWidth * 0.9,
                    constraints: BoxConstraints(
                      maxWidth: 450,
                      maxHeight: MediaQuery.of(context).size.height * 0.9,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: const Color(0xFFE74C3C).withOpacity(0.3),
                          width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE74C3C),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(23),
                              topRight: Radius.circular(23),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.person_add_alt_1,
                                    color: Colors.white, size: 22),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Add New Employee',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            physics: const BouncingScrollPhysics(),
                            child: Form(
                              key: formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildFormField(
                                    controller: nameController,
                                    label: 'Full Name',
                                    icon: Icons.person_outline,
                                    validator: (v) =>
                                        v?.isEmpty ?? true ? 'Required' : null,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildFormField(
                                    controller: emailController,
                                    label: 'Email',
                                    icon: Icons.email_outlined,
                                    validator: (v) =>
                                        v?.isEmpty ?? true ? 'Required' : null,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildFormField(
                                    controller: passwordController,
                                    label: 'Password',
                                    icon: Icons.lock_outline,
                                    obscureText: true,
                                    validator: (v) => (v?.length ?? 0) < 6
                                        ? 'Min 6 characters'
                                        : null,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildFormField(
                                    controller: departmentController,
                                    label: 'Department',
                                    icon: Icons.business_outlined,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildFormField(
                                    controller: positionController,
                                    label: 'Position',
                                    icon: Icons.work_outline,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildFormField(
                                    controller: phoneController,
                                    label: 'Phone',
                                    icon: Icons.phone_outlined,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(24),
                              bottomRight: Radius.circular(24),
                            ),
                            border: Border(
                                top: BorderSide(color: Colors.grey.shade200)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: isLoading
                                      ? null
                                      : () async {
                                          if (formKey.currentState!
                                              .validate()) {
                                            setState(() => isLoading = true);
                                            try {
                                              final userCred = await _auth
                                                  .createUserWithEmailAndPassword(
                                                email:
                                                    emailController.text.trim(),
                                                password: passwordController
                                                    .text
                                                    .trim(),
                                              );
                                              await userCred.user
                                                  ?.updateDisplayName(
                                                      nameController.text
                                                          .trim());
                                              await _firestore
                                                  .collection('users')
                                                  .doc(userCred.user!.uid)
                                                  .set({
                                                'name':
                                                    nameController.text.trim(),
                                                'email':
                                                    emailController.text.trim(),
                                                'role': 'Team Member',
                                                'department':
                                                    departmentController.text
                                                        .trim(),
                                                'position': positionController
                                                    .text
                                                    .trim(),
                                                'phone':
                                                    phoneController.text.trim(),
                                                'joinDate': FieldValue
                                                    .serverTimestamp(),
                                                'isActive': true,
                                                'profileImageUrl': '',
                                              });
                                              if (context.mounted) {
                                                Navigator.pop(context);
                                                final adminProvider =
                                                    Provider.of<AdminProvider>(
                                                        context,
                                                        listen: false);
                                                await adminProvider
                                                    .fetchEmployees();
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: const Text(
                                                        'Employee added successfully'),
                                                    backgroundColor:
                                                        Colors.green.shade700,
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12)),
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                        'Error: ${e.toString()}'),
                                                    backgroundColor:
                                                        Colors.red.shade700,
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12)),
                                                  ),
                                                );
                                              }
                                            } finally {
                                              if (mounted)
                                                setState(
                                                    () => isLoading = false);
                                            }
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFE74C3C),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    elevation: 0,
                                  ),
                                  child: isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      : const Text('Add',
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          prefixIcon: Icon(icon, size: 18, color: const Color(0xFFE74C3C)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE74C3C), width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        ),
        validator: validator,
      ),
    );
  }

  void _showEditEmployeeDialog(
    BuildContext parentContext,
    EmployeeModel employee,
  ) {
    final nameController = TextEditingController(text: employee.name);
    final departmentController =
        TextEditingController(text: employee.department);
    final positionController = TextEditingController(text: employee.position);
    final phoneController = TextEditingController(text: employee.phone);
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    width: constraints.maxWidth * 0.9,
                    constraints: BoxConstraints(
                      maxWidth: 450,
                      maxHeight: MediaQuery.of(context).size.height * 0.9,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: const Color(0xFFE74C3C).withOpacity(0.3),
                          width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE74C3C),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(23),
                              topRight: Radius.circular(23),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.edit_note,
                                    color: Colors.white, size: 22),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Edit Employee',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            physics: const BouncingScrollPhysics(),
                            child: Form(
                              key: formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildFormField(
                                    controller: nameController,
                                    label: 'Full Name',
                                    icon: Icons.person_outline,
                                    validator: (v) =>
                                        v?.isEmpty ?? true ? 'Required' : null,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildFormField(
                                    controller: departmentController,
                                    label: 'Department',
                                    icon: Icons.business_outlined,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildFormField(
                                    controller: positionController,
                                    label: 'Position',
                                    icon: Icons.work_outline,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildFormField(
                                    controller: phoneController,
                                    label: 'Phone',
                                    icon: Icons.phone_outlined,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(24),
                              bottomRight: Radius.circular(24),
                            ),
                            border: Border(
                                top: BorderSide(color: Colors.grey.shade200)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: isLoading
                                      ? null
                                      : () async {
                                          if (formKey.currentState!
                                              .validate()) {
                                            setState(() => isLoading = true);

                                            try {
                                              await _firestore
                                                  .collection('users')
                                                  .doc(employee.id)
                                                  .update({
                                                'name':
                                                    nameController.text.trim(),
                                                'department':
                                                    departmentController.text
                                                        .trim(),
                                                'position': positionController
                                                    .text
                                                    .trim(),
                                                'phone':
                                                    phoneController.text.trim(),
                                              });

                                              await parentContext
                                                  .read<AdminProvider>()
                                                  .fetchEmployees();

                                              if (Navigator.canPop(context)) {
                                                Navigator.pop(context);
                                              }

                                              ScaffoldMessenger.of(
                                                      parentContext)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: const Text(
                                                      'Employee updated successfully'),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                            } catch (e) {
                                              ScaffoldMessenger.of(
                                                      parentContext)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text('Error: $e'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            } finally {
                                              if (mounted) {
                                                setState(
                                                    () => isLoading = false);
                                              }
                                            }
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFE74C3C),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    elevation: 0,
                                  ),
                                  child: isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      : const Text('Save',
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  void _toggleStatus(EmployeeModel employee) async {
    try {
      await _firestore.collection('users').doc(employee.id).update({
        'isActive': !employee.isActive,
      });
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      await adminProvider.fetchEmployees();
      if (context.mounted) {
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(
            content: Text(
                'Employee ${employee.isActive ? 'deactivated' : 'activated'} successfully'),
            backgroundColor: employee.isActive
                ? Colors.orange.shade700
                : Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _confirmDelete(BuildContext parentContext, EmployeeModel employee) {
    showDialog(
      context: parentContext,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                width: constraints.maxWidth * 0.9,
                constraints: BoxConstraints(
                  maxWidth: 400,
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(23),
                          topRight: Radius.circular(23),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.delete_forever,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Delete Employee',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Body
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 56,
                              color: Colors.orange.shade700,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Delete ${employee.name}?',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE74C3C),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'This action cannot be undone.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                try {
                                  await _firestore
                                      .collection('users')
                                      .doc(employee.id)
                                      .delete();

                                  if (dialogContext.mounted) {
                                    Navigator.pop(dialogContext);
                                  }

                                  await parentContext
                                      .read<AdminProvider>()
                                      .fetchEmployees();

                                  ScaffoldMessenger.of(parentContext)
                                      .showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                        'Employee deleted successfully',
                                      ),
                                      backgroundColor: Colors.green.shade700,
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(parentContext)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: Colors.red.shade700,
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Delete',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

extension EmployeeMapExtension on Map<String, dynamic> {
  bool get isActive {
    final value = this['isActive'];

    if (value is bool) return value;

    if (value is String) {
      return value.toLowerCase() == 'true';
    }

    if (value is int) {
      return value == 1;
    }

    return false;
  }

  String get phone {
    final value = this['phone'];
    return value == null ? '' : value.toString();
  }

  String get position {
    final value = this['position'];
    return value == null ? '' : value.toString();
  }

  String get name {
    final value = this['name'];
    return value == null ? '' : value.toString();
  }

  String get email {
    final value = this['email'];
    return value == null ? '' : value.toString();
  }

  String get department {
    final value = this['department'];
    return value == null ? '' : value.toString();
  }
}
