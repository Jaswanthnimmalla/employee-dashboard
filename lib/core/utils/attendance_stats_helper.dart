import 'package:cloud_firestore/cloud_firestore.dart';
import 'attendance_time_logic.dart';

class AttendanceStats {
  int totalEmployees;
  int present;
  int late;
  int veryLate;
  int halfDay;
  int absent;

  AttendanceStats({
    required this.totalEmployees,
    required this.present,
    required this.late,
    required this.veryLate,
    required this.halfDay,
    required this.absent,
  });
}

class AttendanceStatsHelper {
  static Future<AttendanceStats> calculateTodayStats() async {
    final now = DateTime.now();

    final startOfDay = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final endOfDay = DateTime(
      now.year,
      now.month,
      now.day,
      23,
      59,
      59,
    );

    final usersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'Team Member')
        .get();

    final employees = usersSnapshot.docs;
    final attendanceSnapshot = await FirebaseFirestore.instance
        .collection('attendance')
        .where(
          'date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where(
          'date',
          isLessThanOrEqualTo: Timestamp.fromDate(endOfDay),
        )
        .get();

    final attendanceDocs = attendanceSnapshot.docs;
    final Map<String, String> employeeStatus = {};

    for (final emp in employees) {
      employeeStatus[emp.id] = 'Absent';
    }

    for (final doc in attendanceDocs) {
      final userId = doc.get('userId');

      if (!employeeStatus.containsKey(userId)) {
        continue;
      }

      final status = doc.get('status');

      employeeStatus[userId] = status;
    }

    int present = 0;
    int late = 0;
    int veryLate = 0;
    int halfDay = 0;
    int absent = 0;

    final cutoff = DateTime(
      now.year,
      now.month,
      now.day,
      11,
      40,
    );

    for (final status in employeeStatus.values) {
      switch (status) {
        case 'Present':
          present++;
          break;

        case 'Late':
          late++;
          break;

        case 'Very Late':
          veryLate++;
          break;

        case 'Half Day':
          halfDay++;
          break;

        case 'Absent':
          if (now.isAfter(cutoff)) {
            absent++;
          }
          break;
      }
    }

    return AttendanceStats(
      totalEmployees: employees.length,
      present: present,
      late: late,
      veryLate: veryLate,
      halfDay: halfDay,
      absent: absent,
    );
  }
}
