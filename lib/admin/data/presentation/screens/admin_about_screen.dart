import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminAboutScreen extends StatefulWidget {
  const AdminAboutScreen({super.key});

  @override
  State<AdminAboutScreen> createState() => _AdminAboutScreenState();
}

class _AdminAboutScreenState extends State<AdminAboutScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final Map<String, bool> _expandedStates = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedCircleIcon(IconData icon, Color color, double size) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1000),
      builder: (context, double value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: size * 0.5),
          ),
        );
      },
    );
  }

  Widget _buildExpandableFeatureCard({
    required String title,
    required IconData icon,
    required Color color,
    required String shortDescription,
    required String longDescription,
    required List<String> benefits,
  }) {
    final isExpanded = _expandedStates[title] ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _expandedStates[title] = !isExpanded;
            });
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: color.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: color,
                      size: 28,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  shortDescription,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                if (isExpanded) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: color.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          longDescription,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...benefits
                            .map((benefit) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    children: [
                                      Icon(Icons.check_circle,
                                          color: color, size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          benefit,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text(
          'Admin About',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6C5CE7), Color(0xFF8E2DE2), Color(0xFFFF7043)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: const Color(0xFFE74C3C).withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE74C3C).withOpacity(0.15),
                        blurRadius: 25,
                        spreadRadius: 2,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildAnimatedCircleIcon(
                          Icons.admin_panel_settings, const Color(0xFFE74C3C), 110),
                      const SizedBox(height: 20),
                      const Text(
                        'Admin Control Panel',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE74C3C), Color(0xFFC0392B)],
                          ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE74C3C).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Administrator Version 2.0.0',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Complete workforce management solution for administrators',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildExpandableFeatureCard(
              title: 'Employee Management System',
              icon: Icons.people_alt_outlined,
              color: const Color(0xFF3498DB),
              shortDescription:
                  'Complete control over employee profiles, roles, and permissions.',
              longDescription:
                  'Admins can add, edit, and remove employees, assign roles and departments, manage permissions, and track employee performance. The system provides a comprehensive view of all workforce data in one place.',
              benefits: [
                'Bulk employee import/export',
                'Role-based access control',
                'Department and team management',
                'Employee performance tracking',
                'Document management system',
              ],
            ),
            _buildExpandableFeatureCard(
              title: 'Attendance Analytics Dashboard',
              icon: Icons.analytics_outlined,
              color: const Color(0xFF27AE60),
              shortDescription:
                  'Real-time attendance monitoring with advanced analytics.',
              longDescription:
                  'Monitor employee attendance in real-time with detailed analytics. View attendance patterns, late arrivals, early departures, and generate comprehensive reports. Export data for payroll processing.',
              benefits: [
                'Real-time attendance tracking',
                'Late arrival & early departure alerts',
                'Attendance heatmaps and trends',
                'Export reports for payroll',
                'Custom attendance policies',
              ],
            ),
            _buildExpandableFeatureCard(
              title: 'Leave & Request Management',
              icon: Icons.description_outlined,
              color: const Color(0xFFF39C12),
              shortDescription:
                  'Manage and approve leave requests with automated workflows.',
              longDescription:
                  'Review, approve, or reject employee leave requests and other submissions. Set leave policies, track leave balances, and manage holiday calendars. Automated notifications keep everyone informed.',
              benefits: [
                'Bulk approval/rejection of requests',
                'Custom leave policies per department',
                'Holiday calendar management',
                'Leave balance tracking',
                'Email notifications to employees',
              ],
            ),
            _buildExpandableFeatureCard(
              title: 'Advanced Reporting Engine',
              icon: Icons.bar_chart_outlined,
              color: const Color(0xFF9B59B6),
              shortDescription:
                  'Generate comprehensive reports with multiple filters.',
              longDescription:
                  'Create custom reports for attendance, leaves, employee performance, and more. Apply filters by date, department, employee, or status. Export reports in multiple formats for management review.',
              benefits: [
                'Custom report builder',
                'PDF, Excel, CSV export',
                'Scheduled report generation',
                'Department-wise analytics',
                'Visual charts and graphs',
              ],
            ),
            _buildExpandableFeatureCard(
              title: 'Security & Audit Logs',
              icon: Icons.security_outlined,
              color: const Color(0xFFE74C3C),
              shortDescription:
                  'Track all admin activities with comprehensive audit logs.',
              longDescription:
                  'Every action performed by administrators is logged for security and compliance. Track user logins, changes to employee data, approvals, and system configuration changes.',
              benefits: [
                'Complete audit trail',
                'User activity monitoring',
                'Failed login attempts tracking',
                'IP address logging',
                'Compliance reporting',
              ],
            ),
            _buildExpandableFeatureCard(
              title: 'System Configuration',
              icon: Icons.settings_outlined,
              color: const Color(0xFF34495E),
              shortDescription:
                  'Configure system settings, policies, and notifications.',
              longDescription:
                  'Customize the system to match your organization\'s needs. Configure attendance policies, leave rules, notification templates, and system preferences from a centralized dashboard.',
              benefits: [
                'Customizable notification templates',
                'Attendance policy configuration',
                'Leave policy management',
                'System preferences',
                'Backup and restore options',
              ],
            ),
            const SizedBox(height: 20),
            FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE74C3C), Color(0xFFC0392B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE74C3C).withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.4)),
                            ),
                            child: const Icon(Icons.admin_panel_settings,
                                color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 14),
                          const Text(
                            'Admin Development Team',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 1000),
                        builder: (context, double value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.shield_outlined,
                                  color: Colors.white,
                                  size: 50,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Administrator Team',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Enterprise workforce management solutions',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildSocialIcon(Icons.email_outlined, Colors.white),
                          const SizedBox(width: 16),
                          _buildSocialIcon(Icons.link, Colors.white),
                          const SizedBox(width: 16),
                          _buildSocialIcon(Icons.code, Colors.white),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white24, height: 1),
                      const SizedBox(height: 12),
                      Text(
                        '© ${DateTime.now().year} Admin Dashboard - All Rights Reserved',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}