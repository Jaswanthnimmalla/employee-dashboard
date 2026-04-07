import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:employee_dashboard_app/core/services/cloudinary_service.dart';

class UserRequestScreen extends StatefulWidget {
  const UserRequestScreen({super.key});

  @override
  State<UserRequestScreen> createState() => _UserRequestScreenState();
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
              color: Colors.deepPurple.shade700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Submitting...",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserRequestScreenState extends State<UserRequestScreen> {
  final reasonController = TextEditingController();

  File? selectedFile;
  bool loading = false;
  String? selectedRequestType;

  final requestTypes = [
    "Permission",
    "Work From Home",
    "Attendance Correction",
    "Equipment Request",
    "Other"
  ];

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result != null) {
      setState(() {
        selectedFile = File(result.files.single.path!);
      });
      showSnack("File uploaded successfully", Colors.green);
    }
  }

  Future<void> submitRequest() async {
    if (reasonController.text.isEmpty ||
        selectedRequestType == null ||
        selectedFile == null) {
      showSnack("Please fill all fields", Colors.red);
      return;
    }

    setState(() {
      loading = true;
    });

    /// SHOW PAPER JET LOADER DIALOG
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: _PaperJetLoader(),
      ),
    );

    try {
      final user = FirebaseAuth.instance.currentUser;

      final fileUrl = await CloudinaryService.uploadRequestFile(
        selectedFile!,
        userId: user!.uid,
      );

      await FirebaseFirestore.instance.collection("requests").add({
        "userId": user.uid,
        "userName": user.displayName ?? user.email?.split('@')[0] ?? "Employee",
        "requestType": selectedRequestType,
        "reason": reasonController.text,
        "fileUrl": fileUrl,
        "status": "Pending",
        "timestamp": FieldValue.serverTimestamp(),
      });

      showSnack("Request submitted successfully", Colors.green);

      reasonController.clear();

      setState(() {
        selectedFile = null;
        selectedRequestType = null;
      });
    } catch (e) {
      showSnack("Submit failed", Colors.red);
    } finally {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> cancelRequest(String id) async {
    await FirebaseFirestore.instance.collection("requests").doc(id).delete();
    showSnack("Request cancelled", Colors.orange);
  }

  Future<void> openFile(String url) async {
    await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
  }

  void showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
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

  void showRequestDetails(Map<String, dynamic> data, String id) {
    final String status = data["status"];
    final bool isPending = status == "Pending";

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.deepPurple.shade50, Colors.white],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.assignment,
                      color: Colors.deepPurple.shade800,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      data["requestType"],
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor(status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor(status), width: 1),
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
                ],
              ),
              const SizedBox(height: 20),
              _buildDetailRow(
                icon: Icons.description,
                label: "Reason",
                value: data["reason"],
              ),
              const SizedBox(height: 16),
              if (data["timestamp"] != null)
                _buildDetailRow(
                  icon: Icons.calendar_today,
                  label: "Submitted",
                  value: _formatDate(data["timestamp"]),
                ),
              const SizedBox(height: 16),
              _buildDetailRow(
                icon: Icons.attach_file,
                label: "Attachment",
                value: "View Document",
                isFileLink: true,
                onFileTap: () {
                  Navigator.pop(context);
                  openFile(data["fileUrl"]);
                },
              ),
              const SizedBox(height: 24),
              if (isPending)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      cancelRequest(id);
                    },
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: const Text(
                      "Cancel Request",
                      style: TextStyle(color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                )
              else
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Close"),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return "Unknown";
    final date = timestamp.toDate();
    return "${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool isFileLink = false,
    VoidCallback? onFileTap,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.deepPurple.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.shade50,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: Colors.deepPurple.shade700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                isFileLink
                    ? GestureDetector(
                        onTap: onFileTap,
                        child: Text(
                          value,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.deepPurple.shade700,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      )
                    : Text(
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      appBar: AppBar(
        title: const Text("Request Management"),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Apply Request Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: Colors.deepPurple.shade200, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.shade100,
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    "Submit Request",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField(
                    value: selectedRequestType,
                    decoration: InputDecoration(
                      labelText: "Request Type",
                      labelStyle: TextStyle(color: Colors.deepPurple.shade400),
                      prefixIcon: Icon(Icons.category,
                          color: Colors.deepPurple.shade400),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            BorderSide(color: Colors.deepPurple.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            BorderSide(color: Colors.deepPurple.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                            color: Colors.deepPurple, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: requestTypes
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(e),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedRequestType = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: "Reason",
                      labelStyle: TextStyle(color: Colors.deepPurple.shade400),
                      prefixIcon: Icon(Icons.textsms,
                          color: Colors.deepPurple.shade400),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            BorderSide(color: Colors.deepPurple.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            BorderSide(color: Colors.deepPurple.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                            color: Colors.deepPurple, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: pickFile,
                    icon: Icon(
                      selectedFile != null ? Icons.check_circle : Icons.upload,
                      color: selectedFile != null
                          ? Colors.green
                          : Colors.deepPurple,
                    ),
                    label: Text(
                      selectedFile != null ? "File Uploaded ✓" : "Upload File",
                      style: TextStyle(
                        color: selectedFile != null
                            ? Colors.green
                            : Colors.deepPurple,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: selectedFile != null
                            ? Colors.green
                            : Colors.deepPurple.shade200,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: loading
                          ? null
                          : () async {
                              if (!mounted) return;
                              setState(() {
                                loading = true;
                              });
                              await submitRequest();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Submit Request",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "My Request History",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("requests")
                  .where("userId", isEqualTo: user?.uid)
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Text("No request history");
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    String id = docs[index].id;
                    String status = data["status"];

                    return GestureDetector(
                      onTap: () => showRequestDetails(data, id),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: status == "Pending"
                                ? Colors.deepPurple.shade200
                                : status == "Approved"
                                    ? Colors.green.shade200
                                    : Colors.red.shade200,
                            width: 1.5,
                          ),
                        ),
                        child: ListTile(
                          title: Text(data["requestType"]),
                          subtitle: Text(data["reason"]),
                          trailing: status == "Pending"
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => cancelRequest(id),
                                )
                              : Text(
                                  status,
                                  style: TextStyle(
                                    color: statusColor(status),
                                    fontWeight: FontWeight.bold,
                                  ),
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
    );
  }
}
