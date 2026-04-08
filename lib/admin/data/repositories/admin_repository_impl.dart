import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:employee_dashboard_app/admin/data/domain/repositories/admin_repository.dart';
import 'package:employee_dashboard_app/admin/data/models/admin_stats_model.dart';
import 'package:employee_dashboard_app/admin/data/models/attendance_record_model.dart';
import 'package:employee_dashboard_app/admin/data/models/employee_model.dart';
import 'package:employee_dashboard_app/admin/data/models/leave_request_model.dart';
import 'package:rxdart/rxdart.dart';

class AdminRepositoryImpl implements AdminRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Stream<List<EmployeeModel>> getAllEmployees() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => EmployeeModel.fromFirestore(doc))
          .toList();
    });
  }

  Stream<List<LeaveRequestModel>> getAllLeaveRequests() {
    return _firestore
        .collection('leaves')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => LeaveRequestModel.fromFirestore(doc))
          .toList();
    });
  }

  Stream<List<AttendanceRecordModel>> getAllAttendanceRecords() {
    return _firestore
        .collection('attendance')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AttendanceRecordModel.fromFirestore(doc))
          .toList();
    });
  }

  Future<void> updateLeaveStatus(
    String leaveId,
    String status,
    String adminId,
  ) async {
    await _firestore.collection('leaves').doc(leaveId).update({
      'status': status,
      'approvedAt': FieldValue.serverTimestamp(),
      'approvedBy': adminId,
    });
  }

  Future<void> deleteLeaveRequest(String leaveId) async {
    await _firestore.collection('leaves').doc(leaveId).delete();
  }

  Future<void> updateEmployeeStatus(
    String employeeId,
    bool isActive,
  ) async {
    await _firestore.collection('users').doc(employeeId).update({
      'isActive': isActive,
    });
  }

  Future<void> deleteEmployee(String employeeId) async {
    await _firestore.collection('users').doc(employeeId).delete();
  }

  Stream<AdminStatsModel> getAdminStats() {
    return Rx.combineLatest4<QuerySnapshot, QuerySnapshot, QuerySnapshot,
        QuerySnapshot, AdminStatsModel>(
      _firestore
          .collection('users')
          .where('role', isEqualTo: 'user')
          .snapshots(),
      _firestore
          .collection('attendance')
          .where('date', isEqualTo: _getToday())
          .snapshots(),
      _firestore
          .collection('leaves')
          .where('status', isEqualTo: 'Pending')
          .snapshots(),
      _firestore
          .collection('leaves')
          .where('status', isEqualTo: 'Approved')
          .snapshots(),
      (
        employees,
        todayAttendance,
        pendingLeaves,
        approvedLeaves,
      ) {
        return AdminStatsModel(
          totalEmployees: employees.docs.length,
          presentToday: todayAttendance.docs.length,
          onLeave: 0,
          pendingRequests: pendingLeaves.docs.length,
          attendanceRate: employees.docs.isNotEmpty
              ? (todayAttendance.docs.length / employees.docs.length) * 100
              : 0,
          totalLeavesThisMonth: approvedLeaves.docs.length,
        );
      },
    );
  }

  Timestamp _getToday() {
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    return Timestamp.fromDate(today);
  }

  Future<Map<String, dynamic>> getAttendanceReport(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final snapshot = await _firestore
        .collection('attendance')
        .where(
          'date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        )
        .where(
          'date',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate),
        )
        .get();

    final totalDays = endDate.difference(startDate).inDays + 1;

    final presentCount = snapshot.docs.length;

    final attendancePercentage =
        totalDays > 0 ? (presentCount / totalDays) * 100 : 0;

    return {
      'totalDays': totalDays,
      'presentDays': presentCount,
      'absentDays': totalDays - presentCount,
      'attendancePercentage': attendancePercentage,
    };
  }

  Future<Map<String, dynamic>> getLeaveReport(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final snapshot = await _firestore
        .collection('leaves')
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        )
        .where(
          'timestamp',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate),
        )
        .get();

    final approved =
        snapshot.docs.where((doc) => doc['status'] == 'Approved').length;

    final rejected =
        snapshot.docs.where((doc) => doc['status'] == 'Rejected').length;

    final pending =
        snapshot.docs.where((doc) => doc['status'] == 'Pending').length;

    return {
      'totalRequests': snapshot.docs.length,
      'approved': approved,
      'rejected': rejected,
      'pending': pending,
    };
  }
}
