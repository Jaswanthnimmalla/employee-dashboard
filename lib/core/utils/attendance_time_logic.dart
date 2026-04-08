class AttendanceTimeLogic {
  static String getStatus(DateTime checkInTime) {
    final minutes = checkInTime.hour * 60 + checkInTime.minute;

    final presentLimit = 9 * 60 + 30;
    final lateLimit = 10 * 60 + 30;
    final veryLateLimit = 11 * 60 + 40;

    if (minutes <= presentLimit) {
      return 'Present';
    } else if (minutes <= lateLimit) {
      return 'Late';
    } else if (minutes <= veryLateLimit) {
      return 'Very Late';
    } else {
      return 'Half Day';
    }
  }

  static bool shouldMarkAbsent(
    DateTime now,
    bool hasCheckedIn,
  ) {
    final cutoff = DateTime(
      now.year,
      now.month,
      now.day,
      11,
      40,
    );

    return now.isAfter(cutoff) && !hasCheckedIn;
  }
}
