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
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
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
                  icon: const Icon(Icons.date_range),
                  label: const Text("Select Date"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                  ),
                ),
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
                    .collection('attendance')
                    .snapshots(),
                builder: (context, attendanceSnapshot) {
                  if (!attendanceSnapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final attendanceDocs = attendanceSnapshot.data!.docs;

                  int present = attendanceDocs.where((doc) {
                    final status = doc['status'].toString().toLowerCase();

                    return status == 'present';
                  }).length;

                  int absent = attendanceDocs.where((doc) {
                    final status = doc['status'].toString().toLowerCase();

                    return status == 'absent';
                  }).length;

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

                      int approved = leaveDocs.where((doc) {
                        return doc['status'].toString().toLowerCase() ==
                            'approved';
                      }).length;

                      int rejected = leaveDocs.where((doc) {
                        return doc['status'].toString().toLowerCase() ==
                            'rejected';
                      }).length;

                      int pending = leaveDocs.where((doc) {
                        return doc['status'].toString().toLowerCase() ==
                            'pending';
                      }).length;

                      return ListView(
                        children: [
                          _summaryCard(
                            present,
                            absent,
                            approved,
                            rejected,
                            pending,
                          ),
                          const SizedBox(height: 20),
                          _attendanceBarChart(
                            present,
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(
    int present,
    int absent,
    int approved,
    int rejected,
    int pending,
  ) {
    final total = present + absent;

    double attendanceRate = total > 0 ? (present / total) * 100 : 0;

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
                    width: 28,
                  ),
                ],
              ),
              BarChartGroupData(
                x: 1,
                barRods: [
                  BarChartRodData(
                    toY: absent.toDouble(),
                    color: Colors.red,
                    width: 28,
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
        child: LineChart(
          LineChartData(
            lineBarsData: [
              LineChartBarData(
                spots: const [
                  FlSpot(0, 5),
                  FlSpot(1, 8),
                  FlSpot(2, 6),
                  FlSpot(3, 10),
                  FlSpot(4, 7),
                ],
                isCurved: true,
                color: Colors.deepPurple,
                barWidth: 4,
              ),
            ],
          ),
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
