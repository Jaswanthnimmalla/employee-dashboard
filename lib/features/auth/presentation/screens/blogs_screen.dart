import 'package:flutter/material.dart';

class BlogsScreen extends StatefulWidget {
  const BlogsScreen({super.key});

  @override
  State<BlogsScreen> createState() => _BlogsScreenState();
}

class _BlogsScreenState extends State<BlogsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  final List<Map<String, dynamic>> _blogs = [
    {
      'title': '5 Tips for Better Attendance Management',
      'description':
          'Learn how to improve employee attendance with these proven strategies that have helped companies reduce absenteeism by 40%',
      'date': 'Mar 15, 2024',
      'readTime': '5 min read',
      'color': const Color(0xFF6C5CE7),
      'content':
          'Effective attendance management is crucial for business success. Start by implementing clear policies, using automated tracking systems, providing flexible work options, recognizing good attendance, and addressing issues promptly. These strategies create accountability and boost morale.',
      'takeaways': [
        'Set clear attendance expectations from day one',
        'Use biometric systems for accurate tracking',
        'Offer remote work options when possible',
        'Reward employees with perfect attendance',
        'Address chronic absenteeism early'
      ]
    },
    {
      'title': 'The Future of Remote Work',
      'description':
          'How technology is shaping the future of workplace attendance and employee engagement in a post-pandemic world',
      'date': 'Mar 10, 2024',
      'readTime': '4 min read',
      'color': const Color(0xFFFF7043),
      'content':
          'Remote work is here to stay. Companies are adopting hybrid models, investing in collaboration tools, and rethinking productivity metrics. The future focuses on outcomes rather than hours logged, with emphasis on work-life balance and mental health support.',
      'takeaways': [
        'Hybrid work models are becoming standard',
        'Digital nomad policies are emerging',
        'Virtual team building is essential',
        'Cybersecurity training for remote staff',
        'Results-based performance evaluation'
      ]
    },
    {
      'title': 'Leave Management Best Practices',
      'description':
          'Streamline your leave request process with these proven tips that save time and reduce administrative burden',
      'date': 'Mar 5, 2024',
      'readTime': '6 min read',
      'color': const Color(0xFF27AE60),
      'content':
          'Modern leave management requires automation, clear policies, and transparency. Implement self-service portals, set up automatic approval workflows, maintain real-time balance tracking, and create fair policies that accommodate different needs while ensuring business continuity.',
      'takeaways': [
        'Automate leave request workflows',
        'Provide self-service employee portals',
        'Track leave balances in real-time',
        'Create clear blackout period policies',
        'Enable mobile leave requests'
      ]
    },
    {
      'title': 'Employee Productivity Analytics',
      'description':
          'Using data to boost workplace productivity and engagement through meaningful metrics and actionable insights',
      'date': 'Feb 28, 2024',
      'readTime': '7 min read',
      'color': const Color(0xFFE74C3C),
      'content':
          'Data-driven decisions improve productivity. Track key metrics like task completion rates, project timelines, and collaboration patterns. Use analytics to identify bottlenecks, optimize workflows, and provide targeted training. Remember to balance metrics with employee privacy.',
      'takeaways': [
        'Focus on quality over quantity metrics',
        'Use predictive analytics for resource planning',
        'Implement real-time performance dashboards',
        'Conduct regular productivity reviews',
        'Protect employee data privacy'
      ]
    },
    {
      'title': 'Digital Transformation in HR',
      'description':
          'How HR tech is revolutionizing employee management from recruitment to retirement',
      'date': 'Feb 20, 2024',
      'readTime': '8 min read',
      'color': const Color(0xFF3498DB),
      'content':
          'HR technology has evolved dramatically. AI-powered recruitment, blockchain for credential verification, VR for training, and IoT for workspace optimization are transforming how we manage human resources. Stay ahead by embracing these innovations strategically.',
      'takeaways': [
        'AI automates routine HR tasks',
        'Blockchain secures employee records',
        'VR enhances training experiences',
        'IoT improves workspace efficiency',
        'Analytics drives strategic decisions'
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
      Icons.article_outlined,
      Icons.analytics_outlined,
      Icons.description_outlined,
      Icons.bar_chart_outlined,
      Icons.security_outlined,
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
          'Blogs & Articles',
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
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 1));
        },
        color: const Color(0xFF6C5CE7),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _blogs.length,
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
                    color: _blogs[index]['color'].withOpacity(0.3),
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
                    onTap: () => _showBlogDetails(_blogs[index]),
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAnimatedAvatar(_blogs[index]['color'], index),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _blogs[index]['title'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2C3E50),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _blogs[index]['description'],
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
                                      _blogs[index]['date'],
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
                                      _blogs[index]['readTime'],
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
                            Icons.article_outlined,
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
                      'Overview',
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
                      'Key Takeaways',
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
                              child: Icon(Icons.check_circle,
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
                              'Share this article with your team',
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
