import '../../data/models/dashboard_model.dart';
import '../../data/models/attendance_model.dart';
import '../../data/models/leave_model.dart';
import '../../data/models/request_model.dart';
import '../../data/models/holiday_model.dart';

abstract class DashboardRepository {
  Future<DashboardModel> getDashboardStats();
  Future<List<AttendanceModel>> getAttendanceList();
  Future<List<LeaveModel>> getLeaveList();
  Future<List<RequestModel>> getRequestList();
  Future<List<HolidayModel>> getHolidayList();
}
