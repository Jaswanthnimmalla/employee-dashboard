import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:employee_dashboard_app/core/services/cloudinary_service.dart';

class LeaveManagementScreen extends StatefulWidget {
  const LeaveManagementScreen({super.key});

  @override
  State<LeaveManagementScreen> createState() => _LeaveManagementScreenState();
}

class _PaperJetLoader extends StatefulWidget {
  const _PaperJetLoader({super.key});

  @override
  State<_PaperJetLoader> createState() => _PaperJetLoaderState();
}

class _PaperJetLoaderState extends State<_PaperJetLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0,
      end: 40,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// MOVING JET
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_animation.value, 0),
                child: child,
              );
            },
            child: Icon(
              Icons.send_rounded,
              size: 54,

              /// STRONG COLOR
              color: Colors.deepPurple.shade700,
            ),
          ),

          const SizedBox(height: 10),

          /// TEXT
          Text(
            "Submitting...",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,

              /// HIGH CONTRAST COLOR
              color: Colors.black87,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaveManagementScreenState extends State<LeaveManagementScreen> {
  final reasonController = TextEditingController();
  DateTime? fromDate;
  DateTime? toDate;
  File? selectedFile;
  bool loading = false;
  String? selectedLeaveType;

  final leaveTypes = [
    "Sick Leave",
    "Casual Leave",
    "Emergency Leave",
    "Vacation",
    "Study Leave",
    "Other"
  ];

  Color leaveTypeColor(String type) {
    switch (type) {
      case "Sick Leave":
        return Colors.red;

      case "Casual Leave":
        return Colors.orange;

      case "Emergency Leave":
        return Colors.deepPurple;

      case "Vacation":
        return Colors.blue;

      case "Study Leave":
        return Colors.green;

      default:
        return Colors.grey;
    }
  }

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result != null) {
      setState(() {
        selectedFile = File(result.files.single.path!);
      });
      showSnack("Proof uploaded successfully", Colors.green);
    }
  }

  Future<void> pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      initialDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          fromDate = picked;
        } else {
          toDate = picked;
        }
      });
    }
  }

  int calculateDays() {
    if (fromDate == null || toDate == null) {
      return 0;
    }
    return toDate!.difference(fromDate!).inDays + 1;
  }

  Color statusColor(String status) {
    switch (status) {
      case "Approved":
        return Colors.green;
      case "Rejected":
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData statusIcon(String status) {
    switch (status) {
      case "Approved":
        return Icons.check_circle;
      case "Rejected":
        return Icons.cancel;
      default:
        return Icons.pending;
    }
  }

  Future<void> submitLeave() async {
    if (reasonController.text.isEmpty ||
        fromDate == null ||
        toDate == null ||
        selectedLeaveType == null ||
        selectedFile == null) {
      showSnack("Please fill all fields", Colors.red);
      return;
    }

    if (toDate!.isBefore(fromDate!)) {
      showSnack("Invalid date range", Colors.red);
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        showSnack("User not logged in", Colors.red);
        setState(() => loading = false);
        return;
      }

      final proofUrl = await CloudinaryService.uploadLeaveProof(
        selectedFile!,
        userId: user.uid,
      );

      if (proofUrl == null) {
        showSnack("File upload failed", Colors.red);
        setState(() => loading = false);
        return;
      }

      // Match your Firestore structure exactly
      await FirebaseFirestore.instance.collection("leaves").add({
        "studentId": user.uid, // Using studentId as shown in your screenshot
        "studentName":
            user.displayName ?? user.email?.split('@')[0] ?? 'Employee',
        "leaveType": selectedLeaveType,
        "reason": reasonController.text,
        "fromDate": Timestamp.fromDate(fromDate!),
        "toDate": Timestamp.fromDate(toDate!),
        "daysCount": calculateDays(),
        "proofUrl": proofUrl,
        "status": "Pending",
        "timestamp": FieldValue.serverTimestamp(),
      });

      showSnack("Leave submitted successfully", Colors.green);

      reasonController.clear();
      setState(() {
        selectedFile = null;
        fromDate = null;
        toDate = null;
        selectedLeaveType = null;
      });
    } catch (e) {
      debugPrint("Submit error: $e");
      showSnack("Submit failed", Colors.red);
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> cancelLeave(String id) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Leave Request'),
        content:
            const Text('Are you sure you want to cancel this leave request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseFirestore.instance
                    .collection("leaves")
                    .doc(id)
                    .delete();
                showSnack("Leave cancelled", Colors.orange);
              } catch (e) {
                showSnack("Error cancelling leave", Colors.red);
              }
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  Future<void> openProof(String url) async {
    try {
      await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      showSnack("Could not open proof", Colors.red);
    }
  }

  void showSnack(String message, Color color) {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.maybeOf(context);

    if (messenger == null) return;

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        duration: const Duration(seconds: 2),
        content: Row(
          children: [
            Icon(
              color == Colors.green ? Icons.check_circle : Icons.error,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String formatDate(dynamic date) {
    if (date == null) return "Not set";
    if (date is Timestamp) {
      final d = date.toDate();
      return "${d.day}/${d.month}/${d.year}";
    }
    return "";
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.deepPurple.shade50,
      appBar: AppBar(
        /// GRADIENT BACKGROUND (same as dashboard)
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF6C5CE7), // purple
                Color(0xFF8E2DE2), // violet
                Color(0xFFFF7043), // orange
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),

        elevation: 4,

        centerTitle: true,

        foregroundColor: Colors.white,

        /// TITLE
        title: const Text(
          "Apply for Leave",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),

        /// BACK BUTTON
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.deepPurple.shade200,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 18),

                    /// LEAVE TYPE
                    DropdownButtonFormField<String>(
                      value: selectedLeaveType,
                      hint: const Text(
                        "Select Leave Type",
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      decoration: InputDecoration(
                        labelText: "Leave Type",
                        prefixIcon: const Icon(
                          Icons.category_rounded,
                          color: Colors.deepPurple,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: Colors.deepPurple.shade200,
                          ),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.deepPurple,
                            width: 2,
                          ),
                        ),
                      ),
                      items: leaveTypes.map((e) {
                        final color = leaveTypeColor(e);

                        return DropdownMenuItem<String>(
                          value: e,
                          child: Row(
                            children: [
                              /// COLORED DOT
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),

                              const SizedBox(width: 10),

                              /// LEAVE TEXT
                              Text(
                                e,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedLeaveType = value;
                        });
                      },
                    ),

                    const SizedBox(height: 14),

                    /// REASON FIELD
                    TextField(
                      controller: reasonController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: "Reason",
                        prefixIcon: const Icon(
                          Icons.description_rounded,
                          color: Colors.deepPurple,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: Colors.deepPurple.shade200,
                          ),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.deepPurple,
                            width: 2,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    /// DATE PICKERS
                    Row(
                      children: [
                        /// FROM DATE
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => pickDate(true),
                            icon: const Icon(
                              Icons.calendar_today,
                              color: Colors.deepPurple,
                            ),
                            label: Text(
                              fromDate == null
                                  ? "From Date"
                                  : formatDate(
                                      Timestamp.fromDate(fromDate!),
                                    ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(
                                color: Colors.deepPurple.shade300,
                                width: 1.4,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        /// TO DATE
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => pickDate(false),
                            icon: const Icon(
                              Icons.event_available,
                              color: Colors.deepPurple,
                            ),
                            label: Text(
                              toDate == null
                                  ? "To Date"
                                  : formatDate(
                                      Timestamp.fromDate(toDate!),
                                    ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(
                                color: Colors.deepPurple.shade300,
                                width: 1.4,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    /// DURATION
                    if (calculateDays() > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.shade50,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.deepPurple.shade300,
                                width: 1.4,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize
                                  .min, // VERY IMPORTANT for centering
                              children: [
                                const Icon(
                                  Icons.timelapse_rounded,
                                  color: Colors.deepPurple,
                                  size: 20,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "Duration: ${calculateDays()} day${calculateDays() > 1 ? 's' : ''}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 14),

                    /// FILE UPLOAD
                    Center(
                      child: OutlinedButton.icon(
                        onPressed: pickFile,
                        icon: const Icon(
                          Icons.upload_file_rounded,
                          color: Colors.deepPurple,
                          size: 22,
                        ),
                        label: Text(
                          selectedFile != null
                              ? "Proof Uploaded ✓"
                              : "Upload Proof",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: selectedFile != null
                                ? Colors.green
                                : Colors.deepPurple,
                            letterSpacing: 0.3,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          side: BorderSide(
                            color: Colors.deepPurple.shade300,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// SUBMIT BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: loading
                            ? null
                            : () async {
                                if (!mounted) return;

                                /// START LOADING STATE
                                setState(() {
                                  loading = true;
                                });

                                /// SHOW LOADER DIALOG
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (_) => const Center(
                                    child: _PaperJetLoader(),
                                  ),
                                );

                                try {
                                  /// CALL SUBMIT FUNCTION
                                  await submitLeave();
                                } catch (e) {
                                  debugPrint("Submit error: $e");
                                } finally {
                                  /// ALWAYS CLOSE LOADER
                                  if (mounted) {
                                    Navigator.of(
                                      context,
                                      rootNavigator: true,
                                    ).pop();

                                    /// STOP LOADING STATE
                                    setState(() {
                                      loading = false;
                                    });
                                  }
                                }
                              },
                        icon: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        label: loading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                "Submit Leave",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 5,
                          shadowColor: Colors.deepPurple,
                          side: const BorderSide(
                            color: Colors.deepPurple,
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "My Leave History",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("leaves")
                    .where("studentId",
                        isEqualTo:
                            user?.uid) // Using studentId to match your data
                    .orderBy("timestamp", descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'Error loading leaves',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please check your connection',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.inbox, size: 48, color: Colors.grey),
                          SizedBox(height: 12),
                          Text(
                            "No leave history found",
                            style: TextStyle(color: Colors.grey),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Submit your first leave request above",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final leave = docs[index];
                      final data = leave.data() as Map<String, dynamic>;

                      String id = leave.id;
                      String status = data["status"] ?? "Pending";
                      String leaveType = data["leaveType"] ?? "Leave";
                      String reason = data["reason"] ?? "";
                      Timestamp? fromDate = data["fromDate"];
                      Timestamp? toDate = data["toDate"];
                      int daysCount = data["daysCount"] ?? 0;
                      String? proofUrl = data["proofUrl"];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),

                          /// BORDER ADDED HERE
                          side: const BorderSide(
                            color: Color(0xFF6C5CE7),
                            width: 1.5,
                          ),
                        ),
                        child: InkWell(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => Dialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  constraints:
                                      const BoxConstraints(maxWidth: 400),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: statusColor(status)
                                                  .withOpacity(0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              statusIcon(status),
                                              color: statusColor(status),
                                              size: 28,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  leaveType,
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: statusColor(status)
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  child: Text(
                                                    status,
                                                    style: TextStyle(
                                                      color:
                                                          statusColor(status),
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.close),
                                            onPressed: () =>
                                                Navigator.pop(context),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 24),
                                      _buildDetailRow(
                                          Icons.description, 'Reason', reason),
                                      const SizedBox(height: 12),
                                      _buildDetailRow(
                                        Icons.date_range,
                                        'Date Range',
                                        fromDate != null && toDate != null
                                            ? '${formatDate(fromDate)} - ${formatDate(toDate)}'
                                            : 'Not specified',
                                      ),
                                      const SizedBox(height: 12),
                                      _buildDetailRow(
                                        Icons.calendar_today,
                                        'Duration',
                                        '$daysCount day${daysCount > 1 ? 's' : ''}',
                                      ),
                                      if (proofUrl != null &&
                                          proofUrl.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        _buildDetailRow(
                                          Icons.attachment,
                                          'Proof',
                                          'View Attachment',
                                          isLink: true,
                                          onTap: () => openProof(proofUrl),
                                        ),
                                      ],
                                      const SizedBox(height: 24),
                                      if (status == "Pending")
                                        SizedBox(
                                          width: double.infinity,
                                          child: OutlinedButton.icon(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              cancelLeave(id);
                                            },
                                            icon: const Icon(Icons.cancel),
                                            label: const Text('Cancel Request'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.red,
                                              side: const BorderSide(
                                                  color: Colors.red),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),

                            /// LEFT ICON
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: statusColor(status).withOpacity(0.15),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: statusColor(status),
                                  width: 1.6,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        statusColor(status).withOpacity(0.25),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Icon(
                                statusIcon(status),
                                color: statusColor(status),
                                size: 26,
                              ),
                            ),

                            /// TITLE
                            title: Text(
                              leaveType,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 0.3,
                              ),
                            ),

                            /// DETAILS
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 6),

                                /// REASON ROW
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.description,
                                      size: 15,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        reason.length > 40
                                            ? '${reason.substring(0, 40)}...'
                                            : reason,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 6),

                                /// DATE + DAYS ROW (ALIGNED)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.calendar_today,
                                      size: 14,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        formatDate(fromDate) != "Not set" &&
                                                formatDate(toDate) != "Not set"
                                            ? '${formatDate(fromDate)} - ${formatDate(toDate)}'
                                            : 'Date not set',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 2),

                                /// DAYS ROW (SEPARATE LINE — CLEAN ALIGNMENT)
                                Row(
                                  children: [
                                    const SizedBox(
                                        width: 20), // aligns under date text

                                    Text(
                                      '• $daysCount day${daysCount > 1 ? 's' : ''}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            /// RIGHT SIDE
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                /// DELETE OR STATUS (unchanged logic)
                                status == "Pending"
                                    ? Container(
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.12),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.red,
                                            width: 1.4,
                                          ),
                                        ),
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                            size: 22,
                                          ),
                                          onPressed: () => cancelLeave(id),
                                        ),
                                      )
                                    : Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusColor(status)
                                              .withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(
                                            color: statusColor(status),
                                            width: 1.4,
                                          ),
                                        ),
                                        child: Text(
                                          status,
                                          style: TextStyle(
                                            color: statusColor(status),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),

                                const SizedBox(width: 8),

                                /// BOLD COLORFUL ARROW INDICATOR
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple.withOpacity(0.12),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.deepPurple,
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.deepPurple.withOpacity(0.25),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 18,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value,
      {bool isLink = false, VoidCallback? onTap}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.deepPurple.shade400),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              if (isLink)
                GestureDetector(
                  onTap: onTap,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.deepPurple,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                )
              else
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
