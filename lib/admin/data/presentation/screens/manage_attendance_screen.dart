import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:employee_dashboard_app/admin/data/presentation/screens/attendance_statistics_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:employee_dashboard_app/core/utils/attendance_time_logic.dart';

class ManageAttendanceScreen extends StatefulWidget {
  const ManageAttendanceScreen({super.key});

  @override
  State<ManageAttendanceScreen> createState() => _ManageAttendanceScreenState();
}

class _ManageAttendanceScreenState extends State<ManageAttendanceScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _searchQuery = '';
  String _selectedEmployee = 'all';
  String _selectedStatus = 'all';
  DateTime? _selectedDate;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  List<String> _employees = ['all'];

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    try {
      final users = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'Team Member') // Change this line
          .get();

      print('Loaded employees count: ${users.docs.length}'); // Debug print

      setState(() {
        _employees = ['all'];
        _employees.addAll(users.docs
            .map((doc) => doc['name']?.toString() ?? 'Unknown')
            .toList());
      });
    } catch (e) {
      print('Error loading employees: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmall = screenSize.width < 600;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(isSmall ? 12 : 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsCards(),
                  const SizedBox(height: 16),
                  _buildSearchAndFilters(),
                  const SizedBox(height: 16),
                  _buildAttendanceList(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Attendance Management',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          letterSpacing: 0.5,
        ),
      ),
      centerTitle: true,
      elevation: 4,
      backgroundColor: const Color(0xFF1A237E),
      foregroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1A237E),
              Color(0xFF283593),
              Color(0xFF303F9F),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: IconButton(
            icon: const Icon(Icons.analytics, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AttendanceStatisticsScreen(),
                ),
              );
            },
            tooltip: 'View Statistics',
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              padding: const EdgeInsets.all(8),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: _exportToExcel,
            tooltip: 'Export to Excel',
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              padding: const EdgeInsets.all(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .where('role', isEqualTo: 'Team Member')
          .snapshots(),
      builder: (context, usersSnapshot) {
        if (usersSnapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      color: Colors.red.shade400, size: 48),
                  const SizedBox(height: 12),
                  Text('Error loading employees'),
                ],
              ),
            ),
          );
        }

        if (!usersSnapshot.hasData) {
          return _buildShimmerStats();
        }

        final allEmployees = usersSnapshot.data!.docs;
        final totalEmployees = allEmployees.length;

        print('Total employees found: $totalEmployees');

        if (totalEmployees == 0) {
          return Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No employees found'),
                ],
              ),
            ),
          );
        }

        return StreamBuilder<QuerySnapshot>(
          stream: _buildAttendanceStream(),
          builder: (context, attendanceSnapshot) {
            if (!attendanceSnapshot.hasData) {
              return _buildShimmerStats();
            }

            final allRecords = attendanceSnapshot.data!.docs;
            final filteredRecords = allRecords;

            final Map<String, String> employeeBestStatus = {};

            final now = DateTime.now();

            final cutoff = DateTime(
              now.year,
              now.month,
              now.day,
              11,
              40,
            );

            for (final employee in allEmployees) {
              final employeeId = employee.id;

              if (now.isAfter(cutoff)) {
                employeeBestStatus[employeeId] = 'Absent';
              } else {
                employeeBestStatus[employeeId] = 'Pending';
              }
            }

            final startDate = _selectedDate ?? _startDate;
            final endDate = _selectedDate ?? _endDate;

            for (final record in filteredRecords) {
              final userId = record['userId']?.toString() ?? '';
              final status = record['status']?.toString() ?? 'Absent';

              if (userId.isEmpty || !employeeBestStatus.containsKey(userId)) {
                continue;
              }

              if (status == 'Present') {
                employeeBestStatus[userId] = 'Present';
              } else if (status == 'Half Day' &&
                  employeeBestStatus[userId] != 'Present') {
                employeeBestStatus[userId] = 'Half Day';
              } else if (status == 'Very Late' &&
                  employeeBestStatus[userId] != 'Present' &&
                  employeeBestStatus[userId] != 'Half Day') {
                employeeBestStatus[userId] = 'Very Late';
              } else if (status == 'Late' &&
                  employeeBestStatus[userId] != 'Present' &&
                  employeeBestStatus[userId] != 'Half Day' &&
                  employeeBestStatus[userId] != 'Very Late') {
                employeeBestStatus[userId] = 'Late';
              }
            }

            int present = 0;
            int late = 0;
            int veryLate = 0;
            int absent = 0;
            int halfDay = 0;

            for (final status in employeeBestStatus.values) {
              switch (status) {
                case 'Present':
                  present++;
                  break;
                case 'Very Late':
                  veryLate++;
                  break;
                case 'Late':
                  late++;
                  break;
                case 'Half Day':
                  halfDay++;
                  break;
                case 'Absent':
                  if (now.isAfter(cutoff)) {
                    absent++;
                  }
                  break;
              }
            }

            final presentEmployeeIds = <String>{};

            for (final record in filteredRecords) {
              final userId = record['userId']?.toString();

              if (userId != null && record['checkInTime'] != null) {
                presentEmployeeIds.add(userId);
              }
            }

            final presentCount = presentEmployeeIds.length;

            double attendancePercentage = totalEmployees > 0
                ? (presentCount / totalEmployees) * 100
                : 0.0;

            attendancePercentage = attendancePercentage.clamp(0, 100);
            attendancePercentage = attendancePercentage.clamp(0, 100);

            return LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final crossAxisCount = width > 900
                    ? 6
                    : width > 700
                        ? 5
                        : width > 500
                            ? 4
                            : 3;
                final cardWidth =
                    (width - (crossAxisCount - 1) * 10) / crossAxisCount;

                return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildStatCard(
                        'Total Employees',
                        totalEmployees.toString(),
                        Icons.people,
                        Colors.blue,
                        cardWidth,
                      ),
                      _buildStatCard(
                        'Present',
                        presentCount.toString(),
                        Icons.check_circle,
                        Colors.green,
                        cardWidth,
                      ),
                      _buildStatCard(
                        'Late',
                        late.toString(),
                        Icons.access_time,
                        Colors.orange,
                        cardWidth,
                      ),
                      _buildStatCard(
                        'Absent',
                        absent.toString(),
                        Icons.cancel,
                        Colors.red,
                        cardWidth,
                      ),
                      _buildStatCard(
                        'Half Day',
                        halfDay.toString(),
                        Icons.hourglass_bottom,
                        Colors.purple,
                        cardWidth,
                      ),
                      _buildStatCard(
                        'Very Late',
                        veryLate.toString(),
                        Icons.watch_later,
                        Colors.deepOrange,
                        cardWidth,
                      ),
                    ]);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    double width,
  ) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(
        vertical: 10,
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          /// SEARCH FIELD
          TextField(
            onChanged: (value) =>
                setState(() => _searchQuery = value.toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Search by name or email...',
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 13,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.search,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        size: 18,
                        color: Colors.grey.shade500,
                      ),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.grey.shade300,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1.2,
                ),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(
                  color: Colors.blue,
                  width: 1.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          DropdownButtonFormField<String>(
            value: _selectedEmployee,
            decoration: InputDecoration(
              labelText: 'Employee',
              prefixIcon: Container(
                margin: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Colors.green,
                  size: 20,
                ),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: _employees.map((employee) {
              return DropdownMenuItem(
                value: employee,
                child: Text(
                  employee == 'all' ? 'All Employees' : employee,
                ),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedEmployee = value!),
          ),

          const SizedBox(height: 14),

          DropdownButtonFormField<String>(
            value: _selectedStatus,
            decoration: InputDecoration(
              labelText: 'Status',
              prefixIcon: Container(
                margin: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.flag_outlined,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items:
                ['all', 'Present', 'Late', 'Absent', 'Half Day'].map((status) {
              return DropdownMenuItem(
                value: status,
                child: Text(
                  status == 'all' ? 'All Status' : status,
                ),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedStatus = value!),
          ),

          const SizedBox(height: 14),

          InkWell(
            onTap: _showDateRangePicker,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.date_range,
                      size: 18,
                      color: Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${DateFormat('dd MMM').format(_startDate)} - ${DateFormat('dd MMM').format(_endDate)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _buildAttendanceStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              children: [
                Icon(Icons.error_outline,
                    size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text('Error: ${snapshot.error}',
                    style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerList();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text('No attendance records',
                    style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                Text('Try adjusting your filters',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          );
        }

        var records = _applyFilters(snapshot.data!.docs);

        if (records.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                Icon(Icons.filter_alt_off,
                    size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text('No matching records',
                    style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          );
        }

        _autoMarkAbsent(records);

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: records.length,
          itemBuilder: (context, index) => _buildAttendanceCard(records[index]),
        );
      },
    );
  }

  Widget _buildAttendanceCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final status = data['status'] ?? 'Present';
    final isAbsent = status == 'Absent';

    final checkInTime = data['checkInTime'] != null
        ? (data['checkInTime'] as Timestamp).toDate()
        : null;

    final checkOutTime = data['checkOutTime'] != null
        ? (data['checkOutTime'] as Timestamp).toDate()
        : null;

    final totalHours = data['totalHours'] ?? 0.0;

    final date = (data['date'] as Timestamp).toDate();

    final photoUrl = data['photoUrl'] ?? '';

    Color statusColor;

    switch (status) {
      case 'Present':
        statusColor = Colors.green;
        break;

      case 'Late':
        statusColor = Colors.orange;
        break;

      case 'Very Late':
        statusColor = Colors.deepOrange;
        break;

      case 'Half Day':
        statusColor = Colors.purple;
        break;

      case 'Absent':
        statusColor = Colors.red;
        break;

      default:
        statusColor = Colors.blue;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withOpacity(0.4),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showEmployeeDetailsDialog(
            doc,
            checkInTime,
            checkOutTime,
            date,
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                /// TOP ROW
                Row(
                  children: [
                    /// PROFILE IMAGE
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: statusColor.withOpacity(0.4),
                          width: 1.2,
                        ),
                      ),
                      child: photoUrl.isNotEmpty
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: photoUrl,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Center(
                              child: Text(
                                data['userName']?.toString().isNotEmpty == true
                                    ? data['userName'][0].toUpperCase()
                                    : 'E',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ),

                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['userName'] ?? 'Employee',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data['userEmail'] ?? '',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(
                                0.12,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: statusColor.withOpacity(0.5),
                              ),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Divider(
                  color: Colors.grey.shade300,
                  thickness: 1,
                ),

                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('dd MMM yyyy').format(date),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (checkInTime != null)
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.login,
                              size: 14,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              DateFormat('hh:mm a').format(checkInTime),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (checkOutTime != null)
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.logout,
                              size: 14,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              DateFormat('hh:mm a').format(checkOutTime),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                if (totalHours > 0 && !isAbsent) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${totalHours.toStringAsFixed(1)} hours',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEmployeeDetailsDialog(QueryDocumentSnapshot doc,
      DateTime? checkInTime, DateTime? checkOutTime, DateTime date) {
    final data = doc.data() as Map<String, dynamic>;
    final status = data['status'] ?? 'Present';
    final totalHours = data['totalHours'] ?? 0.0;
    final overtime = totalHours > 8 ? totalHours - 8 : 0.0;
    final earlyLeave = (status == 'Present' && totalHours < 8 && totalHours > 0)
        ? 8 - totalHours
        : 0.0;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 18,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 520,
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// HEADER WITH SELFIE IMAGE
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.08),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.25),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.4),
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: data['photoUrl'] != null &&
                                data['photoUrl'].toString().isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: data['photoUrl'],
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                errorWidget: (context, url, error) {
                                  return Center(
                                    child: Text(
                                      data['userName']?.toString().isNotEmpty ==
                                              true
                                          ? data['userName'][0].toUpperCase()
                                          : 'E',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                },
                              )
                            : Center(
                                child: Text(
                                  data['userName']?.toString().isNotEmpty ==
                                          true
                                      ? data['userName'][0].toUpperCase()
                                      : 'E',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['userName'] ?? 'Employee',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            status,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      _buildDetailRow(
                        Icons.email_outlined,
                        'Email',
                        data['userEmail'] ?? 'Not provided',
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        Icons.calendar_today,
                        'Date',
                        DateFormat(
                          'dd MMM yyyy, EEEE',
                        ).format(date),
                      ),
                      const SizedBox(height: 12),
                      if (checkInTime != null)
                        _buildDetailRow(
                          Icons.login,
                          'Check In',
                          DateFormat(
                            'hh:mm a',
                          ).format(checkInTime),
                        ),
                      if (checkOutTime != null) ...[
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          Icons.logout,
                          'Check Out',
                          DateFormat(
                            'hh:mm a',
                          ).format(checkOutTime),
                        ),
                      ],
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        Icons.timer,
                        'Total Hours',
                        '${totalHours.toStringAsFixed(1)} hours',
                      ),
                      if (overtime > 0) ...[
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          Icons.access_time,
                          'Overtime',
                          '+${overtime.toStringAsFixed(1)} hours',
                        ),
                      ],
                      if (earlyLeave > 0) ...[
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          Icons.logout,
                          'Early Leave',
                          '-${earlyLeave.toStringAsFixed(1)} hours',
                        ),
                      ],
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        Icons.work,
                        'Work Type',
                        data['workType'] ?? 'Office',
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        Icons.location_on,
                        'Location',
                        data['locationAddress'] ?? 'Not available',
                      ),
                      if (data['notes'] != null &&
                          data['notes'].toString().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          Icons.note,
                          'Notes',
                          data['notes'],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.grey.shade300,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          'Close',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);

                          _showEditDialog(
                            doc,
                            checkInTime,
                            checkOutTime,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          'Edit Record',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
  ) {
    Color iconColor;

    if (label.contains('Email')) {
      iconColor = Colors.blue;
    } else if (label.contains('Date')) {
      iconColor = Colors.purple;
    } else if (label.contains('Check In')) {
      iconColor = Colors.green;
    } else if (label.contains('Check Out')) {
      iconColor = Colors.red;
    } else if (label.contains('Hours')) {
      iconColor = Colors.teal;
    } else if (label.contains('Overtime')) {
      iconColor = Colors.orange;
    } else if (label.contains('Early')) {
      iconColor = Colors.deepOrange;
    } else if (label.contains('Work')) {
      iconColor = Colors.indigo;
    } else if (label.contains('Location')) {
      iconColor = Colors.brown;
    } else if (label.contains('Notes')) {
      iconColor = Colors.grey;
    } else {
      iconColor = Colors.blueGrey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: iconColor.withOpacity(0.35),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: iconColor.withOpacity(0.4),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              size: 18,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(QueryDocumentSnapshot doc, DateTime? currentCheckIn,
      DateTime? currentCheckOut) {
    DateTime? newCheckIn = currentCheckIn;
    DateTime? newCheckOut = currentCheckOut;
    String selectedStatus = doc['status'] ?? 'Present';
    final notesController = TextEditingController(text: doc['notes'] ?? '');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Edit Attendance',
                style: TextStyle(fontWeight: FontWeight.w600)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      prefixIcon: Icon(Icons.flag_outlined),
                    ),
                    items: ['Present', 'Late', 'Absent', 'Half Day']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setDialogState(() => selectedStatus = v!),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: const Icon(Icons.login, size: 18),
                    title: const Text('Check In Time',
                        style: TextStyle(fontSize: 13)),
                    subtitle: Text(newCheckIn != null
                        ? DateFormat('hh:mm a').format(newCheckIn!)
                        : 'Not set'),
                    trailing: const Icon(Icons.access_time, size: 18),
                    onTap: () async {
                      final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(
                              newCheckIn ?? DateTime.now()));
                      if (time != null) {
                        setDialogState(() {
                          newCheckIn = DateTime(
                            DateTime.now().year,
                            DateTime.now().month,
                            DateTime.now().day,
                            time.hour,
                            time.minute,
                          );
                          if (newCheckOut != null && newCheckIn != null) {
                            final hours =
                                newCheckOut!.difference(newCheckIn!).inMinutes /
                                    60;
                            if (newCheckIn != null) {
                              selectedStatus =
                                  AttendanceTimeLogic.getStatus(newCheckIn!);
                            }
                          }
                        });
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout, size: 18),
                    title: const Text('Check Out Time',
                        style: TextStyle(fontSize: 13)),
                    subtitle: Text(newCheckOut != null
                        ? DateFormat('hh:mm a').format(newCheckOut!)
                        : 'Not set'),
                    trailing: const Icon(Icons.logout, size: 18),
                    onTap: () async {
                      final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(
                              newCheckOut ?? DateTime.now()));
                      if (time != null) {
                        setDialogState(() {
                          newCheckOut = DateTime(
                            DateTime.now().year,
                            DateTime.now().month,
                            DateTime.now().day,
                            time.hour,
                            time.minute,
                          );
                          if (newCheckIn != null && newCheckOut != null) {
                            final hours =
                                newCheckOut!.difference(newCheckIn!).inMinutes /
                                    60;
                            if (selectedStatus == 'Present' ||
                                selectedStatus == 'Late' ||
                                selectedStatus == 'Half Day') {
                              if (hours >= 8)
                                selectedStatus = 'Present';
                              else if (hours >= 4)
                                selectedStatus = 'Half Day';
                              else if (hours > 0) selectedStatus = 'Late';
                            }
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      prefixIcon: Icon(Icons.note),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  double totalHours = 0.0;
                  double overtime = 0.0;
                  double earlyLeave = 0.0;

                  if (newCheckIn != null && newCheckOut != null) {
                    final result = calculateOvertimeEarlyLeave(
                      newCheckIn!,
                      newCheckOut!,
                    );

                    totalHours = result['totalHours']!;
                    overtime = result['overtime']!;
                    earlyLeave = result['earlyLeave']!;
                  }

                  await _firestore.collection('attendance').doc(doc.id).update({
                    'status': selectedStatus,
                    'checkInTime': newCheckIn != null
                        ? Timestamp.fromDate(newCheckIn!)
                        : doc['checkInTime'],
                    'checkOutTime': newCheckOut != null
                        ? Timestamp.fromDate(newCheckOut!)
                        : doc['checkOutTime'],
                    'totalHours': totalHours,
                    'notes': notesController.text,
                  });
                  Navigator.pop(context);
                  _showSnackBar('Attendance updated successfully');
                },
                child: const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _autoMarkAbsent(List<QueryDocumentSnapshot> records) async {
    final now = DateTime.now();

    if (now.hour < 11 || (now.hour == 11 && now.minute < 40)) return;

    final todayStart = DateTime(now.year, now.month, now.day);

    final todayRecords = records.where((doc) {
      final date = (doc['date'] as Timestamp).toDate();
      final dateStart = DateTime(date.year, date.month, date.day);
      return dateStart.isAtSameMomentAs(todayStart);
    }).toList();

    final employeesWithAttendance =
        todayRecords.map((doc) => doc['userId']).toSet();

    final users = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'Team Member')
        .get();

    for (var user in users.docs) {
      if (!employeesWithAttendance.contains(user.id)) {
        final existingRecord = await _firestore
            .collection('attendance')
            .where('userId', isEqualTo: user.id)
            .where('date', isEqualTo: Timestamp.fromDate(todayStart))
            .limit(1)
            .get();

        if (existingRecord.docs.isEmpty) {
          await _firestore.collection('attendance').add({
            'userId': user.id,
            'userName': user['name'] ?? 'Unknown',
            'userEmail': user['email'] ?? '',
            'date': Timestamp.fromDate(todayStart),
            'status': 'Absent',
            'checkInTime': null,
            'checkOutTime': null,
            'totalHours': 0.0,
            'workType': 'Office',
            'notes': 'Auto-marked absent',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
    }
  }

  Map<String, double> calculateOvertimeEarlyLeave(
    DateTime checkIn,
    DateTime checkOut,
  ) {
    final officeEnd = DateTime(
      checkOut.year,
      checkOut.month,
      checkOut.day,
      18,
      0,
    );

    final totalMinutes = checkOut.difference(checkIn).inMinutes;

    final totalHours = totalMinutes / 60.0;

    double overtime = 0;
    double earlyLeave = 0;

    if (checkOut.isAfter(officeEnd)) {
      overtime = checkOut.difference(officeEnd).inMinutes / 60.0;
    }

    if (checkOut.isBefore(officeEnd)) {
      earlyLeave = officeEnd.difference(checkOut).inMinutes / 60.0;
    }

    return {
      'totalHours': totalHours,
      'overtime': overtime,
      'earlyLeave': earlyLeave,
    };
  }

  void _showDateRangePicker() async {
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
      });
    }
  }

  Future<void> _exportToExcel() async {
    try {
      final records = await _buildAttendanceQuery().get();
      final filtered = _applyFilters(records.docs);

      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Attendance Report'];

      sheetObject.appendRow([
        TextCellValue('Date'),
        TextCellValue('Employee Name'),
        TextCellValue('Email'),
        TextCellValue('Status'),
        TextCellValue('Check In'),
        TextCellValue('Check Out'),
        TextCellValue('Total Hours'),
        TextCellValue('Overtime'),
        TextCellValue('Early Leave'),
        TextCellValue('Work Type'),
        TextCellValue('Location'),
        TextCellValue('Notes'),
      ]);

      for (var doc in filtered) {
        final data = doc.data() as Map<String, dynamic>;
        final checkIn = data['checkInTime'] != null
            ? (data['checkInTime'] as Timestamp).toDate()
            : null;
        final checkOut = data['checkOutTime'] != null
            ? (data['checkOutTime'] as Timestamp).toDate()
            : null;
        final totalHours = data['totalHours'] ?? 0.0;
        final overtime = totalHours > 8 ? totalHours - 8 : 0.0;
        final earlyLeave =
            (data['status'] == 'Present' && totalHours < 8 && totalHours > 0)
                ? 8 - totalHours
                : 0.0;

        sheetObject.appendRow([
          TextCellValue(
            DateFormat('dd/MM/yyyy')
                .format((data['date'] as Timestamp).toDate()),
          ),
          TextCellValue(data['userName'] ?? ''),
          TextCellValue(data['userEmail'] ?? ''),
          TextCellValue(data['status'] ?? ''),
          TextCellValue(
            checkIn != null ? DateFormat('hh:mm a').format(checkIn) : '-',
          ),
          TextCellValue(
            checkOut != null ? DateFormat('hh:mm a').format(checkOut) : '-',
          ),
          DoubleCellValue(totalHours.toDouble()),
          DoubleCellValue(overtime.toDouble()),
          DoubleCellValue(earlyLeave.toDouble()),
          TextCellValue(data['workType'] ?? ''),
          TextCellValue(data['locationAddress'] ?? ''),
          TextCellValue(data['notes'] ?? ''),
        ]);
      }

      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/attendance_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx');
      await file.writeAsBytes(excel.encode()!);

      _showSnackBar('Exported to ${file.path.split('/').last}');
    } catch (e) {
      _showSnackBar('Export failed: $e');
    }
  }

  Stream<QuerySnapshot> _buildAttendanceStream() {
    Query query =
        _firestore.collection('attendance').orderBy('date', descending: true);
    if (_selectedDate != null) {
      final start = DateTime(
          _selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
      final end = DateTime(_selectedDate!.year, _selectedDate!.month,
          _selectedDate!.day, 23, 59, 59);
      return query
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .snapshots();
    } else {
      return query
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(_endDate))
          .snapshots();
    }
  }

  Query _buildAttendanceQuery() {
    Query query =
        _firestore.collection('attendance').orderBy('date', descending: true);
    if (_selectedDate != null) {
      final start = DateTime(
          _selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
      final end = DateTime(_selectedDate!.year, _selectedDate!.month,
          _selectedDate!.day, 23, 59, 59);
      query = query
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end));
    } else {
      query = query
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(_endDate));
    }
    return query;
  }

  List<QueryDocumentSnapshot> _applyFilters(
      List<QueryDocumentSnapshot> records) {
    var filtered = records;
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((doc) {
        final name = doc['userName']?.toString().toLowerCase() ?? '';
        final email = doc['userEmail']?.toString().toLowerCase() ?? '';
        return name.contains(_searchQuery) || email.contains(_searchQuery);
      }).toList();
    }
    if (_selectedEmployee != 'all') {
      filtered = filtered
          .where((doc) => doc['userName'] == _selectedEmployee)
          .toList();
    }
    if (_selectedStatus != 'all') {
      filtered =
          filtered.where((doc) => doc['status'] == _selectedStatus).toList();
    }
    return filtered;
  }

  Widget _buildShimmerStats() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(
          6,
          (index) => Container(
                width: 100,
                height: 80,
                color: Colors.grey.shade200,
              )),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: 5,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 120,
        color: Colors.grey.shade200,
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          backgroundColor: Colors.grey.shade800,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
    );
  }
}
