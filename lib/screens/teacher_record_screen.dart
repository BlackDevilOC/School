import 'package:flutter/material.dart';
import '../routes.dart';
import 'monthly_report_screen.dart';
import 'teacher_salary_screen.dart';
import '../services/database_service.dart';
import '../models/teacher.dart';
import '../models/teacher_attendance.dart';

class TeacherRecordScreen extends StatefulWidget {
  const TeacherRecordScreen({super.key});

  @override
  State<TeacherRecordScreen> createState() => _TeacherRecordScreenState();
}

class _TeacherRecordScreenState extends State<TeacherRecordScreen> {
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = true;
  List<Teacher> _teachers = [];
  List<TeacherAttendance> _attendanceRecords = [];
  Map<String, Map<String, int>> _attendanceStats = {};
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load teachers
      final teachers = await _databaseService.getTeachers();
      
      // Load today's attendance
      final today = DateTime.now();
      final attendance = await _databaseService.getTeacherAttendanceForDate(today);
      
      // Calculate statistics
      final stats = await _calculateAttendanceStats(teachers);
      
      setState(() {
        _teachers = teachers;
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
  
  Future<Map<String, Map<String, int>>> _calculateAttendanceStats(List<Teacher> teachers) async {
    // Initialize stats map
    final Map<String, Map<String, int>> stats = {};
    
    // Get current month and year
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;
    
    // For each teacher
    for (final teacher in teachers) {
      // Get all attendance records for this teacher
      final attendance = await _databaseService.getTeacherAttendance(teacher.id);
      
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
      stats[teacher.id] = {
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
    // Determine if we're on a mobile or web layout based on screen width
    final isWebLayout = MediaQuery.of(context).size.width > 800;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Teacher Record',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.green,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Today's Attendance",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildAttendanceCounter(
                                  'Present',
                                  _attendanceRecords
                                      .where((a) => a.status == 'Present')
                                      .length,
                                  Colors.green,
                                ),
                                _buildAttendanceCounter(
                                  'Absent',
                                  _attendanceRecords
                                      .where((a) => a.status == 'Absent')
                                      .length,
                                  Colors.red,
                                ),
                                _buildAttendanceCounter(
                                  'Leave',
                                  _attendanceRecords
                                      .where((a) => a.status == 'Excused')
                                      .length,
                                  Colors.blue,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: isWebLayout
                          ? _buildWebLayout(context)
                          : _buildMobileLayout(context),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildWebLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left side - Action cards in a grid
        Expanded(
          flex: 2,
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Teacher Management",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      childAspectRatio: 1.2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        _buildActionCard(
                          context,
                          'Manage Teachers',
                          Icons.edit,
                          Colors.blue.withOpacity(0.1),
                          Colors.blue,
                          () => Navigator.pushNamed(context, Routes.manageTeachers),
                        ),
                        _buildActionCard(
                          context,
                          'Attendance',
                          Icons.calendar_today,
                          Colors.orange.withOpacity(0.1),
                          Colors.orange,
                          () => Navigator.pushNamed(context, Routes.teacherAttendance),
                        ),
                        _buildActionCard(
                          context,
                          'Salary Structure',
                          Icons.attach_money,
                          Colors.green.withOpacity(0.1),
                          Colors.green,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TeacherSalaryScreen(),
                            ),
                          ),
                        ),
                        _buildActionCard(
                          context,
                          'Monthly Reports',
                          Icons.bar_chart,
                          Colors.red.withOpacity(0.1),
                          Colors.red,
                          () => _showMonthlyReports(context),
                        ),
                        _buildActionCard(
                          context,
                          'Attendance Records',
                          Icons.calendar_today_outlined,
                          Colors.teal.withOpacity(0.1),
                          Colors.teal,
                          () => _showAttendanceDetails(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Right side - Teacher attendance summary
        Expanded(
          flex: 3,
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Teacher Attendance Summary",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _teachers.length,
                      itemBuilder: (context, index) {
                        final teacher = _teachers[index];
                        final stats = _attendanceStats[teacher.id] ?? {
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
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  teacher.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'Subject: ${teacher.subject}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 12),
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
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        // Action Cards - 2x3 grid
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Teacher Management",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildActionCard(
                      context,
                      'Manage Teachers',
                      Icons.edit,
                      Colors.blue.withOpacity(0.1),
                      Colors.blue,
                      () => Navigator.pushNamed(context, Routes.manageTeachers),
                    ),
                    _buildActionCard(
                      context,
                      'Attendance',
                      Icons.calendar_today,
                      Colors.orange.withOpacity(0.1),
                      Colors.orange,
                      () => Navigator.pushNamed(context, Routes.teacherAttendance),
                    ),
                    _buildActionCard(
                      context,
                      'Salary Structure',
                      Icons.attach_money,
                      Colors.green.withOpacity(0.1),
                      Colors.green,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TeacherSalaryScreen(),
                        ),
                      ),
                    ),
                    _buildActionCard(
                      context,
                      'Monthly Reports',
                      Icons.bar_chart,
                      Colors.red.withOpacity(0.1),
                      Colors.red,
                      () => _showMonthlyReports(context),
                    ),
                    _buildActionCard(
                      context,
                      'Attendance Records',
                      Icons.calendar_today_outlined,
                      Colors.teal.withOpacity(0.1),
                      Colors.teal,
                      () => _showAttendanceDetails(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Teacher Attendance Summary
        Expanded(
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Teacher Attendance Summary",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _teachers.length,
                      itemBuilder: (context, index) {
                        final teacher = _teachers[index];
                        final stats = _attendanceStats[teacher.id] ?? {
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
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  teacher.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'Subject: ${teacher.subject}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 12),
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
            ),
          ),
        ),
      ],
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
        const SizedBox(height: 8),
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
        builder: (context) => const MonthlyReportScreen(isTeacher: true),
      ),
    );
  }
  
  void _showAttendanceDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Attendance Records',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Current Month Statistics',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: _teachers.length,
                      itemBuilder: (context, index) {
                        final teacher = _teachers[index];
                        final stats = _attendanceStats[teacher.id] ?? {
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
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  teacher.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'Subject: ${teacher.subject}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 12),
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
