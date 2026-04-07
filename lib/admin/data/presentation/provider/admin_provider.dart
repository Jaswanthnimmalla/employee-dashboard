// lib/admin/data/presentation/provider/admin_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminProvider extends ChangeNotifier {
  AdminProvider() {
    fixExistingUsers();
    startListening();
  }

  Future<void> fixExistingUsers() async {
    final users = await FirebaseFirestore.instance.collection('users').get();

    for (var doc in users.docs) {
      await doc.reference.set({
        'department': doc.data()['department'] ?? '',
        'position': doc.data()['position'] ?? '',
        'phone': doc.data()['phone'] ?? '',
        'profileImageUrl': doc.data()['profileImageUrl'] ?? '',
        'isActive': doc.data()['isActive'] ?? true,
        'joinDate': doc.data()['joinDate'] ?? FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  // ================= DATA =================

  int _totalEmployees = 0;
  int _presentToday = 0;
  int _onLeaveToday = 0;
  int _pendingLeaves = 0;
  double _attendanceRate = 0.0;

  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _attendanceRecords = [];
  List<Map<String, dynamic>> _leaveRequests = [];

  final List<StreamSubscription> _subscriptions = [];

  // ================= GETTERS =================

  int get totalEmployees => _totalEmployees;
  int get presentToday => _presentToday;
  int get onLeaveToday => _onLeaveToday;
  int get pendingLeaves => _pendingLeaves;
  double get attendanceRate => _attendanceRate;
  List<Map<String, dynamic>> get employees => _employees;
  List<Map<String, dynamic>> get attendanceRecords => _attendanceRecords;
  List<Map<String, dynamic>> get leaveRequests => _leaveRequests;

  // ================= START REAL-TIME =================

  void startListening() {
    if (_subscriptions.isNotEmpty) return;

    print("AdminProvider: Starting real-time listeners...");

    // ================= 1. EMPLOYEES (USERS with role='user') =================
    _subscriptions.add(
      FirebaseFirestore.instance.collection('users').snapshots().listen(
          (snapshot) async {
        final adminSnapshot =
            await FirebaseFirestore.instance.collection('Admin').get();

        final userList = snapshot.docs.map((doc) {
          final data = doc.data();

          return {
            'id': doc.id,
            'name': data['name'] ?? '',
            'email': data['email'] ?? '',
            'role': data['role'] ?? '',
            'department': data['department'] ?? '',
            'position': data['position'] ?? '',
            'phone': data['phone'] ?? '',
            'joinDate': data['joinDate'],
            'isActive': data['isActive'] is bool
                ? data['isActive']
                : data['isActive'].toString() == 'true',
            'profileImageUrl':
                (data['profileImageUrl'] ?? '').toString().trim(),
          };
        }).toList();

        final adminList = adminSnapshot.docs.map((doc) {
          final data = doc.data();

          return {
            'id': doc.id,
            'name': data['name'] ?? '',
            'email': data['email'] ?? '',
            'role': 'admin',
            'department': data['department'] ?? '',
            'position': data['position'] ?? '',
            'phone': data['phone'] ?? '',
            'joinDate': data['joinDate'],
            'isActive': true,
            'profileImageUrl':
                (data['profileImageUrl'] ?? '').toString().trim(),
          };
        }).toList();

        _employees = [
          ...userList,
          ...adminList,
        ];

        _totalEmployees = _employees.length;

        _updateAttendanceRate();
        notifyListeners();

        print("✅ Employees + Admins loaded: $_totalEmployees");
      }, onError: (error) {
        print("❌ Error fetching employees: $error");
      }),
    );

    // ================= 2. TODAY'S ATTENDANCE (Matches Cloudinary upload) =================
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    _subscriptions.add(
      FirebaseFirestore.instance
          .collection('attendance')
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where(
            'date',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfDay),
          )
          .snapshots()
          .listen((snapshot) {
        _attendanceRecords = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();

        // Count present today
        _presentToday = _attendanceRecords
            .where((record) =>
                record['status'].toString().toLowerCase() == 'present')
            .length;

        // Count on leave today (status = 'leave' or 'absent')
        _onLeaveToday = _attendanceRecords.where((record) {
          final status = record['status'].toString().toLowerCase();
          return status == 'leave' || status == 'absent';
        }).length;

        _updateAttendanceRate();
        notifyListeners();

        print(
            "✅ Attendance updated for ${startOfDay.toString().split(' ')[0]}");
        print("   📊 Present: $_presentToday");
        print("   📊 On Leave: $_onLeaveToday");
        print("   📊 Total records: ${_attendanceRecords.length}");

        // Debug: Show first record if exists
        if (_attendanceRecords.isNotEmpty) {
          print("   Sample: ${_attendanceRecords.first}");
        }
      }, onError: (error) {
        print("❌ Error fetching attendance: $error");
      }),
    );

    // ================= 3. PENDING LEAVES (Matches Cloudinary leave upload) =================
    _subscriptions.add(
      FirebaseFirestore.instance
          .collection('leaves')
          .where('status', isEqualTo: 'pending')
          .snapshots()
          .listen((snapshot) {
        _leaveRequests = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();

        _pendingLeaves = _leaveRequests.length;
        notifyListeners();

        print("✅ Pending leaves updated: $_pendingLeaves");

        if (_leaveRequests.isNotEmpty) {
          print("   First pending: ${_leaveRequests.first['reason']}");
        }
      }, onError: (error) {
        print("❌ Error fetching leaves: $error");
      }),
    );

    // ================= 4. ALL TIME ATTENDANCE STATS (Optional) =================
    _subscriptions.add(
      FirebaseFirestore.instance.collection('attendance').snapshots().listen(
          (snapshot) {
        print("📊 Total attendance records in DB: ${snapshot.docs.length}");

        // Optional: Calculate weekly/monthly stats here
        Map<String, int> monthlyStats = {};
        for (var doc in snapshot.docs) {
          final date = doc['date'] as Timestamp?;
          if (date != null) {
            final month = "${date.toDate().year}-${date.toDate().month}";
            monthlyStats[month] = (monthlyStats[month] ?? 0) + 1;
          }
        }

        print("   Monthly breakdown: $monthlyStats");
      }, onError: (error) {
        print("❌ Error fetching all attendance: $error");
      }),
    );
  }

  // ================= SEARCH EMPLOYEES =================
  List<Map<String, dynamic>> getFilteredEmployees(String searchText) {
    if (searchText.isEmpty) {
      return _employees;
    }

    return _employees.where((employee) {
      final name = employee['name'].toString().toLowerCase();
      final email = employee['email'].toString().toLowerCase();
      final id = employee['id'].toString().toLowerCase();

      return name.contains(searchText.toLowerCase()) ||
          email.contains(searchText.toLowerCase()) ||
          id.contains(searchText.toLowerCase());
    }).toList();
  }

  // ================= GET ATTENDANCE FOR SPECIFIC DATE =================
  List<Map<String, dynamic>> getAttendanceForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return _attendanceRecords.where((record) {
      final recordDate = record['date'] as Timestamp?;
      if (recordDate == null) return false;

      return recordDate.toDate().isAfter(startOfDay) &&
          recordDate.toDate().isBefore(endOfDay);
    }).toList();
  }

  // ================= GET LEAVES BY USER =================
  List<Map<String, dynamic>> getLeavesByUser(String userId) {
    return _leaveRequests.where((leave) {
      return leave['userId'] == userId;
    }).toList();
  }

  // ================= UPDATE ATTENDANCE RATE =================
  void _updateAttendanceRate() {
    if (_totalEmployees > 0) {
      _attendanceRate = (_presentToday / _totalEmployees) * 100;
    } else {
      _attendanceRate = 0.0;
    }
  }

  // ================= MANUAL REFRESH =================
  Future<void> refresh() async {
    print("AdminProvider: Manual refresh...");
    // Cancel and restart listeners
    for (var sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();
    startListening();
    notifyListeners();
  }

  // ================= GET EMPLOYEE DETAILS BY ID =================
  Map<String, dynamic>? getEmployeeById(String userId) {
    try {
      return _employees.firstWhere((emp) => emp['id'] == userId);
    } catch (e) {
      print("Employee not found: $userId");
      return null;
    }
  }

  // ================= GET TODAY'S ATTENDANCE WITH EMPLOYEE NAMES =================
  List<Map<String, dynamic>> getTodaysAttendanceWithNames() {
    List<Map<String, dynamic>> result = [];

    for (var attendance in _attendanceRecords) {
      final employee = getEmployeeById(attendance['userId'] ?? '');
      result.add({
        'attendance': attendance,
        'employee': employee,
        'employeeName': employee?['name'] ?? 'Unknown',
        'employeeEmail': employee?['email'] ?? 'Unknown',
        'status': attendance['status'],
        'time': attendance['timestamp'] != null
            ? (attendance['timestamp'] as Timestamp).toDate()
            : null,
        'selfieUrl': attendance['selfieUrl'],
      });
    }

    return result;
  }

  // ================= GET PENDING LEAVES WITH EMPLOYEE NAMES =================
  List<Map<String, dynamic>> getPendingLeavesWithNames() {
    List<Map<String, dynamic>> result = [];

    for (var leave in _leaveRequests) {
      final employee = getEmployeeById(leave['userId'] ?? '');
      result.add({
        'leave': leave,
        'employee': employee,
        'employeeName': employee?['name'] ?? 'Unknown',
        'employeeEmail': employee?['email'] ?? 'Unknown',
        'reason': leave['reason'],
        'proofUrl': leave['proofUrl'],
        'startDate': leave['startDate'] != null
            ? (leave['startDate'] as Timestamp).toDate()
            : null,
        'endDate': leave['endDate'] != null
            ? (leave['endDate'] as Timestamp).toDate()
            : null,
        'submittedAt': leave['submittedAt'] != null
            ? (leave['submittedAt'] as Timestamp).toDate()
            : null,
      });
    }

    return result;
  }

  // ================= DISPOSE =================
  @override
  void dispose() {
    print("AdminProvider: Disposing listeners...");
    for (var sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    super.dispose();
  }

  Future<void> fetchEmployees() async {}
}
