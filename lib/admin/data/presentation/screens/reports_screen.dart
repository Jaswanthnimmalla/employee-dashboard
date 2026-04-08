import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  Timer? _refreshTimer;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));

  DateTime _endDate = DateTime.now();

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _startDate,
        end: _endDate,
      ),
    );

    if (picked != null) {
      setState(() {
        _startDate = DateTime(
          picked.start.year,
          picked.start.month,
          picked.start.day,
        );

        _endDate = DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
          23,
          59,
          59,
        );
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _refreshTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          "Reports & Analytics",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF6A1B9A).withOpacity(0.95),
                const Color(0xFF8E24AA).withOpacity(0.95),
                const Color(0xFFAB47BC).withOpacity(0.95),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.3),
                  Colors.white.withOpacity(0.1),
                ],
              ),
            ),
            height: 2,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(isSmall ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Analytics Dashboard",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _selectDateRange,
                  icon: const Icon(
                    Icons.date_range,
                    color: Colors.white,
                    size: 20,
                  ),
                  label: const Text(
                    "Select Date",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                "${DateFormat('dd MMM yyyy').format(_startDate)}  -  ${DateFormat('dd MMM yyyy').format(_endDate)}",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('isActive', isEqualTo: true)
                    .snapshots(),
                builder: (context, usersSnapshot) {
                  if (!usersSnapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final int totalEmployees = usersSnapshot.data!.docs.length;
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('attendance')
                        .where(
                          'checkInTime',
                          isGreaterThanOrEqualTo:
                              Timestamp.fromDate(_startDate),
                        )
                        .where(
                          'checkInTime',
                          isLessThanOrEqualTo: Timestamp.fromDate(_endDate),
                        )
                        .snapshots(),
                    builder: (context, attendanceSnapshot) {
                      if (!attendanceSnapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final attendanceDocs = attendanceSnapshot.data!.docs;

                      final Map<String, String> employeeStatus = {};

                      for (var doc in attendanceDocs) {
                        final userId = doc['userId']?.toString() ?? '';

                        if (userId.isEmpty) continue;

                        if (doc['checkInTime'] != null) {
                          final checkIn =
                              (doc['checkInTime'] as Timestamp).toDate();

                          final minutes = checkIn.hour * 60 + checkIn.minute;

                          if (minutes <= 9 * 60 + 40) {
                            employeeStatus[userId] = 'Present';
                          } else if (minutes <= 10 * 60 + 44) {
                            employeeStatus[userId] = 'Late';
                          } else if (minutes <= 11 * 60 + 39) {
                            employeeStatus[userId] = 'Very Late';
                          } else {
                            employeeStatus[userId] = 'Half Day';
                          }
                        } else {
                          employeeStatus[userId] = 'Absent';
                        }
                      }

                      int present = 0;
                      int late = 0;
                      int veryLate = 0;
                      int halfDay = 0;
                      int absent = 0;

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
                            absent++;
                            break;
                        }
                      }

                      final int notMarked =
                          totalEmployees - employeeStatus.length;

                      if (notMarked > 0) {
                        absent += notMarked;
                      }

                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('leaves')
                            .snapshots(),
                        builder: (context, leaveSnapshot) {
                          if (!leaveSnapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final leaveDocs = leaveSnapshot.data!.docs;

                          int approved = leaveDocs
                              .where(
                                (doc) =>
                                    doc['status'].toString().toLowerCase() ==
                                    'approved',
                              )
                              .length;

                          int rejected = leaveDocs
                              .where(
                                (doc) =>
                                    doc['status'].toString().toLowerCase() ==
                                    'rejected',
                              )
                              .length;

                          int pending = leaveDocs
                              .where(
                                (doc) =>
                                    doc['status'].toString().toLowerCase() ==
                                    'pending',
                              )
                              .length;

                          return ListView(
                            children: [
                              _summaryCard(
                                totalEmployees,
                                present,
                                late,
                                veryLate,
                                halfDay,
                                absent,
                                approved,
                                rejected,
                                pending,
                              ),
                              const SizedBox(height: 20),
                              _attendanceBarChart(
                                present,
                                late,
                                veryLate,
                                halfDay,
                                absent,
                              ),
                              const SizedBox(height: 20),
                              _leavePieChart(
                                approved,
                                rejected,
                                pending,
                              ),
                              const SizedBox(height: 20),
                              _trendLineChart(),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(
    int totalEmployees,
    int present,
    int late,
    int veryLate,
    int halfDay,
    int absent,
    int approved,
    int rejected,
    int pending,
  ) {
    final attendedCount = present + late + veryLate + halfDay;

    double attendanceRate =
        totalEmployees > 0 ? (attendedCount / totalEmployees) * 100 : 0.0;

    final totalLeaves = approved + rejected + pending;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Colors.deepPurple,
            Colors.purple,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  "${attendanceRate.toStringAsFixed(1)}%",
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Attendance Rate",
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: Colors.white24,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  totalLeaves.toString(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Total Leaves",
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _attendanceBarChart(
    int present,
    int late,
    int veryLate,
    int halfDay,
    int absent,
  ) {
    return _chartContainer(
      "Attendance Overview",
      Icons.bar_chart,
      Colors.blue,
      SizedBox(
        height: 220,
        child: BarChart(
          BarChartData(
            barGroups: [
              BarChartGroupData(
                x: 0,
                barRods: [
                  BarChartRodData(
                    toY: present.toDouble(),
                    color: Colors.green,
                    width: 20,
                  ),
                ],
              ),
              BarChartGroupData(
                x: 1,
                barRods: [
                  BarChartRodData(
                    toY: late.toDouble(),
                    color: Colors.orange,
                    width: 20,
                  ),
                ],
              ),
              BarChartGroupData(
                x: 2,
                barRods: [
                  BarChartRodData(
                    toY: veryLate.toDouble(),
                    color: Colors.deepOrange,
                    width: 20,
                  ),
                ],
              ),
              BarChartGroupData(
                x: 3,
                barRods: [
                  BarChartRodData(
                    toY: halfDay.toDouble(),
                    color: Colors.purple,
                    width: 20,
                  ),
                ],
              ),
              BarChartGroupData(
                x: 4,
                barRods: [
                  BarChartRodData(
                    toY: absent.toDouble(),
                    color: Colors.red,
                    width: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _leavePieChart(
    int approved,
    int rejected,
    int pending,
  ) {
    return _chartContainer(
      "Leave Status",
      Icons.pie_chart,
      Colors.orange,
      SizedBox(
        height: 220,
        child: PieChart(
          PieChartData(
            sections: [
              PieChartSectionData(
                value: approved.toDouble(),
                color: Colors.green,
                title: "Approved",
              ),
              PieChartSectionData(
                value: rejected.toDouble(),
                color: Colors.red,
                title: "Rejected",
              ),
              PieChartSectionData(
                value: pending.toDouble(),
                color: Colors.orange,
                title: "Pending",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _trendLineChart() {
    return _chartContainer(
      "Attendance Trend",
      Icons.show_chart,
      Colors.deepPurple,
      SizedBox(
        height: 220,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('attendance')
              .where(
                'checkInTime',
                isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate),
              )
              .where(
                'checkInTime',
                isLessThanOrEqualTo: Timestamp.fromDate(_endDate),
              )
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final docs = snapshot.data!.docs;

            final Map<DateTime, int> dailyCounts = {};

            for (var doc in docs) {
              if (doc['checkInTime'] != null) {
                final checkIn = (doc['checkInTime'] as Timestamp).toDate();

                if (checkIn.isBefore(_startDate) || checkIn.isAfter(_endDate)) {
                  continue;
                }

                final day = DateTime(
                  checkIn.year,
                  checkIn.month,
                  checkIn.day,
                );

                dailyCounts[day] = (dailyCounts[day] ?? 0) + 1;
              }
            }

            if (dailyCounts.isEmpty) {
              return const Center(
                child: Text(
                  "No attendance data",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }

            final sortedDates = dailyCounts.keys.toList()..sort();

            final spots = <FlSpot>[];

            for (int i = 0; i < sortedDates.length; i++) {
              final date = sortedDates[i];

              spots.add(
                FlSpot(
                  i.toDouble(),
                  dailyCounts[date]!.toDouble(),
                ),
              );
            }

            return LineChart(
              LineChartData(
                minY: 0,
                maxY: spots.isNotEmpty
                    ? spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 1
                    : 1,
                gridData: FlGridData(
                  show: true,
                  drawHorizontalLine: true,
                  drawVerticalLine: false,
                ),
                borderData: FlBorderData(
                  show: false,
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < sortedDates.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              DateFormat('dd MMM')
                                  .format(sortedDates[value.toInt()]),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.deepPurple,
                    barWidth: 5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(
                      show: true,
                    ),
                    belowBarData: BarAreaData(
                      show: false,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _chartContainer(
    String title,
    IconData icon,
    Color color,
    Widget chart,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          chart,
        ],
      ),
    );
  }
}
