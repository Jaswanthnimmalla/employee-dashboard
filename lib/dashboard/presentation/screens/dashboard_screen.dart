import 'package:employee_dashboard_app/features/auth/presentation/screens/about_screen.dart';
import 'package:employee_dashboard_app/features/auth/presentation/screens/blogs_screen.dart';
import 'package:employee_dashboard_app/features/auth/presentation/screens/contact_us_screen.dart';
import 'package:employee_dashboard_app/features/auth/presentation/screens/leave_management_screen.dart';
import 'package:employee_dashboard_app/features/auth/presentation/screens/mark_attendance_screen.dart';
import 'package:employee_dashboard_app/features/auth/presentation/screens/profile_screen.dart';
import 'package:employee_dashboard_app/features/auth/presentation/screens/settings_screen.dart';
import 'package:employee_dashboard_app/features/auth/presentation/screens/user_request_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:employee_dashboard_app/features/auth/presentation/screens/login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  String userName = 'Employee';
  String userEmail = '';
  String userRole = 'Team Member';
  String userId = '';
  String profileImageUrl = '';
  bool _isLoading = true;
  bool _isDarkMode = false;
  bool _isCheckedIn = false;
  String? _currentAttendanceId;
  DateTime? _currentCheckInTime;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
    _loadThemeMode();
    _loadUser();
    _checkCurrentAttendanceStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        _showExitDialog();
      },
      child: _buildMainContent(),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C5CE7), Color(0xFF8E2DE2), Color(0xFFFF7043)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Employee Dashboard",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Version 1.0.0",
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "© ${DateTime.now().year} All Rights Reserved",
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Exit App'),
        content: const Text('Are you sure you want to exit the app?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              SystemNavigator.pop();
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 700;
    final isSmallPhone = screenWidth < 380;

    if (_isLoading) {
      return Scaffold(
        backgroundColor:
            _isDarkMode ? const Color(0xFF0F0F1A) : const Color(0xFFF5F7FF),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _isDarkMode ? const Color(0xFF1A1A2E) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const CircularProgressIndicator(
                  color: Color(0xFF6C5CE7),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading...',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor:
          _isDarkMode ? const Color(0xFF0F0F1A) : const Color(0xFFF5F7FF),
      appBar: _buildAppBar(isTablet),
      drawer: _buildDrawer(isSmallPhone),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: () async {
            await _loadUser();
            await _checkCurrentAttendanceStatus();
          },
          color: const Color(0xFF6C5CE7),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(isTablet ? 24 : 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 100,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWelcomeCard(isTablet),
                      const SizedBox(height: 20),
                      _buildStatisticsHeader(),
                      const SizedBox(height: 12),
                      _buildRealTimeStatistics(isTablet, isSmallPhone),
                      const SizedBox(height: 24),
                      _buildQuickActions(isTablet, isSmallPhone),
                      const SizedBox(height: 24),
                      _buildExpandableSections(isTablet),
                      const SizedBox(height: 20),
                      _buildFooter(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isDarkMode = prefs.getBool('isDarkMode') ?? false;
      });
    }
  }

  Future<void> _toggleThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isDarkMode = !_isDarkMode;
        prefs.setBool('isDarkMode', _isDarkMode);
      });
    }
  }

  Future<void> _checkCurrentAttendanceStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    final query = await _firestore
        .collection('attendance')
        .where('userId', isEqualTo: user.uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();

    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      final data = doc.data();
      if (data['checkOutTime'] == null) {
        setState(() {
          _isCheckedIn = true;
          _currentAttendanceId = doc.id;
          if (data['checkInTime'] != null) {
            _currentCheckInTime = (data['checkInTime'] as Timestamp).toDate();
          }
        });
      } else {
        setState(() {
          _isCheckedIn = false;
          _currentAttendanceId = null;
          _currentCheckInTime = null;
        });
      }
    } else {
      setState(() {
        _isCheckedIn = false;
        _currentAttendanceId = null;
        _currentCheckInTime = null;
      });
    }
  }

  Future<void> _loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        userId = user.uid;
        final userDoc = await _firestore.collection('users').doc(userId).get();

        String nameFromPrefs = prefs.getString('userName') ?? '';
        String nameFromFirestore =
            userDoc.data()?['name'] ?? userDoc.data()?['username'] ?? '';
        String displayName = user.displayName ?? '';

        String finalName = 'Employee';
        if (nameFromPrefs.isNotEmpty) {
          finalName = nameFromPrefs;
        } else if (nameFromFirestore.isNotEmpty) {
          finalName = nameFromFirestore;
        } else if (displayName.isNotEmpty) {
          finalName = displayName;
        } else if (user.email != null) {
          finalName = user.email!.split('@').first;
        }

        if (mounted) {
          setState(() {
            userName = finalName;
            userEmail = prefs.getString('userEmail') ?? user.email ?? '';
            userRole = userDoc.data()?['role'] ?? 'Team Member';
            profileImageUrl =
                userDoc.data()?['profileImageUrl'] ?? 'assets/user_logo.png';
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading user: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  PreferredSizeWidget _buildAppBar(bool isTablet) {
    return AppBar(
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF6C5CE7),
              Color(0xFF8E2DE2),
              Color(0xFFFF7043),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      elevation: 4,
      centerTitle: true,
      automaticallyImplyLeading: true,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Colors.white, size: 26),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      title: Text(
        "Employee Dashboard",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: isTablet ? 24 : 21,
          letterSpacing: 0.6,
          color: Colors.white,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: () {
            setState(() {});
            _checkCurrentAttendanceStatus();
          },
        ),
        GestureDetector(
          onTap: _showProfile,
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: profileImageUrl.startsWith('http')
                  ? Image.network(
                      profileImageUrl,
                      fit: BoxFit.cover,
                      width: 44,
                      height: 44,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.white24,
                        child: const Icon(
                          Icons.person,
                          size: 28,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : profileImageUrl.startsWith('assets/')
                      ? Image.asset(
                          profileImageUrl,
                          fit: BoxFit.cover,
                          width: 44,
                          height: 44,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.white24,
                            child: const Icon(
                              Icons.person,
                              size: 28,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.white24,
                          child: const Icon(
                            Icons.person,
                            size: 28,
                            color: Colors.white,
                          ),
                        ),
            ),
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6C5CE7), Color(0xFF8E2DE2), Color(0xFFFF7043)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: UserAccountsDrawerHeader(
        decoration: const BoxDecoration(),
        accountName: Row(
          children: [
            Expanded(
              child: Text(
                userName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: 0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        accountEmail: Row(
          children: [
            Icon(Icons.email_outlined, size: 14, color: Colors.white70),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                userEmail,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        currentAccountPicture: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: profileImageUrl.startsWith('http')
                ? Image.network(
                    profileImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.white24,
                      child: const Icon(
                        Icons.person,
                        size: 45,
                        color: Colors.white,
                      ),
                    ),
                  )
                : Image.asset(
                    profileImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.white24,
                      child: const Icon(
                        Icons.person,
                        size: 45,
                        color: Colors.white,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(bool isSmallPhone) {
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      backgroundColor: _isDarkMode ? const Color(0xFF1A1A2E) : Colors.white,
      child: Column(
        children: [
          _buildDrawerHeader(),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 8),
                _buildDrawerItem(
                  Icons.dashboard_rounded,
                  "Dashboard",
                  () => Navigator.pop(context),
                  isActive: true,
                  color: const Color(0xFF6C5CE7),
                ),
                const Divider(
                    height: 24, thickness: 1, indent: 20, endIndent: 20),
                const SizedBox(height: 4),
                _buildDrawerItem(
                  Icons.person_rounded,
                  "Profile",
                  () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ProfileScreen()),
                    );
                  },
                  color: const Color(0xFF4A90E2),
                ),
                _buildDrawerItem(
                  Icons.info_rounded,
                  "About",
                  () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AboutScreen()),
                    );
                  },
                  color: const Color(0xFFF39C12),
                ),
                _buildDrawerItem(
                  Icons.article_rounded,
                  "Blogs",
                  () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const BlogsScreen()),
                    );
                  },
                  color: const Color(0xFF27AE60),
                ),
                _buildDrawerItem(
                  Icons.contact_mail_rounded,
                  "Contact Us",
                  () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ContactUsScreen()),
                    );
                  },
                  color: const Color(0xFFE74C3C),
                ),
                const Divider(
                    height: 24, thickness: 1, indent: 20, endIndent: 20),
                const SizedBox(height: 4),
                _buildDrawerItem(
                  Icons.logout_rounded,
                  "Sign Out",
                  () => _logout(),
                  isDestructive: true,
                  color: const Color(0xFFE74C3C),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isActive = false,
    bool isDestructive = false,
    Color? color,
  }) {
    final itemColor = isDestructive
        ? Colors.red
        : (isActive
            ? const Color(0xFF6C5CE7)
            : (color ??
                (_isDarkMode ? Colors.white70 : const Color(0xFF4A4A5A))));

    final bgColor = isActive
        ? (const Color(0xFF6C5CE7).withOpacity(0.1))
        : Colors.transparent;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: isActive
            ? Border.all(
                color: const Color(0xFF6C5CE7).withOpacity(0.3), width: 1)
            : null,
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: itemColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 22,
            color: itemColor,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive
                ? Colors.red
                : (isActive
                    ? const Color(0xFF6C5CE7)
                    : (_isDarkMode ? Colors.white : const Color(0xFF2C3E50))),
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
            fontSize: 15,
            letterSpacing: 0.3,
          ),
        ),
        trailing: isActive
            ? Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C5CE7), Color(0xFF8E2DE2)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.white,
                ),
              )
            : null,
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(bool isTablet) {
    final hour = DateTime.now().hour;

    String greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : hour < 21
                ? 'Good Evening'
                : 'Good Night';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 26 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF4A00E0),
            Color(0xFF8E2DE2),
            Color(0xFF6A5AE0),
            Color(0xFF00C9FF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isTablet ? 30 : 26),
        border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6A5AE0).withOpacity(0.45),
            blurRadius: 25,
            spreadRadius: 2,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 800),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: isTablet ? 75 : 65,
                  height: isTablet ? 75 : 65,
                  child: const Icon(
                    Icons.work_history_rounded,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.waving_hand_rounded,
                      color: Colors.yellowAccent,
                      size: isTablet ? 22 : 18,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "$greeting, Welcome Back",
                        style: TextStyle(
                          fontSize: isTablet ? 18 : 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: isTablet ? 22 : 18,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        userName,
                        style: TextStyle(
                          fontSize: isTablet ? 26 : 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.20),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat("hh:mm a").format(DateTime.now()),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.20),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.badge,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            userRole,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsHeader() {
    return SizedBox(
      width: double.infinity,
      child: Row(
        children: const [
          Icon(Icons.analytics_rounded, size: 22, color: Color(0xFF6C5CE7)),
          SizedBox(width: 8),
          Text(
            "Statistics Overview",
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6C5CE7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealTimeStatistics(bool isTablet, bool isSmallPhone) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('attendance')
          .where('userId', isEqualTo: user?.uid)
          .snapshots(),
      builder: (context, attendanceSnapshot) {
        int totalAttendance = attendanceSnapshot.hasData
            ? attendanceSnapshot.data!.docs.length
            : 0;

        return StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('leaves')
              .where('studentId', isEqualTo: user?.uid)
              .snapshots(),
          builder: (context, leavesSnapshot) {
            int leavesTaken = 0;
            int pendingLeaves = 0;

            if (leavesSnapshot.hasData &&
                leavesSnapshot.data!.docs.isNotEmpty) {
              for (var doc in leavesSnapshot.data!.docs) {
                final status = (doc.data() as Map<String, dynamic>)['status']
                    ?.toString()
                    .toLowerCase();
                if (status == 'approved') {
                  leavesTaken++;
                } else if (status == 'pending') {
                  pendingLeaves++;
                }
              }
            }

            return StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('requests')
                  .where('userId', isEqualTo: user?.uid)
                  .snapshots(),
              builder: (context, requestsSnapshot) {
                int pendingRequests = 0;

                if (requestsSnapshot.hasData &&
                    requestsSnapshot.data!.docs.isNotEmpty) {
                  for (var doc in requestsSnapshot.data!.docs) {
                    final status =
                        (doc.data() as Map<String, dynamic>)['status']
                            ?.toString()
                            .toLowerCase();
                    if (status == 'pending') {
                      pendingRequests++;
                    }
                  }
                }

                double spacing = isTablet ? 16 : (isSmallPhone ? 8 : 12);

                return LayoutBuilder(
                  builder: (context, constraints) {
                    bool isMobile = constraints.maxWidth < 500;

                    Widget buildGrid() {
                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: [
                          SizedBox(
                            width: isMobile
                                ? (constraints.maxWidth - spacing) / 2
                                : (constraints.maxWidth - (spacing * 3)) / 4,
                            child: _ModernStatCard(
                              title: "Total Attendance",
                              value: totalAttendance.toString(),
                              icon: Icons.calendar_month_rounded,
                              color: const Color(0xFF4A90E2),
                            ),
                          ),
                          SizedBox(
                            width: isMobile
                                ? (constraints.maxWidth - spacing) / 2
                                : (constraints.maxWidth - (spacing * 3)) / 4,
                            child: _ModernStatCard(
                              title: "Leaves Taken",
                              value: leavesTaken.toString(),
                              icon: Icons.beach_access_rounded,
                              color: const Color(0xFFF39C12),
                            ),
                          ),
                          SizedBox(
                            width: isMobile
                                ? (constraints.maxWidth - spacing) / 2
                                : (constraints.maxWidth - (spacing * 3)) / 4,
                            child: _ModernStatCard(
                              title: "Pending Leaves",
                              value: pendingLeaves.toString(),
                              icon: Icons.pending_actions,
                              color: const Color(0xFFE74C3C),
                            ),
                          ),
                          SizedBox(
                            width: isMobile
                                ? (constraints.maxWidth - spacing) / 2
                                : (constraints.maxWidth - (spacing * 3)) / 4,
                            child: _ModernStatCard(
                              title: "Pending Requests",
                              value: pendingRequests.toString(),
                              icon: Icons.request_page_rounded,
                              color: const Color(0xFF27AE60),
                            ),
                          ),
                        ],
                      );
                    }

                    return buildGrid();
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildQuickActions(bool isTablet, bool isSmallPhone) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFFF7043),
          width: 1.6,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF7043).withOpacity(0.18),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFF7043),
                      Color(0xFFFFA726),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.flash_on_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "Quick Actions",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF7043),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 500) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.camera_alt_rounded,
                            label:
                                _isCheckedIn ? "Check Out" : "Mark Attendance",
                            color: _isCheckedIn
                                ? const Color(0xFFE65100)
                                : const Color(0xFF00796B),
                            onTap: _navigateToMarkAttendance,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.beach_access_rounded,
                            label: "Apply Leave",
                            color: const Color(0xFFD32F2F),
                            onTap: _navigateToLeaveManagement,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.assignment_turned_in_rounded,
                            label: "Submit Request",
                            color: const Color(0xFF7B1FA2),
                            onTap: _navigateToUserRequest,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.check_circle_rounded,
                      label: _isCheckedIn ? "Check Out" : "Mark Attendance",
                      color: _isCheckedIn ? Colors.orange : Colors.green,
                      onTap: _navigateToMarkAttendance,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.beach_access_rounded,
                      label: "Apply Leave",
                      color: Colors.orange,
                      onTap: _navigateToLeaveManagement,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.request_page_rounded,
                      label: "Submit Request",
                      color: Colors.blue,
                      onTap: _navigateToUserRequest,
                    ),
                  ),
                ],
              );
            },
          ),
          if (_isCheckedIn && _currentCheckInTime != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.timer,
                      color: Colors.orange,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Currently Checked In',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.orange,
                          ),
                        ),
                        Text(
                          'Since ${DateFormat('hh:mm a').format(_currentCheckInTime!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _navigateToMarkAttendance,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Check Out',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _navigateToMarkAttendance() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: _ThreeDotLoader()),
    );
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) Navigator.pop(context);
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MarkAttendanceScreen()),
    );
    if (result == true && mounted) {
      await _checkCurrentAttendanceStatus();
      _showSnackBar('Attendance updated successfully!', Colors.green);
    }
  }

  void _navigateToLeaveManagement() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LeaveManagementScreen()),
    );
  }

  void _navigateToUserRequest() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UserRequestScreen()),
    );
  }

  Widget _buildExpandableSections(bool isTablet) {
    final user = FirebaseAuth.instance.currentUser;

    return Column(
      children: [
        _ExpandableSection(
          title: "Leave Details",
          icon: Icons.beach_access,
          color: const Color(0xFFF39C12),
          stream: _firestore
              .collection('leaves')
              .where('studentId', isEqualTo: user?.uid)
              .orderBy('timestamp', descending: true)
              .snapshots(),
          itemBuilder: (context, doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _ListItem(
              title: data['leaveType'] ?? 'Leave Request',
              subtitle: _formatDate(data['fromDate']),
              status: data['status'] ?? 'pending',
              color: const Color(0xFFF39C12),
              icon: Icons.event_note_rounded,
            );
          },
        ),
        const SizedBox(height: 16),
        _ExpandableSection(
          title: "Attendance Records",
          icon: Icons.calendar_month_rounded,
          color: const Color(0xFF4A90E2),
          stream: _firestore
              .collection('attendance')
              .where('userId', isEqualTo: user?.uid)
              .orderBy('date', descending: true)
              .snapshots(),
          itemBuilder: (context, doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _ListItem(
              title: data['status'] ?? 'Present',
              subtitle:
                  '${_formatDate(data['date'])} • In: ${_formatDateTime(data['checkInTime'])} • Out: ${_formatDateTime(data['checkOutTime'])}',
              status: data['status'] ?? 'Present',
              color: const Color(0xFF4A90E2),
              icon: Icons.access_time_rounded,
            );
          },
        ),
        const SizedBox(height: 16),
        _ExpandableSection(
          title: "Requests",
          icon: Icons.request_page_rounded,
          color: const Color(0xFF9B59B6),
          stream: _firestore
              .collection('requests')
              .where('userId', isEqualTo: user?.uid)
              .orderBy('timestamp', descending: true)
              .snapshots(),
          itemBuilder: (context, doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _ListItem(
              title: data['requestType'] ?? 'Request',
              subtitle: _formatDate(data['timestamp']),
              status: data['status'] ?? 'Pending',
              color: const Color(0xFF9B59B6),
              icon: Icons.request_page_rounded,
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Date not set';
    try {
      DateTime date = timestamp is Timestamp ? timestamp.toDate() : timestamp;
      return DateFormat("dd MMM yyyy").format(date);
    } catch (e) {
      return 'Date error';
    }
  }

  String _formatDateTime(dynamic timestamp) {
    if (timestamp == null) return 'Not set';
    try {
      DateTime date = timestamp is Timestamp ? timestamp.toDate() : timestamp;
      return DateFormat("hh:mm a").format(date);
    } catch (e) {
      return 'Time error';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
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

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Feature coming soon!'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _isDarkMode ? const Color(0xFF1A1A2E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notifications',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('leaves')
                    .where('studentId',
                        isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                    .orderBy('timestamp', descending: true)
                    .limit(5)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('No notifications'),
                    );
                  }
                  return ListView(
                    children: snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return _buildNotificationItem(
                        data['leaveType'] ?? 'Leave Request',
                        'Status: ${data['status']}',
                        Icons.beach_access,
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(String title, String subtitle, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            (_isDarkMode ? const Color(0xFF252540) : const Color(0xFFF0F2F8)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF6C5CE7).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF6C5CE7), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        _isDarkMode ? Colors.white54 : const Color(0xFF6B6B7B),
                  ),
                ),
              ],
            ),
          ),
          Text(
            DateFormat('MMM dd').format(DateTime.now()),
            style: TextStyle(
              color: _isDarkMode ? Colors.white54 : const Color(0xFF6B6B7B),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  void _showProfile() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            color: _isDarkMode ? const Color(0xFF1A1A2E) : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0xFF6C5CE7),
              width: 3.0, // Bold border
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C5CE7).withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 5,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: 12,
                top: 12,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _isDarkMode
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF6C5CE7),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.close,
                      color: _isDarkMode ? Colors.white : Colors.grey.shade700,
                      size: 20,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF6C5CE7),
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6C5CE7).withOpacity(0.4),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey.shade200,
                          child: profileImageUrl.startsWith('http')
                              ? Image.network(
                                  profileImageUrl,
                                  fit: BoxFit.cover,
                                  width: 100,
                                  height: 100,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.person,
                                    size: 50,
                                    color: _isDarkMode
                                        ? Colors.white
                                        : Colors.grey.shade600,
                                  ),
                                )
                              : profileImageUrl.startsWith('assets/')
                                  ? Image.asset(
                                      profileImageUrl,
                                      fit: BoxFit.cover,
                                      width: 100,
                                      height: 100,
                                      errorBuilder: (_, __, ___) => Icon(
                                        Icons.person,
                                        size: 50,
                                        color: _isDarkMode
                                            ? Colors.white
                                            : Colors.grey.shade600,
                                      ),
                                    )
                                  : Icon(
                                      Icons.person,
                                      size: 50,
                                      color: _isDarkMode
                                          ? Colors.white
                                          : Colors.grey.shade600,
                                    ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: _isDarkMode
                            ? Colors.white.withOpacity(0.05)
                            : const Color(0xFFF8FAFF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF6C5CE7).withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C5CE7).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF6C5CE7).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              color: Color(0xFF6C5CE7),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Full Name',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _isDarkMode
                                        ? Colors.white60
                                        : Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  userName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _isDarkMode
                                        ? Colors.white
                                        : const Color(0xFF1A1A2E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: _isDarkMode
                            ? Colors.white.withOpacity(0.05)
                            : const Color(0xFFF8FAFF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF4A90E2).withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4A90E2).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF4A90E2).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.email_rounded,
                              color: Color(0xFF4A90E2),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Email Address',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _isDarkMode
                                        ? Colors.white60
                                        : Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  userEmail,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: _isDarkMode
                                        ? Colors.white70
                                        : Colors.grey.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: _isDarkMode
                            ? Colors.white.withOpacity(0.05)
                            : const Color(0xFFF8FAFF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFF39C12).withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF39C12).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFF39C12).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.work_rounded,
                              color: Color(0xFFF39C12),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Role',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _isDarkMode
                                        ? Colors.white60
                                        : Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF39C12)
                                        .withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFF39C12)
                                          .withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    userRole,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFF39C12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              // Navigate to edit profile screen
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF6C5CE7),
                                    Color(0xFF8E2DE2)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF6C5CE7)
                                        .withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.edit_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Edit Profile',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _isDarkMode
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFF6C5CE7),
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                'Close',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _isDarkMode
                                      ? Colors.white
                                      : const Color(0xFF6C5CE7),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _isDarkMode ? const Color(0xFF1A1A2E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(
                'Dark Mode',
                style: TextStyle(
                  color: _isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
              value: _isDarkMode,
              onChanged: (value) {
                Navigator.pop(context);
                _toggleThemeMode();
              },
            ),
            SwitchListTile(
              title: Text(
                'Push Notifications',
                style: TextStyle(
                  color: _isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
              value: true,
              onChanged: (value) {},
            ),
            ListTile(
              leading: Icon(
                Icons.language,
                color: _isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
              ),
              title: Text(
                'Language',
                style: TextStyle(
                  color: _isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
              trailing: Text(
                'English',
                style: TextStyle(
                  color: _isDarkMode ? Colors.white54 : const Color(0xFF6B6B7B),
                ),
              ),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'Employee Dashboard',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.dashboard,
        size: 40,
        color: Color(0xFF6C5CE7),
      ),
      children: const [
        Text('A modern employee management dashboard with real-time updates.'),
      ],
    );
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Sign Out",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text("Are you sure you want to sign out?"),
        actions: [
          TextButton(
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("Sign Out"),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              await FirebaseAuth.instance.signOut();
              if (mounted)
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
            },
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _ModernStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _ModernStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 95,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 26, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.6), width: 1.4),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.18),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 26, color: color),
              const SizedBox(height: 6),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpandableSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Stream<QuerySnapshot> stream;
  final Widget Function(BuildContext, DocumentSnapshot) itemBuilder;

  const _ExpandableSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.stream,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.55), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          collapsedIconColor: color,
          iconColor: color,
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color, width: 1.2),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? const Color(0xFF252540)
                    : const Color(0xFFF4F7FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.45)),
              ),
              child: StreamBuilder<QuerySnapshot>(
                stream: stream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: SizedBox(
                          height: 30,
                          width: 30,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Text(
                          'Error loading data',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Text(
                          'No data available',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) =>
                        itemBuilder(context, snapshot.data!.docs[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? status;
  final Color color;
  final IconData icon;
  final bool showStatus;
  const _ListItem({
    required this.title,
    required this.subtitle,
    this.status,
    required this.color,
    required this.icon,
    this.showStatus = true,
  });

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
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

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF252540) : const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          if (showStatus && status != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: getStatusColor(status!).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: getStatusColor(status!).withOpacity(0.3),
                ),
              ),
              child: Text(
                status!.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: getStatusColor(status!),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ThreeDotLoader extends StatefulWidget {
  const _ThreeDotLoader({super.key});

  @override
  State<_ThreeDotLoader> createState() => _ThreeDotLoaderState();
}

class _ThreeDotLoaderState extends State<_ThreeDotLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _dot(double delay) {
    return FadeTransition(
      opacity: Tween(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Interval(delay, 1.0)),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 7),
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: const Color(0xFFFFA726),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 21, 9, 9).withOpacity(0.6),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [_dot(0.0), _dot(0.3), _dot(0.6)],
      ),
    );
  }
}
