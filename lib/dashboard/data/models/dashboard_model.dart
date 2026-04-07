class DashboardModel {
  final int attendance;
  final int leaves;
  final int requests;

  DashboardModel({
    required this.attendance,
    required this.leaves,
    required this.requests,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return DashboardModel(
      attendance: json['attendance'] ?? 85,
      leaves: json['leaves'] ?? 12,
      requests: json['requests'] ?? 5,
    );
  }
}
