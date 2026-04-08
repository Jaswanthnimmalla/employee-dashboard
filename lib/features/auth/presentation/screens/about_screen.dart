import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen>
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
          'About',
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
                      color: const Color(0xFF6C5CE7).withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C5CE7).withOpacity(0.15),
                        blurRadius: 25,
                        spreadRadius: 2,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildAnimatedCircleIcon(
                          Icons.dashboard, const Color(0xFF6C5CE7), 110),
                      const SizedBox(height: 20),
                      const Text(
                        'Employee Dashboard',
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
                            colors: [Color(0xFF6C5CE7), Color(0xFF8E2DE2)],
                          ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6C5CE7).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Version 2.0.0',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Complete workforce management solution',
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
              title: 'Real-time Attendance Tracking',
              icon: Icons.analytics_outlined,
              color: const Color(0xFF4A90E2),
              shortDescription:
                  'Track employee attendance with precision using GPS and biometric verification.',
              longDescription:
                  'Our advanced attendance system allows employees to mark their attendance with GPS location tracking, photo capture, and biometric verification. Managers can monitor attendance in real-time and generate detailed reports.',
              benefits: [
                'GPS location tracking with accuracy',
                'Face recognition and fingerprint support',
                'Automatic late arrival detection',
                'Real-time attendance dashboard',
                'Export reports in multiple formats',
              ],
            ),
            _buildExpandableFeatureCard(
              title: 'Leave Request Management',
              icon: Icons.description_outlined,
              color: const Color(0xFF27AE60),
              shortDescription:
                  'Submit and manage leave requests with automated approval workflows.',
              longDescription:
                  'Employees can request various types of leaves including sick, casual, annual, and emergency leaves. Managers receive instant notifications and can approve or reject requests with comments. The system tracks leave balances automatically.',
              benefits: [
                'Multiple leave types supported',
                'Automatic leave balance tracking',
                'Email and push notifications',
                'Calendar view of team leaves',
                'Approval workflow with comments',
              ],
            ),
            _buildExpandableFeatureCard(
              title: 'Advanced Analytics & Reports',
              icon: Icons.bar_chart_outlined,
              color: const Color(0xFFF39C12),
              shortDescription:
                  'Get insights with detailed analytics and customizable reports.',
              longDescription:
                  'Powerful analytics engine provides insights into attendance patterns, leave trends, and employee performance. Generate custom reports with multiple filters and export them in PDF, Excel, or CSV formats.',
              benefits: [
                'Interactive dashboards and charts',
                'Custom report builder',
                'Export to PDF, Excel, CSV',
                'Trend analysis and predictions',
                'Department-wise analytics',
              ],
            ),
            _buildExpandableFeatureCard(
              title: 'Secure Biometric Authentication',
              icon: Icons.security_outlined,
              color: const Color(0xFFE74C3C),
              shortDescription:
                  'Protect sensitive data with fingerprint and face recognition.',
              longDescription:
                  'Enterprise-grade security with biometric authentication ensures that only authorized users can access the application. Supports fingerprint, face ID, and pattern lock for maximum security.',
              benefits: [
                'Fingerprint and Face ID support',
                'Two-factor authentication',
                'Encrypted data storage',
                'Session timeout protection',
                'Secure API communication',
              ],
            ),
            _buildExpandableFeatureCard(
              title: 'Real-time Notifications',
              icon: Icons.notifications_outlined,
              color: const Color(0xFF9B59B6),
              shortDescription:
                  'Stay updated with instant push notifications and alerts.',
              longDescription:
                  'Get real-time notifications for attendance updates, leave approvals, announcements, and reminders. Customize notification preferences for different event types.',
              benefits: [
                'Push notifications for important events',
                'Email notifications as backup',
                'Customizable alert preferences',
                'In-app notification center',
                'Daily summary reports',
              ],
            ),
            _buildExpandableFeatureCard(
              title: 'Cloud Data Synchronization',
              icon: Icons.cloud_sync_outlined,
              color: const Color(0xFF3498DB),
              shortDescription:
                  'Access your data anywhere with real-time cloud sync.',
              longDescription:
                  'All data is automatically synchronized across all devices in real-time. Work offline and changes will sync when you\'re back online. Your data is always backed up and secure.',
              benefits: [
                'Real-time cross-device sync',
                'Offline mode support',
                'Automatic data backup',
                'End-to-end encryption',
                '99.9% uptime guarantee',
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
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF6C5CE7),
                        const Color(0xFF8E2DE2)
                      ],
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
                        color: const Color(0xFF6C5CE7).withOpacity(0.3),
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
                            child: const Icon(Icons.developer_mode,
                                color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 14),
                          const Text(
                            'Developed By',
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
                                  Icons.person_outline,
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
                        'Admin Team',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Building better workplace solutions',
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
                        '© ${DateTime.now().year} All Rights Reserved',
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
