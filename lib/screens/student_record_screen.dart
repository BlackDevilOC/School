import 'package:flutter/material.dart';
import '../routes.dart';
import 'monthly_report_screen.dart';
import '../services/database_service.dart';
import '../models/student.dart';
import '../models/attendance.dart';
import 'package:intl/intl.dart';

class StudentRecordScreen extends StatefulWidget {
  const StudentRecordScreen({super.key});

  @override
  State<StudentRecordScreen> createState() => _StudentRecordScreenState();
}

class _StudentRecordScreenState extends State<StudentRecordScreen> {
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = true;
  List<Student> _students = [];
  List<Attendance> _attendanceRecords = [];
  Map<String, Map<String, int>> _attendanceStats = {};
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load students
      final students = await _databaseService.getStudents();
      
      // Load today's attendance
      final today = DateTime.now();
      final attendance = await _databaseService.getAttendanceForDate(today);
      
      // Calculate statistics
      final stats = await _calculateAttendanceStats(students);
      
      setState(() {
        _students = students;
        _attendanceRecords = attendance;
        _attendanceStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }
  
  Future<Map<String, Map<String, int>>> _calculateAttendanceStats(List<Student> students) async {
    // Initialize stats map
    final Map<String, Map<String, int>> stats = {};
    
    // Get current month and year
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;
    
    // For each student
    for (final student in students) {
      // Get all attendance records for this student
      final attendance = await _databaseService.getStudentAttendance(student.id);
      
      // Filter to current month
      final currentMonthAttendance = attendance.where((a) => 
        a.month == currentMonth && a.year == currentYear).toList();
      
      // Count status occurrences
      int present = 0;
      int absent = 0;
      int excused = 0; // This is "Leave" in UI
      
      for (final record in currentMonthAttendance) {
        switch (record.status) {
          case 'Present':
            present++;
            break;
          case 'Absent':
            absent++;
            break;
          case 'Excused': // This is "Leave" in UI
            excused++;
            break;
        }
      }
      
      // Store stats
      stats[student.id] = {
        'present': present,
        'absent': absent,
        'excused': excused,
        'total': currentMonthAttendance.length,
      };
    }
    
    return stats;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Student Record',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.green,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Container(
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
                    // Today's Attendance Summary
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Today's Attendance",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildAttendanceCounter(
                                  'Present',
                                  _attendanceRecords.where((a) => a.status == 'Present').length,
                                  Colors.green,
                                ),
                                _buildAttendanceCounter(
                                  'Absent',
                                  _attendanceRecords.where((a) => a.status == 'Absent').length,
                                  Colors.red,
                                ),
                                _buildAttendanceCounter(
                                  'Leave',
                                  _attendanceRecords.where((a) => a.status == 'Excused').length,
                                  Colors.blue,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Student Management',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 24),
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
                              Navigator.pushNamed(context, Routes.studentAttendance);
                            },
                          ),
                          _buildActionCard(
                            context,
                            'Manage Students',
                            Icons.groups_outlined,
                            Colors.green.shade50,
                            Colors.green.shade700,
                            () {
                              Navigator.pushNamed(context, Routes.manageStudents);
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
                            'Fees Structure',
                            Icons.account_balance_wallet_outlined,
                            Colors.amber.shade50,
                            Colors.amber.shade700,
                            () {
                              Navigator.pushNamed(context, Routes.feeStructure);
                            },
                          ),
                          _buildActionCard(
                            context,
                            'Attendance Records',
                            Icons.calendar_today_outlined,
                            Colors.teal.shade50,
                            Colors.teal.shade700,
                            () {
                              _showAttendanceDetails(context);
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

  Widget _buildAttendanceCounter(String label, int count, Color color) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: color.withOpacity(0.2),
          child: Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MonthlyReportScreen(isTeacher: false),
      ),
    );
  }
  
  void _showAttendanceDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Attendance Records',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Current Month Statistics',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: _students.length,
                      itemBuilder: (context, index) {
                        final student = _students[index];
                        final stats = _attendanceStats[student.id] ?? {
                          'present': 0,
                          'absent': 0,
                          'excused': 0,
                          'total': 0,
                        };
                        
                        // Calculate attendance percentage
                        final total = stats['total'] ?? 0;
                        final present = stats['present'] ?? 0;
                        final percentage = total > 0 
                            ? (present / total * 100).toStringAsFixed(1) 
                            : '0.0';
                        
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  student.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  student.isClassStudent
                                      ? 'Class: ${student.classGrade}'
                                      : 'Course: ${student.courseName}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildStatItem('Present', stats['present'] ?? 0, Colors.green),
                                    _buildStatItem('Absent', stats['absent'] ?? 0, Colors.red),
                                    _buildStatItem('Leave', stats['excused'] ?? 0, Colors.blue),
                                    Column(
                                      children: [
                                        Text(
                                          '$percentage%',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: double.parse(percentage) >= 75 
                                                ? Colors.green 
                                                : Colors.red,
                                          ),
                                        ),
                                        Text(
                                          'Attendance',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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
  
  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
