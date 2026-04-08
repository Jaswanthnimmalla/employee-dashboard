import 'package:employee_dashboard_app/admin/data/presentation/provider/admin_provider.dart';
import 'package:employee_dashboard_app/admin/data/presentation/screens/admin_about_screen.dart';
import 'package:employee_dashboard_app/admin/data/presentation/screens/admin_blogs_screen.dart';
import 'package:employee_dashboard_app/admin/data/presentation/screens/admin_contact_us_screen.dart';
import 'package:employee_dashboard_app/admin/data/presentation/screens/admin_profile_screen.dart';
import 'package:employee_dashboard_app/admin/data/presentation/screens/attendance_statistics_screen.dart';
import 'package:employee_dashboard_app/admin/data/presentation/screens/manage_attendance_screen.dart';
import 'package:employee_dashboard_app/admin/data/presentation/screens/manage_employees_screen.dart';
import 'package:employee_dashboard_app/admin/data/presentation/screens/manage_leave_requests_screen.dart';
import 'package:employee_dashboard_app/admin/data/presentation/screens/manage_requests_screen.dart';
import 'package:employee_dashboard_app/admin/data/presentation/screens/reports_screen.dart';
import 'package:employee_dashboard_app/core/utils/attendance_time_logic.dart';
import 'package:employee_dashboard_app/features/auth/presentation/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  String adminName = '';
  String adminEmail = '';
  String profileImageUrl = '';
  String userRole = 'Admin';
  bool _isLoadingProfile = true; // ADD THIS LINE
  final Color _adminColor = const Color(0xFFE74C3C);
  final Color _backgroundColor = const Color(0xFFF5F6FA);
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late List<Widget> _screens;
  late List<String> _titles;

  @override
  void initState() {
    super.initState();
    _initializeScreens();
    _loadAdminData();
  }

  void _initializeScreens() {
    _screens = [
      const _DashboardHome(),
      const ManageEmployeesScreen(),
      const ManageAttendanceScreen(),
      const ManageLeaveRequestScreen(),
      const ManageRequestsScreen(),
      const ReportsScreen(),
    ];
    _titles = [
      'Admin Dashboard',
      'Manage Employees',
      'Manage Attendance',
      'Leave Requests',
      'Manage Requests',
      'Reports',
    ];
  }

  Future<void> _loadAdminData() async {
    setState(() {
      _isLoadingProfile = true;
    });

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        _isLoadingProfile = false;
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('Admin')
          .doc(user.uid)
          .get();

      print("IMAGE URL: ${doc.data()?['profileImageUrl']}");

      if (mounted) {
        setState(() {
          adminName = (doc.data()?['name'] ?? 'Admin').toString();
          userRole = (doc.data()?['role'] ?? 'Admin').toString();
          profileImageUrl =
              (doc.data()?['profileImageUrl'] ?? '').toString().trim();
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      print('Error loading admin data: $e');
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  Widget _buildProfileImage() {
    if (_isLoadingProfile) {
      return Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.2),
        ),
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: ClipOval(
        child: profileImageUrl.trim().isNotEmpty
            ? Image.network(
                profileImageUrl.trim(),
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.white.withOpacity(0.2),
                    child: const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 22,
                  );
                },
              )
            : const Icon(
                Icons.person,
                color: Colors.white,
                size: 22,
              ),
      ),
    );
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Sign Out"),
        content: const Text("Are you sure you want to sign out?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Sign Out"),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 600;
    final isTablet = size.width >= 600 && size.width < 1200;

    return ChangeNotifierProvider(
      create: (context) => AdminProvider()..refresh(),
      child: PopScope(
        canPop: false,
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: _backgroundColor,
          appBar: _buildAppBar(isSmall),
          drawer: isSmall ? _buildDrawer() : null,
          body: Row(
            children: [
              if (!isSmall)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: NavigationRail(
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: (index) {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    labelType: isTablet
                        ? NavigationRailLabelType.all
                        : NavigationRailLabelType.selected,
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.dashboard_outlined),
                        selectedIcon: Icon(Icons.dashboard),
                        label: Text('Home'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.people_outline),
                        selectedIcon: Icon(Icons.people),
                        label: Text('Employees'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.fingerprint_outlined),
                        selectedIcon: Icon(Icons.fingerprint),
                        label: Text('Attendance'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.event_note_outlined),
                        selectedIcon: Icon(Icons.event_note),
                        label: Text('Leaves'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.request_page_outlined),
                        selectedIcon: Icon(Icons.request_page),
                        label: Text('Requests'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.bar_chart_outlined),
                        selectedIcon: Icon(Icons.bar_chart),
                        label: Text('Reports'),
                      ),
                    ],
                    backgroundColor: Colors.white,
                    selectedIconTheme:
                        const IconThemeData(color: Color(0xFFE74C3C)),
                    unselectedIconTheme:
                        const IconThemeData(color: Colors.grey),
                    selectedLabelTextStyle: const TextStyle(
                      color: Color(0xFFE74C3C),
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelTextStyle: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ),
              Expanded(
                child: _screens[_selectedIndex],
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isSmall) {
    return AppBar(
      automaticallyImplyLeading: false,
      leading: isSmall
          ? IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            )
          : null,
      centerTitle: true,
      elevation: 6,
      backgroundColor: const Color(0xFFC0392B),
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
      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            _titles[_selectedIndex],
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      actions: [
        /// PROFILE PHOTO MENU
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'logout') _logout();
          },
          offset: const Offset(0, 50),
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Material(
              elevation: 4,
              shadowColor: Colors.black.withOpacity(0.3),
              shape: const CircleBorder(),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: profileImageUrl.trim().isNotEmpty
                      ? Image.network(
                          profileImageUrl.trim(),
                          fit: BoxFit.cover,
                          width: 48,
                          height: 48,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.white.withOpacity(0.2),
                              child: const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.white.withOpacity(0.2),
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 32,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.white.withOpacity(0.2),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                ),
              ),
            ),
          ),
          itemBuilder: (context) => [
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(
                    Icons.logout,
                    size: 20,
                    color: Colors.red,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Logout',
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('leaves')
              .where('status', isEqualTo: 'pending')
              .snapshots(),
          builder: (context, snapshot) {
            final pendingCount = snapshot.data?.docs.length ?? 0;

            return Container(
              padding: const EdgeInsets.all(20),
              height: 400,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      children: [
                        if (pendingCount > 0)
                          ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFE74C3C),
                              child: Icon(Icons.event_note,
                                  size: 20, color: Colors.white),
                            ),
                            title: const Text('Pending Leave Requests'),
                            subtitle: Text(
                              '$pendingCount requests awaiting approval',
                            ),
                            trailing: Text(
                                DateFormat('hh:mm a').format(DateTime.now())),
                          ),
                        const Divider(),
                        _buildRequestNotification(context),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF6C5CE7),
                  Color(0xFF8E2DE2),
                  Color(0xFFFF7043)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                // Profile Image
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: profileImageUrl.trim().isNotEmpty
                        ? Image.network(
                            profileImageUrl.trim(),
                            fit: BoxFit.cover,
                            width: 90,
                            height: 90,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.white24,
                              child: const Icon(
                                Icons.admin_panel_settings,
                                color: Colors.white,
                                size: 45,
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.white24,
                            child: const Icon(
                              Icons.admin_panel_settings,
                              color: Colors.white,
                              size: 45,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  adminName.isEmpty ? 'Admin User' : adminName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Administrator',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Email
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.email_outlined, size: 12, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      adminEmail.isEmpty ? 'admin@example.com' : adminEmail,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 8),
                _buildDrawerItem(
                  Icons.dashboard_rounded,
                  'Dashboard',
                  () {
                    setState(() {
                      _selectedIndex = 0;
                    });
                    Navigator.pop(context);
                  },
                  isActive: _selectedIndex == 0,
                ),
                _buildDrawerItem(
                  Icons.people_rounded,
                  'Manage Employees',
                  () {
                    setState(() {
                      _selectedIndex = 1;
                    });
                    Navigator.pop(context);
                  },
                  isActive: _selectedIndex == 1,
                ),
                _buildDrawerItem(
                  Icons.fingerprint_rounded,
                  'Manage Attendance',
                  () {
                    setState(() {
                      _selectedIndex = 2;
                    });
                    Navigator.pop(context);
                  },
                  isActive: _selectedIndex == 2,
                ),
                _buildDrawerItem(
                  Icons.analytics_rounded,
                  'Attendance Statistics',
                  () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const AttendanceStatisticsScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  Icons.event_note_rounded,
                  'Leave Requests',
                  () {
                    setState(() {
                      _selectedIndex = 3;
                    });
                    Navigator.pop(context);
                  },
                  isActive: _selectedIndex == 3,
                ),
                _buildDrawerItem(
                  Icons.request_page_rounded,
                  'Manage Requests',
                  () {
                    setState(() {
                      _selectedIndex = 4;
                    });
                    Navigator.pop(context);
                  },
                  isActive: _selectedIndex == 4,
                ),
                _buildDrawerItem(
                  Icons.bar_chart_rounded,
                  'Reports',
                  () {
                    setState(() {
                      _selectedIndex = 5;
                    });
                    Navigator.pop(context);
                  },
                  isActive: _selectedIndex == 5,
                ),
                const Divider(
                    height: 24, thickness: 1, indent: 20, endIndent: 20),
                _buildDrawerItem(
                  Icons.person_rounded,
                  'Profile',
                  () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AdminProfileScreen()),
                    );
                  },
                ),
                _buildDrawerItem(
                  Icons.article_rounded,
                  'Blogs',
                  () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AdminBlogsScreen()),
                    );
                  },
                ),
                _buildDrawerItem(
                  Icons.contact_mail_rounded,
                  'Contact Us',
                  () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AdminContactUsScreen()),
                    );
                  },
                ),
                _buildDrawerItem(
                  Icons.info_rounded,
                  'About',
                  () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AdminAboutScreen()),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.all(16),
            child: InkWell(
              onTap: _logout,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE74C3C), Color(0xFFC0392B)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE74C3C).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap,
      {bool isActive = false}) {
    final Color itemColor =
        isActive ? const Color(0xFF6C5CE7) : Colors.grey.shade700;
    final Color bgColor = isActive
        ? const Color(0xFF6C5CE7).withOpacity(0.1)
        : Colors.transparent;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: isActive
            ? Border.all(
                color: const Color(0xFF6C5CE7).withOpacity(0.3), width: 1)
            : null,
      ),
      child: ListTile(
        leading: Icon(icon, color: itemColor, size: 22),
        title: Text(
          title,
          style: TextStyle(
            color: itemColor,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        trailing: isActive
            ? Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF6C5CE7),
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _buildRequestNotification(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('requests')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        final pendingCount = snapshot.data?.docs.length ?? 0;

        if (pendingCount == 0) return const SizedBox.shrink();

        return ListTile(
          leading: const CircleAvatar(
            backgroundColor: Color(0xFF9B59B6),
            child: Icon(Icons.request_page, size: 20, color: Colors.white),
          ),
          title: const Text('Pending User Requests'),
          subtitle: Text('$pendingCount requests need your attention'),
          trailing: Text(DateFormat('MMM dd').format(DateTime.now())),
        );
      },
    );
  }
}

class _DashboardHome extends StatefulWidget {
  const _DashboardHome();

  @override
  State<_DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<_DashboardHome> {
  String profileImageUrl = '';
  String adminName = '';
  String userRole = 'Admin';

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('Admin')
        .doc(user.uid)
        .get();

    if (mounted) {
      setState(() {
        adminName = (doc.data()?['name'] ?? 'Admin').toString();
        userRole = (doc.data()?['role'] ?? 'Admin').toString();
        profileImageUrl =
            (doc.data()?['profileImageUrl'] ?? '').toString().trim();
      });
    }
  }

  Future<void> _navigateWithLoader(
    BuildContext context,
    Widget screen,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: _ThreeDotLoader()),
    );

    await Future.delayed(const Duration(milliseconds: 500));

    if (context.mounted) Navigator.pop(context);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: Provider.of<AdminProvider>(
            context,
            listen: false,
          ),
          child: screen,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return RefreshIndicator(
      onRefresh: () async {
        final provider = Provider.of<AdminProvider>(context, listen: false);
        provider.refresh();
      },
      color: const Color(0xFFE74C3C),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(size.width < 600 ? 12 : 16),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: size.width < 1200 ? size.width - 32 : 1200,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeHeader(size),
                const SizedBox(height: 20),
                _buildStatsOverview(),
                const SizedBox(height: 20),
                _buildFeatureGrid(context),
                const SizedBox(height: 20),
                _buildRecentActivity(size),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(Size size) {
    final currentHour = DateTime.now().hour;
    String greeting = 'Good Evening';

    if (currentHour < 12) {
      greeting = 'Good Morning';
    } else if (currentHour < 17) {
      greeting = 'Good Afternoon';
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(size.width < 600 ? 16 : 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF6C5CE7),
            Color(0xFF8E2DE2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      "👋",
                      style: TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        "$greeting, Welcome Back",
                        style: TextStyle(
                          fontSize: size.width < 600 ? 16 : 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.95),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 26,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        adminName,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: size.width < 600 ? 26 : 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 14,
                  runSpacing: 10,
                  children: [
                    /// TIME CHIP
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.6),
                        ),
                        color: Colors.white.withOpacity(0.12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('hh:mm a').format(DateTime.now()),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.6),
                        ),
                        color: Colors.white.withOpacity(0.12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.admin_panel_settings,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Admin",
                            style: TextStyle(
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
          Container(
            margin: const EdgeInsets.only(left: 12),
            padding: EdgeInsets.all(size.width < 600 ? 16 : 20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.dashboard_customize,
              color: Colors.white,
              size: size.width < 600 ? 36 : 46,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid(BuildContext context) {
    final features = [
      {
        'title': 'Employees',
        'icon': Icons.people,
        'color': const Color(0xFF3498DB),
        'screen': const ManageEmployeesScreen()
      },
      {
        'title': 'Attendance',
        'icon': Icons.fingerprint,
        'color': const Color(0xFF27AE60),
        'screen': const ManageAttendanceScreen()
      },
      {
        'title': 'Leave',
        'icon': Icons.event_note,
        'color': const Color(0xFFF39C12),
        'screen': const ManageLeaveRequestScreen()
      },
      {
        'title': 'Requests',
        'icon': Icons.request_page,
        'color': const Color(0xFF9B59B6),
        'screen': const ManageRequestsScreen()
      },
      {
        'title': 'Reports',
        'icon': Icons.bar_chart,
        'color': const Color(0xFFE74C3C),
        'screen': const ReportsScreen()
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text(
            "Quick Actions",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.of(context).size.width < 600 ? 2 : 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          itemCount: 4,
          itemBuilder: (context, index) {
            final feature = features[index];
            return _featureCard(
              context,
              feature['title'] as String,
              feature['icon'] as IconData,
              feature['color'] as Color,
              feature['screen'] as Widget,
            );
          },
        ),
        const SizedBox(height: 12),
        _horizontalFeatureCard(
          context,
          features[4]['title'] as String,
          features[4]['icon'] as IconData,
          features[4]['color'] as Color,
          features[4]['screen'] as Widget,
        ),
      ],
    );
  }

  Widget _featureCard(BuildContext context, String title, IconData icon,
      Color color, Widget screen) {
    return InkWell(
      onTap: () {
        _navigateWithLoader(context, screen);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color,
              color.withOpacity(0.85),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'OPEN',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF2C3E50),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward,
                    color: Color(0xFFE74C3C),
                    size: 11,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _horizontalFeatureCard(BuildContext context, String title,
      IconData icon, Color color, Widget screen) {
    return InkWell(
      onTap: () {
        _navigateWithLoader(context, screen);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              color,
              color.withOpacity(0.85),
              color.withOpacity(0.75),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            "View detailed analytics & insights",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.95),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Text(
                      "OPEN",
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFE74C3C),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward,
                      color: Color(0xFFE74C3C),
                      size: 14,
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

  Widget _buildStatsOverview() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Team Member')
          .snapshots(),
      builder: (context, employeeSnapshot) {
        if (!employeeSnapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final employees = employeeSnapshot.data!.docs;
        final totalEmployees = employees.length;

        final now = DateTime.now();

        final startOfDay = DateTime(
          now.year,
          now.month,
          now.day,
        );

        final endOfDay = DateTime(
          now.year,
          now.month,
          now.day,
          23,
          59,
          59,
        );

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('attendance')
              .where(
                'date',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
              )
              .where(
                'date',
                isLessThanOrEqualTo: Timestamp.fromDate(endOfDay),
              )
              .snapshots(),
          builder: (context, attendanceSnapshot) {
            if (!attendanceSnapshot.hasData) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final attendanceDocs = attendanceSnapshot.data!.docs;
            final Map<String, String> employeeStatus = {};

            for (final employee in employees) {
              employeeStatus[employee.id] = 'Absent';
            }

            for (final doc in attendanceDocs) {
              final userId = doc.get('userId');

              if (!employeeStatus.containsKey(userId)) {
                continue;
              }

              if (doc.get('checkInTime') != null) {
                final checkIn = (doc.get('checkInTime') as Timestamp).toDate();

                final data = doc.data() as Map<String, dynamic>;

                final status = data['status']?.toString() ?? 'Absent';

                employeeStatus[userId] = status;
              }
            }

            int presentToday = 0;
            int lateToday = 0;
            int veryLateToday = 0;
            int halfDayToday = 0;
            int absentToday = 0;

            final now = DateTime.now();

            final cutoff = DateTime(
              now.year,
              now.month,
              now.day,
              11,
              40,
            );

            for (final status in employeeStatus.values) {
              switch (status) {
                case 'Present':
                  presentToday++;
                  break;

                case 'Late':
                  lateToday++;
                  break;

                case 'Very Late':
                  veryLateToday++;
                  break;

                case 'Half Day':
                  halfDayToday++;
                  break;

                case 'Absent':
                  absentToday++;
                  break;

                default:
                  break;
              }
            }

            final totalEmployeesCount = employeeSnapshot.data?.docs
                    .map((doc) => doc.id)
                    .toSet()
                    .length ??
                0;

            final attendedCount =
                presentToday + lateToday + veryLateToday + halfDayToday;

            double attendanceRate = totalEmployeesCount > 0
                ? (attendedCount / totalEmployeesCount) * 100
                : 0.0;

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('leaves')
                  .where('status', isEqualTo: 'Approved')
                  .snapshots(),
              builder: (context, approvedLeaveSnapshot) {
                final today = DateTime.now();
                final todayStart = DateTime(today.year, today.month, today.day);
                final todayEnd =
                    DateTime(today.year, today.month, today.day, 23, 59, 59);

                int onLeaveToday = 0;
                if (approvedLeaveSnapshot.hasData) {
                  for (var doc in approvedLeaveSnapshot.data!.docs) {
                    final fromDate = doc.get('fromDate') as Timestamp?;
                    final toDate = doc.get('toDate') as Timestamp?;

                    if (fromDate != null && toDate != null) {
                      final from = fromDate.toDate();
                      final to = toDate.toDate();

                      if ((from.isBefore(todayEnd) && to.isAfter(todayStart)) ||
                          (from.day == today.day &&
                              from.month == today.month &&
                              from.year == today.year) ||
                          (to.day == today.day &&
                              to.month == today.month &&
                              to.year == today.year)) {
                        onLeaveToday++;
                      }
                    }
                  }
                }

                absentToday = absentToday - onLeaveToday;

                if (absentToday < 0) {
                  absentToday = 0;
                }

                if (absentToday < 0) {
                  absentToday = 0;
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('leaves')
                      .snapshots(),
                  builder: (context, allLeavesSnapshot) {
                    final docs = allLeavesSnapshot.data?.docs ?? [];

                    int approvedLeaves = docs.where((doc) {
                      final status = doc.get('status').toString().toLowerCase();
                      return status == 'approved';
                    }).length;

                    int pendingLeaves = docs.where((doc) {
                      final status = doc.get('status').toString().toLowerCase();
                      return status == 'pending';
                    }).length;

                    int rejectedLeaves = docs.where((doc) {
                      final status = doc.get('status').toString().toLowerCase();
                      return status == 'rejected';
                    }).length;

                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('requests')
                          .snapshots(),
                      builder: (context, requestsSnapshot) {
                        final pendingRequests =
                            requestsSnapshot.data?.docs.where((doc) {
                                  final status = doc
                                      .get('status')
                                      .toString()
                                      .toLowerCase();
                                  return status == 'pending';
                                }).length ??
                                0;

                        return LayoutBuilder(
                          builder: (context, constraints) {
                            double width = constraints.maxWidth;
                            int crossAxisCount = 2;

                            if (width > 1100) {
                              crossAxisCount = 4;
                            } else if (width > 700) {
                              crossAxisCount = 3;
                            }

                            final statsItems = [
                              _statItem(
                                "Total Employees",
                                totalEmployeesCount.toString(),
                                Icons.people_alt,
                                const Color(0xFF3498DB),
                              ),
                              _statItem(
                                "Present Today",
                                presentToday.toString(),
                                Icons.check_circle,
                                const Color(0xFF27AE60),
                              ),
                              _statItem(
                                "Absent Today",
                                absentToday.toString(),
                                Icons.cancel,
                                Colors.red,
                              ),
                              _statItem(
                                "Late Today",
                                lateToday.toString(),
                                Icons.access_time,
                                Colors.orange,
                              ),
                              _statItem(
                                "Very Late",
                                veryLateToday.toString(),
                                Icons.watch_later,
                                Colors.deepOrange,
                              ),
                              _statItem(
                                "Half Day",
                                halfDayToday.toString(),
                                Icons.hourglass_bottom,
                                Colors.purple,
                              ),
                              _statItem(
                                "On Leave Today",
                                onLeaveToday.toString(),
                                Icons.beach_access,
                                const Color(0xFFF39C12),
                              ),
                              _statItem(
                                "Approved Leaves",
                                approvedLeaves.toString(),
                                Icons.check_circle_outline,
                                Colors.green,
                              ),
                              _statItem(
                                "Pending Leaves",
                                pendingLeaves.toString(),
                                Icons.pending_actions,
                                Colors.orange,
                              ),
                              _statItem(
                                "Rejected Leaves",
                                rejectedLeaves.toString(),
                                Icons.cancel,
                                Colors.red,
                              ),
                            ];

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 12),
                                  child: Text(
                                    "Statistics Overview",
                                    style: TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2C3E50),
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: statsItems.length,
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    childAspectRatio: 2.0,
                                  ),
                                  itemBuilder: (context, index) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                          width: 1.4,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.06),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: statsItems[index],
                                    );
                                  },
                                ),
                                const SizedBox(height: 14),
                                const SizedBox(height: 14),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFF9B59B6),
                                      width: 1.6,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF9B59B6)
                                            .withOpacity(0.10),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF9B59B6)
                                              .withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: const Color(0xFF9B59B6)
                                                .withOpacity(0.4),
                                            width: 1,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.request_page,
                                          color: Color(0xFF9B59B6),
                                          size: 26,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            pendingRequests.toString(),
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF2C3E50),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            "Pending Requests",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.black54,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.teal.shade300,
                                      width: 1.6,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.teal.withOpacity(0.08),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: _attendanceRateCard(attendanceRate),
                                ),
                                const SizedBox(height: 6),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _statItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 1.2,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
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

  Widget _attendanceRateCard(double rate) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF9B59B6),
            Color(0xFF8E44AD),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.purple,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Attendance Rate",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${rate.toStringAsFixed(1)}%",
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: rate / 100,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(
            Icons.trending_up,
            color: Colors.white,
            size: 36,
          ),
        ],
      ),
    );
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

  Widget _buildRecentActivity(Size size) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.blueGrey.withOpacity(0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.notifications_active,
                color: Colors.red,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                "Recent Activity",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('leaves')
                .orderBy('timestamp', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        "Failed to load activity",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                );
              }

              final docs = snapshot.data!.docs;

              if (docs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.history, color: Colors.grey),
                      SizedBox(width: 8),
                      Text(
                        "No recent activity",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  final leaveType = data['leaveType'] ?? 'Leave';

                  final status = data['status'] ?? 'pending';

                  Color statusColor;

                  if (status == 'approved') {
                    statusColor = Colors.green;
                  } else if (status == 'rejected') {
                    statusColor = Colors.red;
                  } else {
                    statusColor = Colors.orange;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: statusColor.withOpacity(0.35),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
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
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: statusColor.withOpacity(0.4),
                            ),
                          ),
                          child: Icon(
                            status == 'approved'
                                ? Icons.check_circle
                                : status == 'rejected'
                                    ? Icons.cancel
                                    : Icons.pending_actions,
                            color: statusColor,
                            size: 18,
                          ),
                        ),

                        const SizedBox(width: 10),

                        /// TEXT
                        Expanded(
                          child: Text(
                            "$leaveType request — Status: ${status.toUpperCase()}",
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                        ),

                        /// STATUS DOT
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _blinkingDot([bool isActive = true]) {
    if (!isActive) {
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: Colors.grey,
          shape: BoxShape.circle,
        ),
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
      onEnd: () {},
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
        CurvedAnimation(
          parent: _controller,
          curve: Interval(delay, 1.0),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 7),
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: const Color(0xFFE74C3C),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _dot(0.0),
          _dot(0.3),
          _dot(0.6),
        ],
      ),
    );
  }
}
