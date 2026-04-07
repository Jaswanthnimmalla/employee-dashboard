import 'package:employee_dashboard_app/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import '../../data/models/leave_model.dart';

class LeaveList extends StatelessWidget {
  final List<LeaveModel> leaves;

  const LeaveList({Key? key, required this.leaves}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (leaves.isEmpty) {
      return const Center(
        child: Text('No leave records found'),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: leaves.length > 5 ? 5 : leaves.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final leave = leaves[index];
        return _buildLeaveItem(leave);
      },
    );
  }

  Widget _buildLeaveItem(LeaveModel leave) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                leave.type,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${leave.startDate} to ${leave.endDate}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(leave.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            leave.status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _getStatusColor(leave.status),
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }
}
