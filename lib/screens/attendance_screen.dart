import 'package:flutter/material.dart';
import '../models/attendance.dart';
import '../models/student.dart';
import '../models/teacher.dart';
import '../services/database_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final DatabaseService _db = DatabaseService();
  DateTime _selectedDate = DateTime.now();
  AttendanceType _selectedType = AttendanceType.student;
  List<dynamic> _people = [];
  Map<String, AttendanceStatus> _attendance = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load people (students or teachers)
      if (_selectedType == AttendanceType.student) {
        _people = await _db.getAllStudents();
      } else {
        _people = await _db.getAllTeachers();
      }

      // Load attendance for the selected date
      final attendanceList = await _db.getAttendance(
        date: _selectedDate,
        type: _selectedType,
      );

      // Create a map of user IDs to their attendance status
      _attendance = {for (var a in attendanceList) a.userId: a.status};

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAttendance(String userId, AttendanceStatus status) async {
    try {
      final attendance = Attendance(
        id: DateTime.now()
            .toIso8601String(), // This will be replaced by Supabase
        userId: userId,
        type: _selectedType,
        date: _selectedDate,
        status: status,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final success = await _db.markAttendance(attendance);
      if (success) {
        setState(() {
          _attendance[userId] = status;
        });
      }
    } catch (e) {
      print('Error marking attendance: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() => _selectedDate = date);
                _loadData();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Type selector
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SegmentedButton<AttendanceType>(
              segments: const [
                ButtonSegment(
                  value: AttendanceType.student,
                  label: Text('Students'),
                ),
                ButtonSegment(
                  value: AttendanceType.teacher,
                  label: Text('Teachers'),
                ),
              ],
              selected: {_selectedType},
              onSelectionChanged: (Set<AttendanceType> selected) {
                setState(() => _selectedType = selected.first);
                _loadData();
              },
            ),
          ),
          // Date display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Date: ${_selectedDate.toString().split(' ')[0]}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 16),
          // List of people
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _people.isEmpty
                    ? Center(
                        child: Text(
                          _selectedType == AttendanceType.student
                              ? 'No students found. Add students first.'
                              : 'No teachers found. Add teachers first.',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      )
                    : ListView.builder(
                        itemCount: _people.length,
                        itemBuilder: (context, index) {
                          final person = _people[index];
                          final userId = person.id;
                          final name = person.name;
                          final status = _attendance[userId];

                          return Card(
                            child: ListTile(
                              title: Text(name),
                              subtitle: Text(status == null
                                  ? 'Not marked'
                                  : 'Status: ${status.toString().split('.').last}'),
                              trailing: PopupMenuButton<AttendanceStatus>(
                                initialValue: status,
                                onSelected: (AttendanceStatus status) {
                                  _markAttendance(userId, status);
                                },
                                itemBuilder: (BuildContext context) {
                                  return AttendanceStatus.values
                                      .map((AttendanceStatus status) {
                                    return PopupMenuItem<AttendanceStatus>(
                                      value: status,
                                      child: Text(
                                        status.toString().split('.').last,
                                      ),
                                    );
                                  }).toList();
                                },
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to add student/teacher screen
          Navigator.pushNamed(
            context,
            _selectedType == AttendanceType.student
                ? '/add_student'
                : '/add_teacher',
          ).then((_) => _loadData());
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
