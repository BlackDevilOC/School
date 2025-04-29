import 'package:flutter/material.dart';
import '../models/student.dart';
import '../models/attendance.dart';
import '../services/database_service.dart';

class StudentAttendanceScreen extends StatefulWidget {
  const StudentAttendanceScreen({super.key});

  @override
  _StudentAttendanceScreenState createState() =>
      _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Student> _students = [];
  List<Student> _filteredStudents = [];
  List<Attendance> _attendanceRecords = [];
  bool _isLoading = true;

  DateTime _selectedDate = DateTime.now();
  bool _isClassStudent = true;
  String _selectedClass = 'All';
  String _selectedBatch = 'All';
  bool _hasChanges = false;

  List<String> get _classGrades {
    final grades = _students
        .where((s) => s.isClassStudent)
        .map((s) => s.classGrade!)
        .toSet()
        .toList();
    grades.sort();
    return ['All', ...grades];
  }

  List<String> get _batchNumbers {
    final batches = _students
        .where((s) => !s.isClassStudent)
        .map((s) => s.batchNumber!)
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
      final students = await _databaseService.getStudents();
      final attendance = await _databaseService.getAttendanceForDate(
        _selectedDate,
      );

      setState(() {
        _students = students;
        _attendanceRecords = attendance;
        _filterStudents();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
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
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2025),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _hasChanges = false;
      });
      await _loadData();
    }
  }

  Future<void> _toggleAttendance(Student student) async {
    final existingRecord = _attendanceRecords.firstWhere(
      (a) => a.studentId == student.id,
      orElse: () => Attendance(
        id: '',
        studentId: student.id,
        attendanceDate: _selectedDate,
        status: 'Present',
        month: _selectedDate.month,
        year: _selectedDate.year,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    final newStatus = existingRecord.status == 'Present' ? 'Absent' : 'Present';

    try {
      if (existingRecord.id.isEmpty) {
        await _databaseService.addAttendance(
          Attendance(
            id: '',
            studentId: student.id,
            attendanceDate: _selectedDate,
            status: newStatus,
            month: _selectedDate.month,
            year: _selectedDate.year,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      } else {
        await _databaseService.updateAttendance(
          Attendance(
            id: existingRecord.id,
            studentId: student.id,
            attendanceDate: _selectedDate,
            status: newStatus,
            month: _selectedDate.month,
            year: _selectedDate.year,
            createdAt: existingRecord.createdAt,
            updatedAt: DateTime.now(),
          ),
        );
      }

      setState(() {
        _hasChanges = true;
      });
      await _loadData();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating attendance: $e')));
    }
  }

  String _getAttendanceStatus(String studentId) {
    final record = _attendanceRecords.firstWhere(
      (a) => a.studentId == studentId,
      orElse: () => Attendance(
        id: '',
        studentId: studentId,
        attendanceDate: _selectedDate,
        status: 'Absent',
        month: _selectedDate.month,
        year: _selectedDate.year,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    return record.status;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Attendance'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
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
                        child: ElevatedButton.icon(
                          onPressed: () => _selectDate(context),
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      SwitchListTile(
                        title: const Text('Class Students'),
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
                Expanded(
                  child: _filteredStudents.isEmpty
                      ? const Center(child: Text('No students found'))
                      : ListView.builder(
                          itemCount: _filteredStudents.length,
                          itemBuilder: (context, index) {
                            final student = _filteredStudents[index];
                            final status = _getAttendanceStatus(student.id);
                            return ListTile(
                              title: Text(student.name),
                              subtitle: Text(
                                student.isClassStudent
                                    ? 'Class: ${student.classGrade}'
                                    : 'Course: ${student.courseName}',
                              ),
                              trailing: Switch(
                                value: status == 'Present',
                                onChanged: (_) => _toggleAttendance(student),
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
