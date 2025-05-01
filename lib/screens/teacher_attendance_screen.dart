import 'package:flutter/material.dart';
import '../services/data_service.dart';

class TeacherAttendanceScreen extends StatefulWidget {
  const TeacherAttendanceScreen({super.key});

  @override
  _TeacherAttendanceScreenState createState() =>
      _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends State<TeacherAttendanceScreen> {
  final DataService _dataService = DataService();
  late List<Map<String, dynamic>> teachers;
  DateTime _selectedDate = DateTime.now();
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    teachers = _dataService.teachers;
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
      final teacher = teachers[index];
      final String id = teacher['id'];
      final bool newValue = !(teacher['isPresent'] ?? false);

      teacher['isPresent'] = newValue;
      _dataService.updateTeacher(id, teacher);
      _hasChanges = true;

      // Show a subtle indicator that the change was saved
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${teacher['name']}\'s attendance marked as ${newValue ? 'Present' : 'Absent'}',
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
        title: const Text('Teacher Attendance'),
        backgroundColor: Colors.green.shade600,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildDateSelector(),
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
              'ID',
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
              'Subject',
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
    if (teachers.isEmpty) {
      return Center(
        child: Text(
          'No teachers found',
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
        ),
      );
    }

    return ListView.builder(
      itemCount: teachers.length,
      itemBuilder: (context, index) {
        final teacher = teachers[index];
        final bool isPresent = teacher['isPresent'] ?? false;

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
                    '${teacher['id']}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '${teacher['name']}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '${teacher['subject']}',
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
