import 'package:cloud_firestore/cloud_firestore.dart';

class EmployeeModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String department;
  final String position;
  final String phone;
  final DateTime joinDate;
  final bool isActive;
  final String profileImageUrl;

  EmployeeModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.department,
    required this.position,
    required this.phone,
    required this.joinDate,
    required this.isActive,
    required this.profileImageUrl,
  });

  factory EmployeeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return EmployeeModel(
      id: doc.id,
      name: (data['name'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      role: (data['role'] ?? 'user').toString(),
      department: (data['department'] ?? '').toString(),
      position: (data['position'] ?? '').toString(),
      phone: (data['phone'] ?? '').toString(),
      joinDate: data['joinDate'] is Timestamp
          ? (data['joinDate'] as Timestamp).toDate()
          : DateTime.now(),
      isActive: data['isActive'] is bool
          ? data['isActive']
          : data['isActive'].toString() == 'true',
      profileImageUrl: (data['profileImageUrl'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'department': department,
      'position': position,
      'phone': phone,
      'joinDate': Timestamp.fromDate(joinDate),
      'isActive': isActive,
      'profileImageUrl': profileImageUrl,
    };
  }
}
