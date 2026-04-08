import 'package:employee_dashboard_app/admin/data/presentation/screens/admin_dashboard_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ManageLeaveRequestScreen extends StatefulWidget {
  const ManageLeaveRequestScreen({super.key});

  @override
  State<ManageLeaveRequestScreen> createState() =>
      _ManageLeaveRequestScreenState();
}

class _ManageLeaveRequestScreenState extends State<ManageLeaveRequestScreen> {
  String searchText = "";
  String selectedFilter = "All";
  final filters = ["All", "Pending", "Approved", "Rejected"];
  String userId = '';
  String userName = '';
  bool isAdmin = false;

  final ScrollController _scrollController = ScrollController();
  final Map<String, QueryDocumentSnapshot> _leaveCache = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _leaveCache.clear();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (mounted) {
        setState(() {
          userId = user.uid;
          userName = userDoc.data()?['name'] ?? user.displayName ?? 'Employee';

          isAdmin =
              (userDoc.data()?['role']?.toString().toLowerCase() == 'admin');
        });
      }
    }
  }

  Future<void> updateStatus(String id, String status) async {
    try {
      await FirebaseFirestore.instance.collection("leaves").doc(id).update({
        "status": status,
        "reviewedAt": FieldValue.serverTimestamp(),
        "reviewedBy": userId,
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Leave $status"),
            backgroundColor:
                status == "Approved" ? Colors.teal : Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      debugPrint("Update error: $e");
    }
  }

  Future<void> deleteLeave(String id) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Leave Request'),
        content: const Text(
            'Are you sure you want to delete this leave request? This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseFirestore.instance
                    .collection('leaves')
                    .doc(id)
                    .delete();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Leave request deleted successfully'),
                      backgroundColor: Colors.teal,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelLeaveRequest(String id) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Leave Request'),
        content:
            const Text('Are you sure you want to cancel this leave request?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('No')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseFirestore.instance
                    .collection('leaves')
                    .doc(id)
                    .delete();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            const Text('Leave request cancelled successfully'),
                        backgroundColor: Colors.teal,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                  );
                }
              }
            },
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void _applyLeave() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: const Text('Apply Leave feature coming soon'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    );
  }

  Future<void> openProof(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("Open error: $e");
    }
  }

  Color statusColor(String status) {
    switch (status) {
      case "Approved":
        return Colors.teal;
      case "Rejected":
        return Colors.redAccent;
      default:
        return Colors.orange;
    }
  }

  String formatDate(Timestamp? timestamp) {
    if (timestamp == null) return "Unknown";
    return DateFormat('dd MMM yyyy').format(timestamp.toDate());
  }

  String formatDateTime(Timestamp? timestamp) {
    if (timestamp == null) return "Unknown";
    return DateFormat('dd MMM yyyy, hh:mm a').format(timestamp.toDate());
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    bool isLink = false,
    VoidCallback? onTap,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                if (isLink)
                  GestureDetector(
                    onTap: onTap,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: color,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  )
                else
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProofCard(String proofUrl) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.red.shade50, Colors.red.shade100.withOpacity(0.3)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attachment, color: Colors.red.shade800, size: 20),
              const SizedBox(width: 8),
              Text(
                "Supporting Document",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.visibility, color: Colors.white, size: 20),
              label: const Text(
                "View Proof",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade800,
                foregroundColor: Colors.white,
                elevation: 2,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => openProof(proofUrl),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        onPressed: onPressed,
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: color,
          fontSize: 12,
        ),
      ),
    );
  }

  void _showLeaveDetailsDialog({
    required String studentName,
    required String reason,
    required String status,
    required Timestamp? fromDate,
    required Timestamp? toDate,
    required Timestamp? timestamp,
    required int daysCount,
    required String leaveType,
    required String? proofUrl,
    required String leaveId,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.teal.shade400,
                                Colors.teal.shade800
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: const Icon(Icons.beach_access,
                              color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Leave Request Details",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal,
                                ),
                              ),
                              const SizedBox(height: 4),
                              _statusBadge(status),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (isAdmin && studentName.isNotEmpty)
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.blue.shade400,
                            width: 2,
                          ),
                        ),
                        child: _buildDetailCard(
                          icon: Icons.person,
                          title: "Student Name",
                          value: studentName,
                          color: Colors.blue,
                        ),
                      ),
                    if (isAdmin && studentName.isNotEmpty)
                      const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.purple.shade400,
                          width: 2,
                        ),
                      ),
                      child: _buildDetailCard(
                        icon: Icons.category,
                        title: "Leave Type",
                        value: leaveType,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.orange.shade400,
                          width: 2,
                        ),
                      ),
                      child: _buildDetailCard(
                        icon: Icons.notes,
                        title: "Reason",
                        value: reason,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.green.shade400,
                          width: 2,
                        ),
                      ),
                      child: _buildDetailCard(
                        icon: Icons.date_range,
                        title: "Date Range",
                        value: fromDate != null && toDate != null
                            ? '${formatDate(fromDate)} - ${formatDate(toDate)}'
                            : formatDate(timestamp),
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.teal.shade400,
                          width: 2,
                        ),
                      ),
                      child: _buildDetailCard(
                        icon: Icons.calendar_today,
                        title: "Duration",
                        value: '$daysCount day${daysCount > 1 ? 's' : ''}',
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.cyan.shade400,
                          width: 2,
                        ),
                      ),
                      child: _buildDetailCard(
                        icon: Icons.access_time,
                        title: "Applied On",
                        value: formatDateTime(timestamp),
                        color: Colors.cyan,
                      ),
                    ),
                    if (proofUrl != null && proofUrl.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildProofCard(proofUrl),
                    ],
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.teal.shade800,
                          width: 2,
                        ),
                        color: Colors.teal.shade50,
                      ),
                      child: Column(
                        children: [
                          if (isAdmin) ...[
                            if (status == "Pending") ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: _buildActionButton(
                                        icon: Icons.check_circle,
                                        label: "Approve",
                                        color: Colors.teal,
                                        onPressed: () {
                                          Navigator.pop(context);
                                          updateStatus(leaveId, "Approved");
                                        },
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: _buildActionButton(
                                        icon: Icons.cancel,
                                        label: "Reject",
                                        color: Colors.orange,
                                        onPressed: () {
                                          Navigator.pop(context);
                                          updateStatus(leaveId, "Rejected");
                                        },
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildActionButton(
                                      icon: Icons.delete,
                                      label: "Delete",
                                      color: Colors.grey,
                                      onPressed: () {
                                        Navigator.pop(context);
                                        deleteLeave(leaveId);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.close),
                                  label: const Text("Close"),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.teal.shade800,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    side: BorderSide(
                                      color: Colors.teal.shade800,
                                      width: 1.5,
                                    ),
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),
                            ] else ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: _buildActionButton(
                                        icon: Icons.delete,
                                        label: "Delete",
                                        color: Colors.grey,
                                        onPressed: () {
                                          Navigator.pop(context);
                                          deleteLeave(leaveId);
                                        },
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.close),
                                      label: const Text("Close"),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.teal.shade800,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        side: BorderSide(
                                          color: Colors.teal.shade800,
                                          width: 1.5,
                                        ),
                                      ),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ] else if (!isAdmin && status == "Pending") ...[
                            Row(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: _buildActionButton(
                                      icon: Icons.cancel,
                                      label: "Cancel Request",
                                      color: Colors.redAccent,
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _cancelLeaveRequest(leaveId);
                                      },
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.close),
                                    label: const Text("Close"),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.teal.shade800,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      side: BorderSide(
                                        color: Colors.teal.shade800,
                                        width: 1.5,
                                      ),
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ),
                              ],
                            ),
                          ] else if (!isAdmin && status != "Pending") ...[
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.close),
                                label: const Text("Close"),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.teal.shade800,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: BorderSide(
                                    color: Colors.teal.shade800,
                                    width: 1.5,
                                  ),
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "Leave Management",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
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
                const Color(0xFF00897B).withOpacity(0.95),
                const Color(0xFF004D40).withOpacity(0.95),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const AdminDashboardScreen(),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 22),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade400,
                    Colors.purple.shade400,
                    Colors.pink.shade400,
                    Colors.orange.shade400,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade200.withOpacity(0.5),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: isAdmin
                        ? "Search by student name or reason..."
                        : "Search by reason...",
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.shade400,
                            Colors.purple.shade400
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.search,
                          color: Colors.white, size: 20),
                    ),
                    suffixIcon: searchText.isNotEmpty
                        ? IconButton(
                            icon:
                                Icon(Icons.clear, color: Colors.grey.shade600),
                            onPressed: () {
                              setState(() {
                                searchText = '';
                              });
                            },
                          )
                        : Container(
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.orange.shade400,
                                  Colors.red.shade400
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.filter_alt,
                                color: Colors.white, size: 20),
                          ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 17),
                  ),
                  onChanged: (value) =>
                      setState(() => searchText = value.toLowerCase()),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filters.length,
              itemBuilder: (context, index) {
                String filter = filters[index];
                bool isSelected = selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    selectedColor: Colors.teal,
                    labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                        fontWeight: FontWeight.w600),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                        color: isSelected ? Colors.teal : Colors.grey.shade300,
                        width: 1.5),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    onSelected: (_) => setState(() => selectedFilter = filter),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              key: ValueKey('${isAdmin}_${selectedFilter}_$searchText'),
              stream: isAdmin
                  ? FirebaseFirestore.instance
                      .collection("leaves")
                      .orderBy("timestamp", descending: true)
                      .snapshots()
                  : FirebaseFirestore.instance
                      .collection("leaves")
                      .where('studentId', isEqualTo: userId)
                      .orderBy("timestamp", descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('Error loading leaves',
                            style: TextStyle(color: Colors.grey.shade600)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text("Retry"),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox,
                            size: 90, color: Colors.grey.shade300),
                        const SizedBox(height: 20),
                        Text(
                          isAdmin
                              ? "No leave requests found"
                              : "No leave requests found",
                          style: TextStyle(
                              fontSize: 17, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 12),
                        if (!isAdmin)
                          ElevatedButton.icon(
                            onPressed: _applyLeave,
                            icon: const Icon(Icons.add),
                            label: const Text("Apply for Leave"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        if (isAdmin)
                          const Text(
                            "Leave requests will appear here when employees apply",
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                      ],
                    ),
                  );
                }
                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  String status = data["status"] ?? "Pending";
                  String reason =
                      (data["reason"] ?? "").toString().toLowerCase();
                  String studentName =
                      (data["studentName"] ?? "").toString().toLowerCase();
                  bool matchesSearch = isAdmin
                      ? studentName.contains(searchText) ||
                          reason.contains(searchText)
                      : reason.contains(searchText);
                  bool matchesFilter =
                      selectedFilter == "All" || status == selectedFilter;
                  return matchesSearch && matchesFilter;
                }).toList();

                if (docs.isEmpty) {
                  String message = "";
                  if (selectedFilter != "All" && searchText.isNotEmpty) {
                    message =
                        "No matching leave requests for '$searchText' with status '$selectedFilter'";
                  } else if (selectedFilter != "All") {
                    message = "No $selectedFilter leave requests found";
                  } else if (searchText.isNotEmpty) {
                    message = "No leave requests found matching '$searchText'";
                  } else {
                    message = isAdmin
                        ? "No leave requests found"
                        : "You haven't applied for any leave yet";
                  }

                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.filter_alt_off,
                            size: 90, color: Colors.grey.shade300),
                        const SizedBox(height: 20),
                        Text(
                          message,
                          style: TextStyle(
                              fontSize: 16, color: Colors.grey.shade600),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        if (!isAdmin)
                          ElevatedButton.icon(
                            onPressed: _applyLeave,
                            icon: const Icon(Icons.add),
                            label: const Text("Apply for Leave"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        if (searchText.isNotEmpty || selectedFilter != "All")
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                searchText = '';
                                selectedFilter = 'All';
                              });
                            },
                            icon: const Icon(Icons.clear),
                            label: const Text("Clear Filters"),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.teal,
                            ),
                          ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  cacheExtent: 500,
                  addRepaintBoundaries: true,
                  addAutomaticKeepAlives: true,
                  itemBuilder: (context, index) {
                    final leave = docs[index];
                    final data = leave.data() as Map<String, dynamic>;
                    String id = leave.id;
                    String studentName = data["studentName"] ?? "Unknown";
                    String reason = data["reason"] ?? "Leave Request";
                    String status = data["status"] ?? "Pending";
                    String leaveType = data["leaveType"] ?? "Leave";
                    Timestamp? fromDate = data["fromDate"];
                    Timestamp? toDate = data["toDate"];
                    Timestamp? timestamp = data["timestamp"];
                    int daysCount = data["daysCount"] ?? 1;
                    String? proofUrl = data["proofUrl"];

                    return RepaintBoundary(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: Colors.teal.shade800,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade200,
                              offset: const Offset(0, 4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Card(
                          margin: EdgeInsets.zero,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: InkWell(
                            onTap: () => _showLeaveDetailsDialog(
                              studentName: studentName,
                              reason: reason,
                              status: status,
                              fromDate: fromDate,
                              toDate: toDate,
                              timestamp: timestamp,
                              daysCount: daysCount,
                              leaveType: leaveType,
                              proofUrl: proofUrl,
                              leaveId: id,
                            ),
                            borderRadius: BorderRadius.circular(22),
                            splashColor: Colors.teal.withOpacity(0.08),
                            highlightColor: Colors.teal.withOpacity(0.06),
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Row(
                                children: [
                                  Container(
                                    width: 58,
                                    height: 58,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: status == "Approved"
                                            ? [
                                                Colors.teal.shade400,
                                                Colors.green.shade400
                                              ]
                                            : status == "Rejected"
                                                ? [
                                                    Colors.red.shade400,
                                                    Colors.orange.shade400
                                                  ]
                                                : [
                                                    Colors.deepPurple.shade400,
                                                    Colors.purple.shade400
                                                  ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: statusColor(status)
                                              .withOpacity(0.3),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      status == "Approved"
                                          ? Icons.check_circle
                                          : status == "Rejected"
                                              ? Icons.cancel
                                              : Icons.pending,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                  ),
                                  const SizedBox(width: 18),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isAdmin ? studentName : leaveType,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 17),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          reason.length > 60
                                              ? '${reason.substring(0, 60)}...'
                                              : reason,
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade700,
                                              height: 1.3),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Icon(Icons.date_range,
                                                size: 16,
                                                color: Colors.grey.shade500),
                                            const SizedBox(width: 6),
                                            Text(
                                              fromDate != null && toDate != null
                                                  ? formatDate(fromDate)
                                                  : formatDate(timestamp),
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey.shade600),
                                            ),
                                            const Spacer(),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 5),
                                              decoration: BoxDecoration(
                                                color: statusColor(status)
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                border: Border.all(
                                                    color: statusColor(status)
                                                        .withOpacity(0.3),
                                                    width: 1.5),
                                              ),
                                              child: Text(
                                                status,
                                                style: TextStyle(
                                                    color: statusColor(status),
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 12),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.teal.shade400,
                                          Colors.teal.shade800
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: !isAdmin
          ? FloatingActionButton.extended(
              onPressed: _applyLeave,
              icon: const Icon(Icons.add),
              label: const Text('Apply Leave'),
              backgroundColor: Colors.teal,
              elevation: 8,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            )
          : null,
    );
  }
}
