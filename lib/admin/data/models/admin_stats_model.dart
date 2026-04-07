// lib/features/admin/data/models/admin_stats_model.dart
class AdminStatsModel {
  final int totalEmployees;
  final int presentToday;
  final int onLeave;
  final int pendingRequests;
  final double attendanceRate;
  final int totalLeavesThisMonth;

  AdminStatsModel({
    required this.totalEmployees,
    required this.presentToday,
    required this.onLeave,
    required this.pendingRequests,
    required this.attendanceRate,
    required this.totalLeavesThisMonth,
  });

  factory AdminStatsModel.fromMap(Map<String, dynamic> map) {
    return AdminStatsModel(
      totalEmployees: map['totalEmployees'] ?? 0,
      presentToday: map['presentToday'] ?? 0,
      onLeave: map['onLeave'] ?? 0,
      pendingRequests: map['pendingRequests'] ?? 0,
      attendanceRate: (map['attendanceRate'] ?? 0.0).toDouble(),
      totalLeavesThisMonth: map['totalLeavesThisMonth'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalEmployees': totalEmployees,
      'presentToday': presentToday,
      'onLeave': onLeave,
      'pendingRequests': pendingRequests,
      'attendanceRate': attendanceRate,
      'totalLeavesThisMonth': totalLeavesThisMonth,
    };
  }
}
