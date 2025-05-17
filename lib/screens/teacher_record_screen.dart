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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.school, color: Colors.green),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Teacher Management',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: LayoutBuilder(builder: (context, constraints) {
                    // Determine grid layout based on screen width
                    final isWideScreen = constraints.maxWidth > 600;
                    final crossAxisCount = isWideScreen ? 3 : 2;
                    final childAspectRatio = isWideScreen ? 2.2 : 1.8;
                    
                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: childAspectRatio,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      padding: const EdgeInsets.symmetric(vertical: 6),
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
                      ],
                    );
                  }),
                ),
              ],
            ),
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
    return Card(
      elevation: 1,
      margin: const EdgeInsets.all(2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: iconColor.withOpacity(0.2),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Icon(icon, size: 18, color: iconColor),
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_forward_ios, size: 12, color: iconColor.withOpacity(0.5)),
                  ],
                ),
                const Spacer(),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Manage ${title.toLowerCase()}',
                  style: TextStyle(
                    fontSize: 10,
                    color: iconColor.withOpacity(0.7),
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
