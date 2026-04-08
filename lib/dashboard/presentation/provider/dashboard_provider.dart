import 'package:flutter/material.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../data/models/dashboard_model.dart';
import '../../data/models/attendance_model.dart';
import '../../data/models/leave_model.dart';
import '../../data/models/request_model.dart';
import '../../data/models/holiday_model.dart';

class DashboardProvider extends ChangeNotifier {
  final DashboardRepository dashboardRepository;

  DashboardProvider({required this.dashboardRepository});

  DashboardModel? _dashboardStats;
  List<AttendanceModel> _attendanceList = [];
  List<LeaveModel> _leaveList = [];
  List<RequestModel> _requestList = [];
  List<HolidayModel> _holidayList = [];

  bool _isLoading = false;
  String? _error;

  DashboardModel? get dashboardStats => _dashboardStats;
  List<AttendanceModel> get attendanceList => _attendanceList;
  List<LeaveModel> get leaveList => _leaveList;
  List<RequestModel> get requestList => _requestList;
  List<HolidayModel> get holidayList => _holidayList;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadDashboardData() async {
    _setLoading(true);
    _error = null;

    try {
      await Future.wait([
        _loadStats(),
        _loadAttendance(),
        _loadLeaves(),
        _loadRequests(),
        _loadHolidays(),
      ]);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadStats() async {
    _dashboardStats = await dashboardRepository.getDashboardStats();
  }

  Future<void> _loadAttendance() async {
    _attendanceList = await dashboardRepository.getAttendanceList();
  }

  Future<void> _loadLeaves() async {
    _leaveList = await dashboardRepository.getLeaveList();
  }

  Future<void> _loadRequests() async {
    _requestList = await dashboardRepository.getRequestList();
  }

  Future<void> _loadHolidays() async {
    _holidayList = await dashboardRepository.getHolidayList();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void refresh() {
    loadDashboardData();
  }

  Future<void> markCheckOut(
      {required String attendanceId, required DateTime checkOutTime}) async {}

  Future<void> markCheckIn(
      {required userId,
      required userName,
      required userEmail,
      required DateTime checkInTime,
      required String status,
      required latitude,
      required longitude,
      required String locationAddress,
      String? photoUrl,
      required String deviceInfo,
      required String notes}) async {}
}
