import 'package:flutter/material.dart';

class AdminBlogsScreen extends StatefulWidget {
  const AdminBlogsScreen({super.key});

  @override
  State<AdminBlogsScreen> createState() => _AdminBlogsScreenState();
}

class _AdminBlogsScreenState extends State<AdminBlogsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  final List<Map<String, dynamic>> _adminBlogs = [
    {
      'title': 'Mastering Employee Attendance Management',
      'description':
          'Advanced strategies for HR administrators to track, analyze, and optimize workforce attendance with real-time analytics',
      'date': 'Apr 10, 2024',
      'readTime': '8 min read',
      'color': const Color(0xFFE74C3C),
      'category': 'Administration',
      'content':
          'As an administrator, managing employee attendance effectively is crucial for organizational success. Implement automated tracking systems, set up geofencing for remote workers, use biometric verification, create attendance policies, generate automated reports, integrate with payroll, monitor trends, and address attendance issues proactively. These strategies will help you maintain a productive workforce while reducing administrative overhead.',
      'takeaways': [
        'Implement real-time attendance tracking systems',
        'Set up automated alerts for late arrivals',
        'Generate comprehensive attendance reports',
        'Integrate attendance data with payroll',
        'Create data-driven attendance policies'
      ]
    },
    {
      'title': 'Admin Guide to Leave Policy Optimization',
      'description':
          'How to create fair and efficient leave policies that balance employee needs with business requirements',
      'date': 'Apr 5, 2024',
      'readTime': '6 min read',
      'color': const Color(0xFF27AE60),
      'category': 'Policy Management',
      'content':
          'Creating effective leave policies requires careful consideration of both employee well-being and operational needs. Design tiered leave structures, implement blackout periods for peak seasons, automate approval workflows, track leave patterns, manage carryover policies, handle emergency leave requests, ensure compliance with labor laws, and communicate policies clearly to all employees.',
      'takeaways': [
        'Design flexible leave structures',
        'Automate leave approval workflows',
        'Track and analyze leave patterns',
        'Ensure legal compliance',
        'Communicate policies effectively'
      ]
    },
    {
      'title': 'Advanced Reporting & Analytics Dashboard',
      'description':
          'Leverage data analytics to make informed decisions about workforce management and resource allocation',
      'date': 'Mar 28, 2024',
      'readTime': '10 min read',
      'color': const Color(0xFF3498DB),
      'category': 'Analytics',
      'content':
          'Data-driven decision making is essential for modern administrators. Build custom dashboards, track key performance indicators, analyze attendance trends, predict staffing needs, identify productivity patterns, measure policy effectiveness, generate executive summaries, and export comprehensive reports. Use these insights to optimize workforce management and reduce operational costs.',
      'takeaways': [
        'Create custom analytics dashboards',
        'Track key attendance metrics',
        'Predict future staffing needs',
        'Identify productivity patterns',
        'Generate executive-ready reports'
      ]
    },
    {
      'title': 'Security Best Practices for Admin Dashboards',
      'description':
          'Essential security measures to protect sensitive employee data and maintain compliance',
      'date': 'Mar 20, 2024',
      'readTime': '7 min read',
      'color': const Color(0xFF9B59B6),
      'category': 'Security',
      'content':
          'Protecting employee data is critical for administrators. Implement multi-factor authentication, set up role-based access control, maintain audit logs, encrypt sensitive data, conduct regular security audits, train staff on security protocols, handle data breaches, ensure GDPR compliance, and backup data regularly. Stay ahead of potential security threats with proactive measures.',
      'takeaways': [
        'Enable multi-factor authentication',
        'Maintain comprehensive audit logs',
        'Encrypt all sensitive employee data',
        'Conduct regular security audits',
        'Ensure regulatory compliance'
      ]
    },
    {
      'title': 'Employee Performance Management Systems',
      'description':
          'Implementing effective performance tracking and feedback systems for better workforce outcomes',
      'date': 'Mar 15, 2024',
      'readTime': '9 min read',
      'color': const Color(0xFFF39C12),
      'category': 'Performance',
      'content':
          'Modern performance management requires continuous feedback and data-driven insights. Set up automated performance reviews, track goal completion, monitor productivity metrics, provide real-time feedback, identify high performers, address performance issues, create development plans, and link performance to rewards. These systems help retain top talent and improve overall productivity.',
      'takeaways': [
        'Automate performance review cycles',
        'Track real-time productivity metrics',
        'Implement continuous feedback systems',
        'Create personalized development plans',
        'Link performance to rewards'
      ]
    },
    {
      'title': 'HR Technology Stack Optimization',
      'description':
          'How to choose and integrate the right tools for efficient HR management and automation',
      'date': 'Mar 8, 2024',
      'readTime': '11 min read',
      'color': const Color(0xFF16A085),
      'category': 'Technology',
      'content':
          'Optimizing your HR technology stack improves efficiency and reduces costs. Evaluate current tools, identify integration opportunities, implement API connections, automate data synchronization, reduce manual data entry, improve user experience, scale with business growth, and measure ROI. Choose solutions that work together seamlessly to create a unified HR ecosystem.',
      'takeaways': [
        'Evaluate and optimize existing tools',
        'Implement seamless integrations',
        'Automate data synchronization',
        'Improve user experience',
        'Measure technology ROI'
      ]
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedAvatar(Color color, int index) {
    final List<IconData> icons = [
      Icons.admin_panel_settings,
      Icons.policy,
      Icons.analytics,
      Icons.security,
      Icons.trending_up,
      Icons.integration_instructions,
    ];

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 800 + (index * 100)),
      builder: (context, double value, child) {
        return Transform.scale(
          scale: 0.7 + (0.3 * value),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                icons[index % icons.length],
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text(
          'Admin Insights & Blogs',
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
              colors: [Color(0xFFE74C3C), Color(0xFFC0392B), Color(0xFFFF7043)],
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
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 1));
        },
        color: const Color(0xFFE74C3C),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _adminBlogs.length,
          itemBuilder: (context, index) {
            return TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: Duration(milliseconds: 400 + (index * 100)),
              builder: (context, double value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 40 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _adminBlogs[index]['color'].withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showBlogDetails(_adminBlogs[index]),
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAnimatedAvatar(
                              _adminBlogs[index]['color'], index),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _adminBlogs[index]['color']
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _adminBlogs[index]['color']
                                              .withOpacity(0.3),
                                          width: 0.5,
                                        ),
                                      ),
                                      child: Text(
                                        _adminBlogs[index]['category'],
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                          color: _adminBlogs[index]['color'],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _adminBlogs[index]['title'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2C3E50),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _adminBlogs[index]['description'],
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                    height: 1.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today,
                                        size: 12, color: Colors.grey.shade500),
                                    const SizedBox(width: 4),
                                    Text(
                                      _adminBlogs[index]['date'],
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(Icons.access_time,
                                        size: 12, color: Colors.grey.shade500),
                                    const SizedBox(width: 4),
                                    Text(
                                      _adminBlogs[index]['readTime'],
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios,
                              size: 16, color: Colors.grey.shade400),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showBlogDetails(Map<String, dynamic> blog) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border.all(
            color: blog['color'].withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [blog['color'], blog['color'].withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 600),
                    builder: (context, double value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.admin_panel_settings,
                            size: 40,
                            color: blog['color'],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    blog['title'],
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      blog['category'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today,
                          size: 14, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        blog['date'],
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                      Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white70,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Icon(Icons.access_time, size: 14, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        blog['readTime'],
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Administrator Guide',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      blog['content'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Key Takeaways for Admins',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...(blog['takeaways'] as List<String>).map((takeaway) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              child: Icon(Icons.admin_panel_settings,
                                  size: 18, color: blog['color']),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                takeaway,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: blog['color'].withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: blog['color'].withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.share_outlined, color: blog['color']),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Share this admin guide with your team',
                              style: TextStyle(
                                fontSize: 13,
                                color: blog['color'],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Icon(Icons.arrow_forward,
                              color: blog['color'], size: 18),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
