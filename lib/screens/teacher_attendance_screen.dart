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
      final String id = teachers[index]['id'];
      final bool newValue = !teachers[index]['isPresent'];

      // Update the local state
      teachers[index]['isPresent'] = newValue;

      // Update in the data service
      _dataService.updateTeacherAttendance(id, newValue);
    });
  }

  void _submitAttendance() {
    // In a real app, this would save the attendance data to a database
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Teacher attendance submitted successfully'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Attendance'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          _buildAttendanceHeaderRow(),
          Expanded(child: _buildAttendanceList()),
          _buildSubmitButton(),
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
      child: const Row(
        children: [
          Expanded(
            flex: 2,
            child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Subject',
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
      itemCount: teachers.length,
      itemBuilder: (context, index) {
        final teacher = teachers[index];
        final bool isPresent = teacher['isPresent'] ?? false;

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
