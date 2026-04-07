// lib/features/admin/presentation/widgets/employee_list_tile.dart
import 'package:employee_dashboard_app/admin/data/models/employee_model.dart';
import 'package:flutter/material.dart';

class EmployeeListTile extends StatelessWidget {
  final EmployeeModel employee;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;

  const EmployeeListTile({
    super.key,
    required this.employee,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.all(isSmall ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF6C5CE7).withOpacity(0.1),
            radius: isSmall ? 20 : 25,
            child: Text(
              employee.name.isNotEmpty ? employee.name[0].toUpperCase() : 'E',
              style: TextStyle(
                color: const Color(0xFF6C5CE7),
                fontWeight: FontWeight.bold,
                fontSize: isSmall ? 14 : 16,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employee.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isSmall ? 14 : 16,
                    color: const Color(0xFF2D3436),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  employee.email,
                  style: TextStyle(
                    fontSize: isSmall ? 11 : 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (!isSmall) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${employee.department} • ${employee.position}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: employee.isActive
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              employee.isActive ? 'Active' : 'Inactive',
              style: TextStyle(
                color: employee.isActive ? Colors.green : Colors.red,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
            onPressed: onDelete,
          ),
          Switch(
            value: employee.isActive,
            onChanged: (_) => onToggleStatus(),
            activeColor: Colors.green,
          ),
        ],
      ),
    );
  }
}
