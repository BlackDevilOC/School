import 'package:flutter/material.dart';
import '../routes.dart';
import 'monthly_report_screen.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';
import '../models/student.dart';
import '../models/attendance.dart';

class StudentRecordScreen extends StatefulWidget {
  const StudentRecordScreen({super.key});

  @override
  State<StudentRecordScreen> createState() => _StudentRecordScreenState();
}

class _StudentRecordScreenState extends State<StudentRecordScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final SyncService _syncService = SyncService(DatabaseService());
  bool _isLoading = true;
  List<Student> _students = [];
  List<Attendance> _attendanceRecords = [];
  Map<String, Map<String, int>> _attendanceStats = {};
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load cached data first
      final cachedStudents = await _syncService.getStudentsWithCache();
      final cachedStats = await _syncService.getAttendanceStatsWithCache(cachedStudents);
      
      if (cachedStudents.isNotEmpty) {
        setState(() {
          _students = cachedStudents;
          _attendanceStats = cachedStats;
          _isLoading = false;
        });
      }
      
      // Load fresh data
      final students = await _databaseService.getStudents();
      final today = DateTime.now();
      final attendance = await _databaseService.getAttendanceForDate(today);
      final stats = await _calculateAttendanceStats(students);
      
      if (mounted) {
        setState(() {
          _students = students;
          _attendanceRecords = attendance;
          _attendanceStats = stats;
          _isLoading = false;
        });
      }
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
      backgroundColor: Colors.grey[100],
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
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading && _students.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              controller: _scrollController,
              child: Container(
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
                            Text(
                              "Today's Attendance",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 16),
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
                    SizedBox(height: 24),
                    SizedBox(
                      height: MediaQuery.of(context).size.height - 300,
                      child: MediaQuery.of(context).size.width > 800
                          ? _buildWebLayout(context)
                          : _buildMobileLayout(context),
                    ),
                  ],
                ),
              ),
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
                  Text(
                    "Student Management",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      childAspectRatio: 1.2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        _buildActionCard(
                          context,
                          'Manage Students',
                          Icons.edit,
                          Colors.blue.withOpacity(0.1),
                          Colors.blue,
                          () => Navigator.pushNamed(context, Routes.manageStudents),
                        ),
                        _buildActionCard(
                          context,
                          'Attendance',
                          Icons.calendar_today,
                          Colors.orange.withOpacity(0.1),
                          Colors.orange,
                          () => Navigator.pushNamed(context, Routes.studentAttendance),
                        ),
                        _buildActionCard(
                          context,
                          'Fee Structure',
                          Icons.attach_money,
                          Colors.green.withOpacity(0.1),
                          Colors.green,
                          () => Navigator.pushNamed(context, Routes.feeStructure),
                        ),
                        _buildActionCard(
                          context,
                          'Fee Records',
                          Icons.receipt_long,
                          Colors.purple.withOpacity(0.1),
                          Colors.purple,
                          () => Navigator.pushNamed(context, Routes.feeRecords),
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
        SizedBox(width: 16),
        // Right side - Student attendance summary
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
                  Text(
                    "Student Attendance Summary",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
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
                Text(
                  "Student Management",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildActionCard(
                      context,
                      'Manage Students',
                      Icons.edit,
                      Colors.blue.withOpacity(0.1),
                      Colors.blue,
                      () => Navigator.pushNamed(context, Routes.manageStudents),
                    ),
                    _buildActionCard(
                      context,
                      'Attendance',
                      Icons.calendar_today,
                      Colors.orange.withOpacity(0.1),
                      Colors.orange,
                      () => Navigator.pushNamed(context, Routes.studentAttendance),
                    ),
                    _buildActionCard(
                      context,
                      'Fee Structure',
                      Icons.attach_money,
                      Colors.green.withOpacity(0.1),
                      Colors.green,
                      () => Navigator.pushNamed(context, Routes.feeStructure),
                    ),
                    _buildActionCard(
                      context,
                      'Fee Records',
                      Icons.receipt_long,
                      Colors.purple.withOpacity(0.1),
                      Colors.purple,
                      () => Navigator.pushNamed(context, Routes.feeRecords),
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
        SizedBox(height: 16),
        // Student Attendance Summary
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
                  Text(
                    "Student Attendance Summary",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
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
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                // Background design element
                Positioned(
                  right: -10,
                  bottom: -10,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 24, color: iconColor),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
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
