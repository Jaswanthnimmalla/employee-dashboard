import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceRecordModel {
  final String id;
  final String employeeId;
  final String employeeName;
  final DateTime date;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final String status;
  final double workHours;
  final String location;

  AttendanceRecordModel({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.date,
    required this.checkInTime,
    this.checkOutTime,
    required this.status,
    required this.workHours,
    required this.location,
  });

  factory AttendanceRecordModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AttendanceRecordModel(
      id: doc.id,
      employeeId: data['employeeId'] ?? '',
      employeeName: data['employeeName'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      checkInTime:
          (data['checkInTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      checkOutTime: (data['checkOutTime'] as Timestamp?)?.toDate(),
      status: data['status'] ?? 'present',
      workHours: (data['workHours'] ?? 0.0).toDouble(),
      location: data['location'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'employeeId': employeeId,
      'employeeName': employeeName,
      'date': Timestamp.fromDate(date),
      'checkInTime': Timestamp.fromDate(checkInTime),
      'checkOutTime':
          checkOutTime != null ? Timestamp.fromDate(checkOutTime!) : null,
      'status': status,
      'workHours': workHours,
      'location': location,
    };
  }
}
