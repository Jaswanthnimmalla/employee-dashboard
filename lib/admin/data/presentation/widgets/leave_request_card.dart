import 'package:employee_dashboard_app/admin/data/models/leave_request_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class LeaveRequestCard extends StatelessWidget {
  final LeaveRequestModel request;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onDelete;

  const LeaveRequestCard({
    super.key,
    required this.request,
    required this.onApprove,
    required this.onReject,
    required this.onDelete,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approved':
        return Colors.green;

      case 'Rejected':
        return Colors.red;

      default:
        return Colors.orange;
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  // FIXED FUNCTION
  Future<void> _openProof() async {
    if (request.proofUrl.isNotEmpty) {
      final uri = Uri.parse(request.proofUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 600;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: EdgeInsets.all(isSmall ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFE74C3C).withOpacity(0.1),
                  radius: isSmall ? 20 : 24,
                  child: Text(
                    request.employeeName.isNotEmpty
                        ? request.employeeName[0].toUpperCase()
                        : 'E',
                    style: const TextStyle(
                      color: Color(0xFFE74C3C),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.employeeName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isSmall ? 14 : 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        request.leaveType,
                        style: TextStyle(
                          fontSize: isSmall ? 11 : 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(request.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    request.status,
                    style: TextStyle(
                      color: _getStatusColor(request.status),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Reason: ${request.reason}',
              style: TextStyle(
                fontSize: isSmall ? 12 : 13,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: isSmall ? 12 : 14,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 6),
                Text(
                  '${_formatDate(request.fromDate)} - ${_formatDate(request.toDate)}',
                  style: TextStyle(
                    fontSize: isSmall ? 11 : 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.timer,
                  size: isSmall ? 12 : 14,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 6),
                Text(
                  '${request.daysCount} days',
                  style: TextStyle(
                    fontSize: isSmall ? 11 : 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (request.proofUrl.isNotEmpty)
                  IconButton(
                    icon: const Icon(
                      Icons.visibility,
                      color: Colors.blue,
                      size: 20,
                    ),
                    onPressed: _openProof,
                    tooltip: 'View Proof',
                  ),
                if (request.status == 'Pending') ...[
                  IconButton(
                    icon: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                    onPressed: onApprove,
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.cancel,
                      color: Colors.red,
                      size: 20,
                    ),
                    onPressed: onReject,
                  ),
                ],
                IconButton(
                  icon: const Icon(
                    Icons.delete,
                    color: Colors.grey,
                    size: 20,
                  ),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
