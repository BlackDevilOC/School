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
  bool _isClassStudent = true; // Default to class students
  String _selectedClass = 'All';
  String _selectedBatch = 'All';

  // Get unique class grades
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

  // Get unique batch numbers
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

      // Update the local state
      student['isPresent'] = newValue;

      // Update in the data service
      _dataService.updateStudentAttendance(id, newValue);
    });
  }

  void _submitAttendance() {
    // In a real app, this would save the attendance data to a database
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Attendance submitted successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Attendance'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          _buildFilterOptions(),
          _buildAttendanceHeaderRow(),
          Expanded(child: _buildAttendanceList()),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildFilterOptions() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: RadioListTile<bool>(
                  title: Text('Class Students'),
                  value: true,
                  groupValue: _isClassStudent,
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
                  title: Text('Course Students'),
                  value: false,
                  groupValue: _isClassStudent,
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
          SizedBox(height: 8),
          if (_isClassStudent)
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Filter by Class',
                border: OutlineInputBorder(),
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
                border: OutlineInputBorder(),
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

  Widget _buildDateSelector() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          ElevatedButton.icon(
            onPressed: () => _selectDate(context),
            icon: const Icon(Icons.calendar_today),
            label: const Text('Select Date'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceHeaderRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Colors.grey.shade200,
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              'Roll No.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _isClassStudent ? 'Class' : 'Course/Batch',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'Status',
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList() {
    return ListView.builder(
      itemCount: filteredStudents.length,
      itemBuilder: (context, index) {
        final student = filteredStudents[index];
        final bool isPresent = student['isPresent'] ?? false;

        return GestureDetector(
          onTap: () => _toggleAttendance(index),
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            color: isPresent ? Colors.green.shade100 : Colors.red.shade100,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
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
                        Switch(
                          value: isPresent,
                          onChanged: (_) => _toggleAttendance(index),
                          activeColor: Colors.green,
                        ),
                        Text(
                          isPresent ? 'P' : 'A',
                          style: TextStyle(
                            color: isPresent ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubmitButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: _submitAttendance,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          minimumSize: const Size(double.infinity, 50),
        ),
        child: const Text('Submit Attendance', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
