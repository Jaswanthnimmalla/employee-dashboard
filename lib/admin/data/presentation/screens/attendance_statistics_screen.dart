import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class AttendanceStatisticsScreen extends StatefulWidget {
  const AttendanceStatisticsScreen({super.key});

  @override
  State<AttendanceStatisticsScreen> createState() =>
      _AttendanceStatisticsScreenState();
}

class _AttendanceStatisticsScreenState
    extends State<AttendanceStatisticsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _selectedPeriod = 'Last 30 Days';

  final List<Map<String, dynamic>> _periodOptions = [
    {'label': 'Today', 'days': 0},
    {'label': 'Last 7 Days', 'days': 7},
    {'label': 'Last 30 Days', 'days': 30},
    {'label': 'Last 90 Days', 'days': 90},
    {'label': 'This Year', 'days': 365},
    {'label': 'Custom', 'days': -1},
  ];

  Future<List<String>> _getAllEmployeeIds() async {
    final snapshot = await _firestore
        .collection('users')
        .get(); // Remove the where clause entirely
    print('Found ${snapshot.docs.length} employees'); // Debug print
    return snapshot.docs.map((doc) => doc.id).toList();
  }

  Map<String, dynamic> _calculateStatisticsWithEmployees(
      List<QueryDocumentSnapshot> records, List<String> allEmployeeIds) {
    final totalEmployees = allEmployeeIds.length;

    final Map<String, String> employeeBestStatus = {};
    for (final employeeId in allEmployeeIds) {
      employeeBestStatus[employeeId] = 'Absent';
    }

    for (final record in records) {
      final userId = record['userId']?.toString() ?? '';
      final status = record['status']?.toString() ?? 'Absent';

      if (userId.isEmpty || !employeeBestStatus.containsKey(userId)) continue;

      if (status == 'Present') {
        employeeBestStatus[userId] = 'Present';
      } else if (status == 'Half Day' &&
          employeeBestStatus[userId] != 'Present') {
        employeeBestStatus[userId] = 'Half Day';
      } else if (status == 'Late' &&
          employeeBestStatus[userId] != 'Present' &&
          employeeBestStatus[userId] != 'Half Day') {
        employeeBestStatus[userId] = 'Late';
      }
    }

    int present = 0;
    int late = 0;
    int absent = 0;
    int halfDay = 0;

    for (final status in employeeBestStatus.values) {
      switch (status) {
        case 'Present':
          present++;
          break;
        case 'Late':
          late++;
          break;
        case 'Half Day':
          halfDay++;
          break;
        case 'Absent':
          absent++;
          break;
      }
    }

    final attendanceRate =
        totalEmployees > 0 ? (present / totalEmployees) * 100 : 0.0;

    double totalOvertime = 0;
    double totalEarlyLeave = 0;

    for (var record in records) {
      final hours = (record['totalHours'] ?? 0.0).toDouble();
      if (hours > 8) totalOvertime += (hours - 8);
      if (record['status'] == 'Present' && hours < 8 && hours > 0) {
        totalEarlyLeave += (8 - hours);
      }
    }

    return {
      'totalRecords': records.length,
      'present': present,
      'late': late,
      'absent': absent,
      'halfDay': halfDay,
      'totalEmployees': totalEmployees,
      'attendanceRate': attendanceRate,
      'totalOvertime': totalOvertime,
      'totalEarlyLeave': totalEarlyLeave,
    };
  }

  Stream<QuerySnapshot> _buildAttendanceStream() {
    final startOfDay =
        DateTime(_startDate.year, _startDate.month, _startDate.day);
    final endOfDay =
        DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);

    return _firestore
        .collection('attendance')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('date', descending: false)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Attendance Statistics',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey.shade800,
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: _buildPeriodDropdown(),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.calendar_today, size: 20),
              onPressed: _showCustomDateRangePicker,
              tooltip: 'Custom Date Range',
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<String>>(
        future: _getAllEmployeeIds(),
        builder: (context, employeesSnapshot) {
          if (employeesSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (employeesSnapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('Error loading employees',
                      style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            );
          }

          final allEmployeeIds = employeesSnapshot.data ?? [];

          if (allEmployeeIds.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('No employees found',
                      style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            );
          }

          return StreamBuilder<QuerySnapshot>(
            key: ValueKey(
                '${_startDate.toIso8601String()}_${_endDate.toIso8601String()}'),
            stream: _buildAttendanceStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('Error loading statistics',
                          style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final records = snapshot.hasData
                  ? snapshot.data!.docs
                  : <QueryDocumentSnapshot>[];
              final stats =
                  _calculateStatisticsWithEmployees(records, allEmployeeIds);

              return SingleChildScrollView(
                padding: EdgeInsets.all(isSmall ? 12 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDateRangeIndicator(),
                    const SizedBox(height: 16),
                    _buildKeyMetricsCards(stats, isSmall),
                    const SizedBox(height: 20),
                    if (records.isNotEmpty) ...[
                      _buildStatusDistributionChart(records, stats, isSmall),
                      const SizedBox(height: 20),
                      _buildDailyTrendsChart(records, isSmall),
                      const SizedBox(height: 20),
                      _buildWeeklyBarChart(records, isSmall),
                      const SizedBox(height: 20),
                      _buildLateArrivalTrends(records, isSmall),
                      const SizedBox(height: 20),
                      _buildDepartmentStats(records, isSmall),
                      const SizedBox(height: 20),
                      _buildHourlyDistribution(records, isSmall),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.bar_chart,
                                  size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text('No attendance data available',
                                  style:
                                      TextStyle(color: Colors.grey.shade600)),
                              const SizedBox(height: 8),
                              Text('Try selecting a different date range',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPeriodDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedPeriod,
          icon: Icon(Icons.arrow_drop_down, color: Colors.teal.shade700),
          style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
          items: _periodOptions.map<DropdownMenuItem<String>>((option) {
            return DropdownMenuItem<String>(
              value: option['label'] as String,
              child: Text(option['label'] as String),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedPeriod = value;

                final selectedOption = _periodOptions.firstWhere(
                  (opt) => opt['label'] == value,
                  orElse: () => _periodOptions[2],
                );

                if (value == 'Custom') {
                  _showCustomDateRangePicker();
                  return;
                }

                if (selectedOption['days'] > 0) {
                  _startDate = DateTime.now().subtract(
                    Duration(days: selectedOption['days']),
                  );
                  _endDate = DateTime.now();
                } else if (value == 'Today') {
                  _startDate = DateTime.now();
                  _endDate = DateTime.now();
                }
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildDateRangeIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade400, Colors.teal.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.calendar_today, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date Range',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 2),
                Text(
                  '${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${(_endDate.difference(_startDate).inDays + 1)} days',
              style: TextStyle(fontSize: 11, color: Colors.teal.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyMetricsCards(Map<String, dynamic> stats, bool isSmall) {
    final metrics = [
      {
        'label': 'Attendance Rate',
        'value': stats['attendanceRate'] > 0
            ? '${stats['attendanceRate'].toStringAsFixed(1)}%'
            : '0%',
        'icon': Icons.percent,
        'color': Colors.teal,
        'subtext': 'out of ${stats['totalEmployees']} employees',
      },
      {
        'label': 'Total Records',
        'value': stats['totalRecords'].toString(),
        'icon': Icons.receipt_long,
        'color': Colors.blue,
        'subtext': 'attendance entries',
      },
      {
        'label': 'Overtime',
        'value': '${stats['totalOvertime'].toStringAsFixed(1)}h',
        'icon': Icons.access_time,
        'color': Colors.orange,
        'subtext': 'extra hours worked',
      },
      {
        'label': 'Early Leave',
        'value': '${stats['totalEarlyLeave'].toStringAsFixed(1)}h',
        'icon': Icons.logout,
        'color': Colors.red,
        'subtext': 'early departures',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isSmall ? 2 : 4,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        final metric = metrics[index];
        final color = metric['color'] as Color;
        final icon = metric['icon'] as IconData;
        final value = metric['value'] as String;
        final label = metric['label'] as String;
        final subtext = metric['subtext'] as String;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color,
                        color.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Text(
                  subtext,
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusDistributionChart(List<QueryDocumentSnapshot> records,
      Map<String, dynamic> stats, bool isSmall) {
    final totalRecords = stats['totalRecords'] as int;

    if (totalRecords == 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200, width: 1.5),
        ),
        child: const Center(
          child: Text('No attendance data available for the selected period'),
        ),
      );
    }

    final List<Map<String, dynamic>> statusData = [];
    final colors = [Colors.green, Colors.orange, Colors.red, Colors.purple];
    final labels = ['Present', 'Late', 'Absent', 'Half Day'];
    final values = [
      stats['present'] as int,
      stats['late'] as int,
      stats['absent'] as int,
      stats['halfDay'] as int,
    ];

    for (int i = 0; i < labels.length; i++) {
      if (values[i] > 0) {
        statusData.add({
          'label': labels[i],
          'value': values[i],
          'color': colors[i],
          'percentage': (values[i] / totalRecords) * 100,
        });
      }
    }

    if (statusData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200, width: 1.5),
        ),
        child: const Center(child: Text('No status data available')),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade400, Colors.pink.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    const Icon(Icons.pie_chart, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Status Distribution',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Total: $totalRecords',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 280,
            child: PieChart(
              PieChartData(
                sections: statusData.map((data) {
                  final percentage = data['percentage'] as double;
                  return PieChartSectionData(
                    value: (data['value'] as int).toDouble(),
                    title: percentage > 8
                        ? '${percentage.toStringAsFixed(1)}%'
                        : '',
                    color: data['color'] as Color,
                    radius: 100,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    showTitle: percentage > 8,
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                startDegreeOffset: -90,
                pieTouchData: PieTouchData(enabled: false),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            alignment: WrapAlignment.center,
            children: statusData.map((data) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: data['color'] as Color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${data['label']}: ${data['value']} (${(data['percentage'] as double).toStringAsFixed(1)}%)',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyTrendsChart(
      List<QueryDocumentSnapshot> records, bool isSmall) {
    final dailyData = <String, Map<String, dynamic>>{};

    for (var record in records) {
      final date = (record['date'] as Timestamp).toDate();
      final dateKey = DateFormat('dd MMM').format(date);
      final status = record['status'] as String;

      if (!dailyData.containsKey(dateKey)) {
        dailyData[dateKey] = {
          'date': date,
          'present': 0,
          'late': 0,
          'absent': 0,
          'total': 0,
        };
      }

      if (status == 'Present')
        dailyData[dateKey]!['present'] =
            (dailyData[dateKey]!['present'] as int) + 1;
      if (status == 'Late')
        dailyData[dateKey]!['late'] = (dailyData[dateKey]!['late'] as int) + 1;
      if (status == 'Absent')
        dailyData[dateKey]!['absent'] =
            (dailyData[dateKey]!['absent'] as int) + 1;
      dailyData[dateKey]!['total'] = (dailyData[dateKey]!['total'] as int) + 1;
    }

    final sortedDates = dailyData.keys.toList()
      ..sort((a, b) => (dailyData[a]!['date'] as DateTime)
          .compareTo(dailyData[b]!['date'] as DateTime));

    if (sortedDates.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200, width: 1.5),
        ),
        child: const Center(child: Text('No daily trend data available')),
      );
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < sortedDates.length; i++) {
      final dateKey = sortedDates[i];
      final total = dailyData[dateKey]!['total'] as int;
      final present = dailyData[dateKey]!['present'] as int;
      final attendanceRate = total > 0 ? (present / total) * 100 : 0.0;
      spots.add(FlSpot(i.toDouble(), attendanceRate));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade400, Colors.cyan.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.trending_up,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Daily Attendance Trend',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < sortedDates.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Transform.rotate(
                              angle: -0.785,
                              child: Text(
                                sortedDates[value.toInt()],
                                style: const TextStyle(fontSize: 9),
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.teal,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.teal.withOpacity(0.1),
                    ),
                  ),
                ],
                minY: 0,
                maxY: 100,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '📈 Attendance Rate Trend (Last ${sortedDates.length} days)',
                style: TextStyle(fontSize: 11, color: Colors.teal.shade700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyBarChart(
      List<QueryDocumentSnapshot> records, bool isSmall) {
    final weeklyData = <String, Map<String, dynamic>>{};
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    for (var day in days) {
      weeklyData[day] = {'present': 0, 'total': 0};
    }

    for (var record in records) {
      final date = (record['date'] as Timestamp).toDate();
      final dayName = DateFormat('E').format(date);
      final status = record['status'] as String;

      if (weeklyData.containsKey(dayName)) {
        weeklyData[dayName]!['total'] =
            (weeklyData[dayName]!['total'] as int) + 1;
        if (status == 'Present') {
          weeklyData[dayName]!['present'] =
              (weeklyData[dayName]!['present'] as int) + 1;
        }
      }
    }

    final hasData = weeklyData.values.any((data) => (data['total'] as int) > 0);
    if (!hasData) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200, width: 1.5),
        ),
        child: const Center(child: Text('No weekly data available')),
      );
    }

    final barGroups = <BarChartGroupData>[];
    for (int i = 0; i < days.length; i++) {
      final day = days[i];
      final total = weeklyData[day]!['total'] as int;
      final present = weeklyData[day]!['present'] as int;
      final attendanceRate = total > 0 ? (present / total) * 100 : 0.0;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: attendanceRate,
              color: attendanceRate >= 75
                  ? Colors.green
                  : attendanceRate >= 50
                      ? Colors.orange
                      : Colors.red,
              width: 30,
              borderRadius: BorderRadius.circular(6),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: 100,
                color: Colors.grey.shade100,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange.shade400,
                      Colors.deepOrange.shade400
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    const Icon(Icons.bar_chart, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Weekly Attendance Performance',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barGroups: barGroups,
                gridData: FlGridData(
                  show: true,
                  drawHorizontalLine: true,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          days[value.toInt()],
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text('${value.toInt()}%',
                            style: const TextStyle(fontSize: 10));
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Wrap(
              spacing: 16,
              children: [
                _buildLegendItem(Colors.green, 'Excellent (>75%)'),
                _buildLegendItem(Colors.orange, 'Average (50-75%)'),
                _buildLegendItem(Colors.red, 'Poor (<50%)'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLateArrivalTrends(
      List<QueryDocumentSnapshot> records, bool isSmall) {
    final lateByHour = <int, int>{};
    for (int i = 0; i < 24; i++) lateByHour[i] = 0;

    for (var record in records) {
      if (record['status'] == 'Late' && record['checkInTime'] != null) {
        final checkIn = (record['checkInTime'] as Timestamp).toDate();
        final hour = checkIn.hour;
        lateByHour[hour] = (lateByHour[hour] ?? 0) + 1;
      }
    }

    final hasData = lateByHour.values.any((count) => count > 0);
    if (!hasData) {
      return const SizedBox.shrink();
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < 24; i++) {
      spots.add(FlSpot(i.toDouble(), (lateByHour[i] ?? 0).toDouble()));
    }

    final maxLate = lateByHour.values.isEmpty
        ? 1
        : lateByHour.values.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade400, Colors.orange.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.access_time,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Late Arrival Distribution',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 2,
                      getTitlesWidget: (value, meta) {
                        return Transform.rotate(
                          angle: -0.785,
                          child: Text(
                            '${value.toInt()}:00',
                            style: const TextStyle(fontSize: 9),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return Text(value.toInt().toString(),
                            style: const TextStyle(fontSize: 10));
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.redAccent,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.redAccent.withOpacity(0.1),
                    ),
                  ),
                ],
                minY: 0,
                maxY: maxLate.toDouble() + 1,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '⏰ Peak Late Hours: ${_getPeakHour(lateByHour)}:00',
                style: TextStyle(fontSize: 11, color: Colors.red.shade700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentStats(
      List<QueryDocumentSnapshot> records, bool isSmall) {
    final deptStats = <String, Map<String, dynamic>>{};

    for (var record in records) {
      final data = record.data() as Map<String, dynamic>;
      String dept = 'General';

      if (data.containsKey('department') && data['department'] != null) {
        dept = data['department'].toString();
      }

      final status = record['status'] as String;

      if (!deptStats.containsKey(dept)) {
        deptStats[dept] = {'present': 0, 'late': 0, 'absent': 0, 'total': 0};
      }

      deptStats[dept]!['total'] = (deptStats[dept]!['total'] as int) + 1;
      if (status == 'Present')
        deptStats[dept]!['present'] = (deptStats[dept]!['present'] as int) + 1;
      if (status == 'Late')
        deptStats[dept]!['late'] = (deptStats[dept]!['late'] as int) + 1;
      if (status == 'Absent')
        deptStats[dept]!['absent'] = (deptStats[dept]!['absent'] as int) + 1;
    }

    if (deptStats.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200, width: 1.5),
        ),
        child: const Center(child: Text('No department data available')),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade400, Colors.indigo.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    const Icon(Icons.business, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Department-wise Performance',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: deptStats.keys.length,
            itemBuilder: (context, index) {
              final dept = deptStats.keys.elementAt(index);
              final stats = deptStats[dept]!;
              final total = stats['total'] as int;
              final present = stats['present'] as int;
              final rate = total > 0 ? (present / total) * 100 : 0.0;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            dept,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: rate >= 75
                                ? Colors.green.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${rate.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: rate >= 75 ? Colors.green : Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: rate / 100,
                      backgroundColor: Colors.grey.shade200,
                      color: rate >= 75
                          ? Colors.green
                          : rate >= 50
                              ? Colors.orange
                              : Colors.red,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMiniStat(
                            'Present', stats['present'] as int, Colors.green),
                        _buildMiniStat(
                            'Late', stats['late'] as int, Colors.orange),
                        _buildMiniStat(
                            'Absent', stats['absent'] as int, Colors.red),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyDistribution(
      List<QueryDocumentSnapshot> records, bool isSmall) {
    final hourlyData = <int, int>{};
    for (int i = 0; i < 24; i++) hourlyData[i] = 0;

    for (var record in records) {
      if (record['checkInTime'] != null) {
        final checkIn = (record['checkInTime'] as Timestamp).toDate();
        final hour = checkIn.hour;
        hourlyData[hour] = (hourlyData[hour] ?? 0) + 1;
      }
    }

    final hasData = hourlyData.values.any((count) => count > 0);
    if (!hasData) {
      return const SizedBox.shrink();
    }

    final barGroups = <BarChartGroupData>[];
    for (int i = 0; i < 24; i++) {
      if (hourlyData[i]! > 0) {
        barGroups.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: hourlyData[i]!.toDouble(),
                color: Colors.teal,
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        );
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade400, Colors.teal.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    const Icon(Icons.schedule, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Check-in Hour Distribution',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                barGroups: barGroups,
                gridData: FlGridData(
                  show: true,
                  drawHorizontalLine: true,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 2,
                      getTitlesWidget: (value, meta) {
                        return Transform.rotate(
                          angle: -0.785,
                          child: Text(
                            '${value.toInt()}:00',
                            style: const TextStyle(fontSize: 9),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildMiniStat(String label, int value, Color color) {
    return Column(
      children: [
        Text(value.toString(),
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
      ],
    );
  }

  String _getPeakHour(Map<int, int> data) {
    int peakHour = 0;
    int maxCount = 0;
    data.forEach((hour, count) {
      if (count > maxCount) {
        maxCount = count;
        peakHour = hour;
      }
    });
    return peakHour.toString().padLeft(2, '0');
  }

  Future<void> _showCustomDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _selectedPeriod = 'Custom';
      });
    }
  }
}
