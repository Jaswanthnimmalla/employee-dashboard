import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../models/dashboard_model.dart';
import '../models/attendance_model.dart';
import '../models/leave_model.dart';
import '../models/request_model.dart';
import '../models/holiday_model.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Future<DashboardModel> getDashboardStats() async {
    final user = _auth.currentUser;
    if (user == null) {
      return DashboardModel(attendance: 0, leaves: 0, requests: 0);
    }

    final today = DateTime.now();
    final startOfMonth = DateTime(today.year, today.month, 1);
    final endOfMonth = DateTime(today.year, today.month + 1, 0);

    final attendanceQuery = await _firestore
        .collection('attendance')
        .where('userId', isEqualTo: user.uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .get();

    final leavesQuery = await _firestore
        .collection('leaves')
        .where('studentId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'approved')
        .get();

    final requestsQuery = await _firestore
        .collection('requests')
        .where('userId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'pending')
        .get();

    return DashboardModel(
      attendance: attendanceQuery.docs.length,
      leaves: leavesQuery.docs.length,
      requests: requestsQuery.docs.length,
    );
  }

  Stream<List<AttendanceModel>> getAttendanceStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('attendance')
        .where('userId', isEqualTo: user.uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AttendanceModel.fromFirestore(doc))
          .toList();
    });
  }

  @override
  Future<List<AttendanceModel>> getAttendanceList() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final query = await _firestore
        .collection('attendance')
        .where('userId', isEqualTo: user.uid)
        .orderBy('date', descending: true)
        .limit(50)
        .get();

    return query.docs.map((doc) => AttendanceModel.fromFirestore(doc)).toList();
  }

  @override
  Future<List<LeaveModel>> getLeaveList() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final query = await _firestore
        .collection('leaves')
        .where('studentId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .get();

    return query.docs.map((doc) {
      final data = doc.data();
      return LeaveModel(
        id: doc.id,
        type: data['leaveType'] ?? '',
        startDate: data['fromDate'] != null
            ? _formatDateFromTimestamp(data['fromDate'])
            : '',
        endDate: data['toDate'] != null
            ? _formatDateFromTimestamp(data['toDate'])
            : '',
        status: data['status'] ?? 'Pending',
        reason: data['reason'] ?? '',
      );
    }).toList();
  }

  Stream<List<LeaveModel>> getLeavesStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('leaves')
        .where('studentId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return LeaveModel(
          id: doc.id,
          type: data['leaveType'] ?? '',
          startDate: data['fromDate'] != null
              ? _formatDateFromTimestamp(data['fromDate'])
              : '',
          endDate: data['toDate'] != null
              ? _formatDateFromTimestamp(data['toDate'])
              : '',
          status: data['status'] ?? 'Pending',
          reason: data['reason'] ?? '',
        );
      }).toList();
    });
  }

  @override
  Future<List<RequestModel>> getRequestList() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final query = await _firestore
        .collection('requests')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .get();

    return query.docs.map((doc) {
      final data = doc.data();
      return RequestModel(
        id: doc.id,
        title: data['title'] ?? '',
        type: data['type'] ?? '',
        date: data['createdAt'] != null
            ? _formatDateFromTimestamp(data['createdAt'])
            : '',
        status: data['status'] ?? 'Pending',
        description: data['description'] ?? '',
      );
    }).toList();
  }

  Stream<List<RequestModel>> getRequestsStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('requests')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return RequestModel(
          id: doc.id,
          title: data['title'] ?? '',
          type: data['type'] ?? '',
          date: data['createdAt'] != null
              ? _formatDateFromTimestamp(data['createdAt'])
              : '',
          status: data['status'] ?? 'Pending',
          description: data['description'] ?? '',
        );
      }).toList();
    });
  }

  @override
  Future<List<HolidayModel>> getHolidayList() async {
    final query = await _firestore.collection('holidays').orderBy('date').get();

    return query.docs.map((doc) {
      final data = doc.data();
      return HolidayModel(
        name: data['name'] ?? '',
        date:
            data['date'] != null ? _formatDateFromTimestamp(data['date']) : '',
        day: _getDayOfWeek(data['date']),
        type: data['type'] ?? 'Holiday',
        description: data['description'],
      );
    }).toList();
  }

  Stream<List<HolidayModel>> getHolidaysStream() {
    return _firestore
        .collection('holidays')
        .orderBy('date')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return HolidayModel(
          name: data['name'] ?? '',
          date: data['date'] != null
              ? _formatDateFromTimestamp(data['date'])
              : '',
          day: _getDayOfWeek(data['date']),
          type: data['type'] ?? 'Holiday',
          description: data['description'],
        );
      }).toList();
    });
  }

  String _formatDateFromTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _getDayOfWeek(Timestamp? timestamp) {
    if (timestamp == null) return '';
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[timestamp.toDate().weekday - 1];
  }
}
