// lib/features/admin/presentation/widgets/attendance_chart.dart
import 'package:employee_dashboard_app/admin/data/models/attendance_record_model.dart';
import 'package:flutter/material.dart';

class AttendanceChart extends StatelessWidget {
  final List<AttendanceRecordModel> records;
  final int totalDays;

  const AttendanceChart({
    super.key,
    required this.records,
    required this.totalDays,
  });

  int get _presentCount => records.length;
  int get _absentCount => totalDays - _presentCount;
  double get _presentPercentage =>
      totalDays > 0 ? (_presentCount / totalDays) * 100 : 0;
  double get _absentPercentage =>
      totalDays > 0 ? (_absentCount / totalDays) * 100 : 0;

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.all(isSmall ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Attendance Overview',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                'Total Days: $totalDays',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: _presentCount,
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius:
                        const BorderRadius.horizontal(left: Radius.circular(8)),
                  ),
                  child: Center(
                    child: Text(
                      '${_presentPercentage.toStringAsFixed(1)}%',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: _absentCount,
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(8)),
                  ),
                  child: Center(
                    child: Text(
                      '${_absentPercentage.toStringAsFixed(1)}%',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend('Present', Colors.green, _presentCount),
              const SizedBox(width: 24),
              _buildLegend('Absent', Colors.red, _absentCount),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, Color color, int count) {
    return Row(
      children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('$label: $count', style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
