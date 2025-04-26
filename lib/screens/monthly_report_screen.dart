import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../services/data_service.dart';

class MonthlyReportScreen extends StatefulWidget {
  final bool isTeacher; // true for teacher reports, false for student reports

  const MonthlyReportScreen({super.key, required this.isTeacher});

  @override
  _MonthlyReportScreenState createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  final DataService _dataService = DataService();
  String _selectedMonth = 'January';
  String _selectedClass = 'All';
  String _searchQuery = '';
  List<Map<String, dynamic>> _filteredData = [];

  final List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  final List<String> _classes = ['All', '9th', '10th', '11th', '12th'];

  @override
  void initState() {
    super.initState();
    _updateFilteredData();
  }

  void _updateFilteredData() {
    if (widget.isTeacher) {
      _filteredData =
          _dataService.teachers.where((teacher) {
            final nameMatches = teacher['name'].toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );
            return nameMatches;
          }).toList();
    } else {
      _filteredData =
          _dataService.students.where((student) {
            final nameMatches = student['name'].toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );
            final classMatches =
                _selectedClass == 'All' ||
                student['classGrade'] == _selectedClass;
            return nameMatches && classMatches;
          }).toList();
    }
    setState(() {});
  }

  Future<void> _generateAndDownloadReport() async {
    List<List<dynamic>> rows = [];

    // Add header row
    if (widget.isTeacher) {
      rows.add(['Name', 'Subject', 'Attendance Status', 'Month']);

      // Add data rows
      for (var teacher in _filteredData) {
        rows.add([
          teacher['name'],
          teacher['subject'],
          teacher['isPresent'] ? 'Present' : 'Absent',
          _selectedMonth,
        ]);
      }
    } else {
      rows.add(['Roll Number', 'Name', 'Class', 'Attendance Status', 'Month']);

      // Add data rows
      for (var student in _filteredData) {
        rows.add([
          student['rollNumber'],
          student['name'],
          student['classGrade'],
          student['isPresent'] ? 'Present' : 'Absent',
          _selectedMonth,
        ]);
      }
    }

    String csv = const ListToCsvConverter().convert(rows);

    // Get the application documents directory
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        '${widget.isTeacher ? 'teacher' : 'student'}_attendance_${_selectedMonth.toLowerCase()}.csv';
    final file = File('${directory.path}/$fileName');

    // Write the file
    await file.writeAsString(csv);

    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report saved as $fileName'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.isTeacher ? 'Teacher' : 'Student'} Monthly Report',
        ),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Month Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedMonth,
                  decoration: const InputDecoration(
                    labelText: 'Select Month',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      _months.map((String month) {
                        return DropdownMenuItem(
                          value: month,
                          child: Text(month),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedMonth = newValue;
                        _updateFilteredData();
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Class Dropdown (only for students)
                if (!widget.isTeacher) ...[
                  DropdownButtonFormField<String>(
                    value: _selectedClass,
                    decoration: const InputDecoration(
                      labelText: 'Select Class',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        _classes.map((String classGrade) {
                          return DropdownMenuItem(
                            value: classGrade,
                            child: Text(classGrade),
                          );
                        }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedClass = newValue;
                          _updateFilteredData();
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Search by name',
                    border: const OutlineInputBorder(),
                    suffixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _updateFilteredData();
                    });
                  },
                ),
              ],
            ),
          ),

          // Data Table
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns:
                      widget.isTeacher
                          ? const [
                            DataColumn(label: Text('Name')),
                            DataColumn(label: Text('Subject')),
                            DataColumn(label: Text('Status')),
                          ]
                          : const [
                            DataColumn(label: Text('Roll No')),
                            DataColumn(label: Text('Name')),
                            DataColumn(label: Text('Class')),
                            DataColumn(label: Text('Status')),
                          ],
                  rows:
                      _filteredData.map((data) {
                        if (widget.isTeacher) {
                          return DataRow(
                            cells: [
                              DataCell(Text(data['name'])),
                              DataCell(Text(data['subject'])),
                              DataCell(
                                Text(data['isPresent'] ? 'Present' : 'Absent'),
                              ),
                            ],
                          );
                        } else {
                          return DataRow(
                            cells: [
                              DataCell(Text(data['rollNumber'].toString())),
                              DataCell(Text(data['name'])),
                              DataCell(Text(data['classGrade'])),
                              DataCell(
                                Text(data['isPresent'] ? 'Present' : 'Absent'),
                              ),
                            ],
                          );
                        }
                      }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generateAndDownloadReport,
        label: const Text('Download CSV'),
        icon: const Icon(Icons.download),
        backgroundColor: Colors.green,
      ),
    );
  }
}
