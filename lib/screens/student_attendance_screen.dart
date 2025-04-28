import 'package:flutter/material.dart';
import '../services/data_service.dart';

class StudentAttendanceScreen extends StatefulWidget {
  const StudentAttendanceScreen({super.key});

  @override
  _StudentAttendanceScreenState createState() =>
      _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  final DataService _dataService = DataService();
  late List<Map<String, dynamic>> students;
  late List<Map<String, dynamic>> filteredStudents;

  DateTime _selectedDate = DateTime.now();
  bool _isClassStudent = true;
  String _selectedClass = 'All';
  String _selectedBatch = 'All';
  bool _hasChanges = false;

  List<String> get _classGrades {
    final grades =
        students
            .where((s) => s['isClassStudent'] == true)
            .map((s) => s['classGrade'] as String)
            .toSet()
            .toList();
    grades.sort();
    return ['All', ...grades];
  }

  List<String> get _batchNumbers {
    final batches =
        students
            .where((s) => s['isClassStudent'] == false)
            .map((s) => s['batchNumber'] as String)
            .toSet()
            .toList();
    batches.sort();
    return ['All', ...batches];
  }

  @override
  void initState() {
    super.initState();
    students = _dataService.students;
    _filterStudents();
  }

  void _filterStudents() {
    setState(() {
      filteredStudents =
          students.where((student) {
            final isCorrectType = student['isClassStudent'] == _isClassStudent;
            if (!isCorrectType) return false;

            if (_isClassStudent) {
              return _selectedClass == 'All' ||
                  student['classGrade'] == _selectedClass;
            } else {
              return _selectedBatch == 'All' ||
                  student['batchNumber'] == _selectedBatch;
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
      });
    }
  }

  void _toggleAttendance(int index) {
    setState(() {
      final student = filteredStudents[index];
      final String id = student['id'];
      final bool newValue = !student['isPresent'];

      student['isPresent'] = newValue;
      _dataService.updateStudentAttendance(id, newValue);
      _hasChanges = true;

      // Show a subtle indicator that the change was saved
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${student['name']}\'s attendance marked as ${newValue ? 'Present' : 'Absent'}',
          ),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          backgroundColor:
              newValue ? Colors.green.shade700 : Colors.red.shade700,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Attendance'),
        backgroundColor: Colors.green.shade600,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          _buildFilterOptions(),
          _buildAttendanceHeaderRow(),
          Expanded(child: _buildAttendanceList()),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border(bottom: BorderSide(color: Colors.green.shade100)),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today, color: Colors.green.shade700, size: 20),
          const SizedBox(width: 12),
          Text(
            'Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.green.shade900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOptions() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: RadioListTile<bool>(
                  title: const Text('Class Students'),
                  value: true,
                  groupValue: _isClassStudent,
                  activeColor: Colors.green.shade700,
                  onChanged: (bool? value) {
                    if (value != null) {
                      setState(() {
                        _isClassStudent = value;
                        _selectedClass = 'All';
                        _selectedBatch = 'All';
                        _filterStudents();
                      });
                    }
                  },
                ),
              ),
              Expanded(
                child: RadioListTile<bool>(
                  title: const Text('Course Students'),
                  value: false,
                  groupValue: _isClassStudent,
                  activeColor: Colors.green.shade700,
                  onChanged: (bool? value) {
                    if (value != null) {
                      setState(() {
                        _isClassStudent = value;
                        _selectedClass = 'All';
                        _selectedBatch = 'All';
                        _filterStudents();
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_isClassStudent)
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Filter by Class',
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              value: _selectedClass,
              items:
                  _classGrades
                      .map(
                        (grade) =>
                            DropdownMenuItem(value: grade, child: Text(grade)),
                      )
                      .toList(),
              onChanged: (String? value) {
                if (value != null) {
                  setState(() {
                    _selectedClass = value;
                    _filterStudents();
                  });
                }
              },
            )
          else
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Filter by Batch',
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              value: _selectedBatch,
              items:
                  _batchNumbers
                      .map(
                        (batch) =>
                            DropdownMenuItem(value: batch, child: Text(batch)),
                      )
                      .toList(),
              onChanged: (String? value) {
                if (value != null) {
                  setState(() {
                    _selectedBatch = value;
                    _filterStudents();
                  });
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAttendanceHeaderRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              'Roll No.',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Name',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _isClassStudent ? 'Class' : 'Course/Batch',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'Status',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList() {
    if (filteredStudents.isEmpty) {
      return Center(
        child: Text(
          'No students found for the selected filter',
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredStudents.length,
      itemBuilder: (context, index) {
        final student = filteredStudents[index];
        final bool isPresent = student['isPresent'] ?? false;

        return InkWell(
          onTap: () => _toggleAttendance(index),
          child: Container(
            decoration: BoxDecoration(
              color: isPresent ? Colors.green.shade50 : Colors.red.shade50,
              border: Border(
                bottom: BorderSide(
                  color:
                      isPresent ? Colors.green.shade100 : Colors.red.shade100,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Text(
                    '${student['rollNumber']}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '${student['name']}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    _isClassStudent
                        ? '${student['classGrade']}'
                        : '${student['courseName']}\n${student['batchNumber']}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isPresent
                                  ? Colors.green.shade100
                                  : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                isPresent
                                    ? Colors.green.shade300
                                    : Colors.red.shade300,
                          ),
                        ),
                        child: Text(
                          isPresent ? 'P' : 'A',
                          style: TextStyle(
                            color:
                                isPresent
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
