import 'package:flutter/material.dart';
import '../routes.dart';
import 'teacher_monthly_report_screen.dart';
import 'teacher_salary_screen.dart';

class TeacherRecordScreen extends StatelessWidget {
  const TeacherRecordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Teacher Record',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.green,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.withOpacity(0.1), Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Teacher Management',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.count(
                  crossAxisCount:
                      MediaQuery.of(context).size.width > 600 ? 3 : 2,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _buildActionCard(
                      context,
                      'Attendance',
                      Icons.fact_check_outlined,
                      Colors.blue.shade50,
                      Colors.blue.shade700,
                      () {
                        Navigator.pushNamed(context, Routes.teacherAttendance);
                      },
                    ),
                    _buildActionCard(
                      context,
                      'Manage Teachers',
                      Icons.groups_outlined,
                      Colors.green.shade50,
                      Colors.green.shade700,
                      () {
                        Navigator.pushNamed(context, Routes.manageTeachers);
                      },
                    ),
                    _buildActionCard(
                      context,
                      'Monthly Reports',
                      Icons.assessment_outlined,
                      Colors.purple.shade50,
                      Colors.purple.shade700,
                      () {
                        _showMonthlyReports(context);
                      },
                    ),
                    _buildActionCard(
                      context,
                      'Salary Structure',
                      Icons.account_balance_wallet_outlined,
                      Colors.amber.shade50,
                      Colors.amber.shade700,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TeacherSalaryScreen(),
                          ),
                        );
                      },
                    ),
                    _buildActionCard(
                      context,
                      'Time Table',
                      Icons.calendar_month_outlined,
                      Colors.teal.shade50,
                      Colors.teal.shade700,
                      () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Time Table - Coming Soon'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
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

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color bgColor,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                // Background design element
                Positioned(
                  right: -15,
                  bottom: -15,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 36, color: iconColor),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: iconColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMonthlyReports(BuildContext context) {
    Navigator.pushNamed(context, Routes.teacherMonthlyReport);
  }
}
