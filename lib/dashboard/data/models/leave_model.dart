class LeaveModel {
  final String id;
  final String type;
  final String startDate;
  final String endDate;
  final String status;
  final String reason;

  LeaveModel({
    required this.id,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.reason,
  });

  factory LeaveModel.fromJson(Map<String, dynamic> json) {
    return LeaveModel(
      id: json['id']?.toString() ?? '',
      type: json['type'] ?? 'Annual Leave',
      startDate: json['startDate'] ?? '2024-03-15',
      endDate: json['endDate'] ?? '2024-03-20',
      status: json['status'] ?? 'Pending',
      reason: json['reason'] ?? 'No reason provided',
    );
  }
}
