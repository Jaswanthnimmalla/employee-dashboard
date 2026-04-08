import 'package:cloud_firestore/cloud_firestore.dart';

class LeaveRequestModel {
  final String id;
  final String employeeId;
  final String employeeName;
  final String leaveType;
  final String reason;
  final DateTime fromDate;
  final DateTime toDate;
  final int daysCount;
  final String status;
  final String proofUrl;
  final DateTime timestamp;
  final DateTime? approvedAt;
  final String? approvedBy;

  LeaveRequestModel({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.leaveType,
    required this.reason,
    required this.fromDate,
    required this.toDate,
    required this.daysCount,
    required this.status,
    required this.proofUrl,
    required this.timestamp,
    this.approvedAt,
    this.approvedBy,
  });

  factory LeaveRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LeaveRequestModel(
      id: doc.id,
      employeeId: data['studentId'] ?? data['employeeId'] ?? '',
      employeeName: data['studentName'] ?? data['employeeName'] ?? '',
      leaveType: data['leaveType'] ?? '',
      reason: data['reason'] ?? '',
      fromDate: (data['fromDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      toDate: (data['toDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      daysCount: data['daysCount'] ?? 0,
      status: data['status'] ?? 'Pending',
      proofUrl: data['proofUrl'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
      approvedBy: data['approvedBy'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'employeeId': employeeId,
      'employeeName': employeeName,
      'leaveType': leaveType,
      'reason': reason,
      'fromDate': Timestamp.fromDate(fromDate),
      'toDate': Timestamp.fromDate(toDate),
      'daysCount': daysCount,
      'status': status,
      'proofUrl': proofUrl,
      'timestamp': Timestamp.fromDate(timestamp),
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'approvedBy': approvedBy,
    };
  }
}
