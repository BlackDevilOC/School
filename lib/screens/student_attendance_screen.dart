import 'package:flutter/material.dart';
import '../models/student.dart';
import '../models/attendance.dart';
import '../services/database_service.dart';
import 'package:uuid/uuid.dart';

class StudentAttendanceScreen extends StatefulWidget {
  const StudentAttendanceScreen({super.key});

  @override
  _StudentAttendanceScreenState createState() =>
      _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final Uuid _uuid = const Uuid();
  List<Student> _students = [];
  List<Student> _filteredStudents = [];
  List<Attendance> _attendanceRecords = [];
  bool _isLoading = true;
  bool _isLoadingAttendance = false;

  DateTime _selectedDate = DateTime.now();
  bool _isClassStudent = true;
  String _selectedClass = 'All';
  String _selectedBatch = 'All';
  bool _hasChanges = false;

  // Define attendance status options and their colors - only using Present, Absent, and Excused (for Leave)
  final Map<String, Color> _statusColors = {
    'Present': Colors.green,
    'Absent': Colors.red,
    'Excused': Colors
        .blue, // Using Excused instead of Leave to match database constraint
  };

  // Map for display names (what user sees) vs actual values (what's stored in DB)
  final Map<String, String> _statusDisplayNames = {
    'Present': 'Present',
    'Absent': 'Absent',
    'Excused': 'Leave', // Display "Leave" but store as "Excused"
  };

  List<String> get _classGrades {
    final grades = _students
        .where((s) => s.isClassStudent)
        .map((s) => s.classGrade!)
        .where((grade) => grade.isNotEmpty)
        .toSet()
        .toList();
    grades.sort();
    return ['All', ...grades];
  }

  List<String> get _batchNumbers {
    final batches = _students
        .where((s) => !s.isClassStudent)
        .map((s) => s.batchNumber!)
        .where((batch) => batch.isNotEmpty)
        .toSet()
        .toList();
    batches.sort();
    return ['All', ...batches];
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load students from Supabase
      await _loadStudents();

      // Load attendance records for the selected date
      await _loadAttendanceForDate();

      // Filter students based on current selection
      _filterStudents();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  Future<void> _loadStudents() async {
    try {
      final students = await _databaseService.getStudents();
      setState(() {
        _students = students;
      });
      print('Loaded ${students.length} students from Supabase');
    } catch (e) {
      print('Error loading students: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading students: $e')),
      );
      rethrow;
    }
  }

  Future<void> _loadAttendanceForDate() async {
    setState(() => _isLoadingAttendance = true);
    try {
      final attendance =
          await _databaseService.getAttendanceForDate(_selectedDate);
      setState(() {
        _attendanceRecords = attendance;
        _isLoadingAttendance = false;
      });
      print(
          'Loaded ${attendance.length} attendance records for ${_selectedDate.toIso8601String().split('T')[0]}');
    } catch (e) {
      setState(() => _isLoadingAttendance = false);
      print('Error loading attendance: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading attendance records: $e')),
      );
      rethrow;
    }
  }

  void _filterStudents() {
    setState(() {
      _filteredStudents = _students.where((student) {
        if (student.isClassStudent != _isClassStudent) return false;

        if (_isClassStudent) {
          return _selectedClass == 'All' ||
              student.classGrade == _selectedClass;
        } else {
          return _selectedBatch == 'All' ||
              student.batchNumber == _selectedBatch;
        }
      }).toList();
    });

    print('Filtered to ${_filteredStudents.length} students');
  }

  Future<void> _updateAttendanceStatus(
      Student student, String newStatus) async {
    // Find existing attendance record for this student on the selected date
    final existingRecordIndex = _attendanceRecords.indexWhere(
      (a) => a.studentId == student.id,
    );

    final bool isNewRecord = existingRecordIndex == -1;

    try {
      if (isNewRecord) {
        // Create a new attendance record
        await _databaseService.addAttendance(
          Attendance(
            id: _uuid.v4(),
            studentId: student.id,
            attendanceDate: _selectedDate,
            status: newStatus,
            // Don't set month and year as they are generated in the database
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      } else {
        // Update existing record
        final existingRecord = _attendanceRecords[existingRecordIndex];
        await _databaseService.updateAttendance(
          Attendance(
            id: existingRecord.id,
            studentId: student.id,
            attendanceDate: _selectedDate,
            status: newStatus,
            // Include month and year from existing record for updates
            month: existingRecord.month,
            year: existingRecord.year,
            createdAt: existingRecord.createdAt,
            updatedAt: DateTime.now(),
          ),
        );
      }

      setState(() => _hasChanges = true);
      await _loadAttendanceForDate();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating attendance: $e')),
      );
    }
  }

  String _getAttendanceStatus(String studentId) {
    final recordIndex = _attendanceRecords.indexWhere(
      (a) => a.studentId == studentId,
    );

    // If no record found, default to "Absent"
    if (recordIndex == -1) {
      return 'Absent';
    }

    return _attendanceRecords[recordIndex].status;
  }

  // Show a dialog to select attendance status
  Future<void> _showStatusSelectionDialog(Student student) async {
    final currentStatus = _getAttendanceStatus(student.id);

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Update Attendance for ${student.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _statusColors.keys.map((status) {
                final displayName = _statusDisplayNames[status] ?? status;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _statusColors[status],
                    child: Text(
                      displayName[0], // First letter of display name (P, A, L)
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(displayName),
                  selected: currentStatus == status,
                  onTap: () {
                    Navigator.of(context).pop();
                    _updateAttendanceStatus(student, status);
                  },
                );
              }).toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Get status indicator widget
  Widget _getStatusIndicator(String status) {
    final color = _statusColors[status] ?? Colors.grey;
    final displayName = _statusDisplayNames[status] ?? status;
    return CircleAvatar(
      radius: 15,
      backgroundColor: color,
      child: Text(
        displayName[0], // First letter of display name (P, A, L)
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Attendance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Text(
                            'Today: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 180,
                        child: Row(
                          children: [
                            Switch(
                              value: _isClassStudent,
                              onChanged: (value) {
                                setState(() {
                                  _isClassStudent = value;
                                  _selectedClass = 'All';
                                  _selectedBatch = 'All';
                                });
                                _filterStudents();
                              },
                            ),
                            const SizedBox(width: 8),
                            Text(_isClassStudent ? 'Class' : 'Course'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isClassStudent)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: DropdownButtonFormField<String>(
                      value: _selectedClass,
                      items: _classGrades.map((grade) {
                        return DropdownMenuItem(
                          value: grade,
                          child: Text(grade),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedClass = value!);
                        _filterStudents();
                      },
                      decoration: const InputDecoration(
                        labelText: 'Select Class',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: DropdownButtonFormField<String>(
                      value: _selectedBatch,
                      items: _batchNumbers.map((batch) {
                        return DropdownMenuItem(
                          value: batch,
                          child: Text(batch),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedBatch = value!);
                        _filterStudents();
                      },
                      decoration: const InputDecoration(
                        labelText: 'Select Batch',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                // Display attendance status legend
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _statusColors.entries.map((entry) {
                      final displayName =
                          _statusDisplayNames[entry.key] ?? entry.key;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 10,
                              backgroundColor: entry.value,
                              child: Text(
                                displayName[0],
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(displayName),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                _isLoadingAttendance
                    ? const Center(child: CircularProgressIndicator())
                    : Expanded(
                        child: _filteredStudents.isEmpty
                            ? const Center(child: Text('No students found'))
                            : ListView.builder(
                                itemCount: _filteredStudents.length,
                                itemBuilder: (context, index) {
                                  final student = _filteredStudents[index];
                                  final status =
                                      _getAttendanceStatus(student.id);
                                  return ListTile(
                                    title: Text(student.name),
                                    subtitle: Text(
                                      student.isClassStudent
                                          ? 'Class: ${student.classGrade}'
                                          : 'Course: ${student.courseName}',
                                    ),
                                    trailing: InkWell(
                                      onTap: () =>
                                          _showStatusSelectionDialog(student),
                                      child: _getStatusIndicator(status),
                                    ),
                                  );
                                },
                              ),
                      ),
              ],
            ),
    );
  }
}
