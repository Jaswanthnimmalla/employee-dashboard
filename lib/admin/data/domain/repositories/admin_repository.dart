import 'package:employee_dashboard_app/admin/data/models/admin_stats_model.dart';
import 'package:employee_dashboard_app/admin/data/models/attendance_record_model.dart';
import 'package:employee_dashboard_app/admin/data/models/employee_model.dart';
import 'package:employee_dashboard_app/admin/data/models/leave_request_model.dart';

abstract class AdminRepository {
  Stream<List<EmployeeModel>> getAllEmployees();
  Stream<List<LeaveRequestModel>> getAllLeaveRequests();
  Stream<List<AttendanceRecordModel>> getAllAttendanceRecords();
  Future<void> updateLeaveStatus(String leaveId, String status, String adminId);
  Future<void> deleteLeaveRequest(String leaveId);
  Future<void> updateEmployeeStatus(String employeeId, bool isActive);
  Future<void> deleteEmployee(String employeeId);
  Stream<AdminStatsModel> getAdminStats();
  Future<Map<String, dynamic>> getAttendanceReport(
      DateTime startDate, DateTime endDate);
  Future<Map<String, dynamic>> getLeaveReport(
      DateTime startDate, DateTime endDate);
}
