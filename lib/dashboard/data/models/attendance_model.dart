import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AttendanceModel {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final DateTime date;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final String status;
  final double totalHours;
  final double latitude;
  final double longitude;
  final String locationAddress;
  final String photoUrl;
  final String notes;
  final String workType;
  final int month;
  final int year;
  final Timestamp timestamp;

  AttendanceModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.date,
    required this.checkInTime,
    this.checkOutTime,
    required this.status,
    required this.totalHours,
    required this.latitude,
    required this.longitude,
    required this.locationAddress,
    required this.photoUrl,
    required this.notes,
    required this.workType,
    required this.month,
    required this.year,
    required this.timestamp,
  });

  factory AttendanceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AttendanceModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Employee',
      userEmail: data['userEmail'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      checkInTime:
          (data['checkInTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      checkOutTime: (data['checkOutTime'] as Timestamp?)?.toDate(),
      status: data['status'] ?? 'present',
      totalHours: (data['totalHours'] ?? 0.0).toDouble(),
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      locationAddress: data['locationAddress'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      notes: data['notes'] ?? '',
      workType: data['workType'] ?? 'Office',
      month: data['month'] ?? DateTime.now().month,
      year: data['year'] ?? DateTime.now().year,
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? 'Employee',
      userEmail: json['userEmail'] ?? '',
      date: json['date'] is DateTime
          ? json['date']
          : DateTime.parse(json['date'] ?? DateTime.now().toString()),
      checkInTime: json['checkInTime'] is DateTime
          ? json['checkInTime']
          : DateTime.parse(json['checkInTime'] ?? DateTime.now().toString()),
      checkOutTime: json['checkOutTime'] != null
          ? (json['checkOutTime'] is DateTime
              ? json['checkOutTime']
              : DateTime.parse(json['checkOutTime']))
          : null,
      status: json['status'] ?? 'present',
      totalHours: (json['totalHours'] ?? 0.0).toDouble(),
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      locationAddress: json['locationAddress'] ?? '',
      photoUrl: json['photoUrl'] ?? '',
      notes: json['notes'] ?? '',
      workType: json['workType'] ?? 'Office',
      month: json['month'] ?? DateTime.now().month,
      year: json['year'] ?? DateTime.now().year,
      timestamp: Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'date': Timestamp.fromDate(date),
      'checkInTime': Timestamp.fromDate(checkInTime),
      'checkOutTime':
          checkOutTime != null ? Timestamp.fromDate(checkOutTime!) : null,
      'status': status,
      'totalHours': totalHours,
      'latitude': latitude,
      'longitude': longitude,
      'locationAddress': locationAddress,
      'photoUrl': photoUrl,
      'notes': notes,
      'workType': workType,
      'month': month,
      'year': year,
      'timestamp': Timestamp.now(),
    };
  }

  String get formattedCheckIn {
    return '${checkInTime.hour.toString().padLeft(2, '0')}:${checkInTime.minute.toString().padLeft(2, '0')}';
  }

  String get formattedCheckOut {
    if (checkOutTime == null) return '--:--';
    return '${checkOutTime!.hour.toString().padLeft(2, '0')}:${checkOutTime!.minute.toString().padLeft(2, '0')}';
  }

  String get formattedDate {
    return '${date.day}/${date.month}/${date.year}';
  }

  String get statusText {
    switch (status.toLowerCase()) {
      case 'present':
        return 'Present';
      case 'late':
        return 'Late';
      case 'absent':
        return 'Absent';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'present':
        return Colors.green;
      case 'late':
        return Colors.orange;
      case 'absent':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}
