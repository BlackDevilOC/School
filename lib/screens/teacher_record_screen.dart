import 'package:flutter/material.dart';
import '../routes.dart';
import 'monthly_report_screen.dart';

class TeacherRecordScreen extends StatelessWidget {
  const TeacherRecordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Record'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Teacher Management',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildActionCard(
                    context,
                    'Attendance',
                    Icons.assignment_turned_in,
                    Colors.blue.shade100,
                    Colors.blue.shade700,
                    () {
                      Navigator.pushNamed(context, Routes.teacherAttendance);
                    },
                  ),
                  _buildActionCard(
                    context,
                    'Manage Teachers',
                    Icons.people,
                    Colors.green.shade100,
                    Colors.green.shade700,
                    () {
                      Navigator.pushNamed(context, Routes.manageTeachers);
                    },
                  ),
                  _buildActionCard(
                    context,
                    'Teacher Details',
                    Icons.person_search,
                    Colors.orange.shade100,
                    Colors.orange.shade700,
                    () {
                      _showTeacherDetails(context);
                    },
                  ),
                  _buildActionCard(
                    context,
                    'Monthly Reports',
                    Icons.calendar_month,
                    Colors.purple.shade100,
                    Colors.purple.shade700,
                    () {
                      _showMonthlyReports(context);
                    },
                  ),
                  _buildActionCard(
                    context,
                    'Salary Structure',
                    Icons.attach_money,
                    Colors.amber.shade100,
                    Colors.amber.shade700,
                    () {
                      // Handle salary structure
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Salary Structure - Coming Soon'),
                        ),
                      );
                    },
                  ),
                  _buildActionCard(
                    context,
                    'Time Table',
                    Icons.access_time,
                    Colors.teal.shade100,
                    Colors.teal.shade700,
                    () {
                      // Handle time table
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Time Table - Coming Soon')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color bgColor,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: iconColor),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTeacherDetails(BuildContext context) {
    // Show a dialog to select a teacher
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Select Teacher'),
            content: const Text(
              'This will show a list of teachers to select for viewing detailed information',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _showMonthlyReports(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MonthlyReportScreen(isTeacher: true),
      ),
    );
  }
}
