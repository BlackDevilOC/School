import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../services/database_service.dart';
import '../models/student.dart';
import 'package:intl/intl.dart';

class MonthlyReportScreen extends StatefulWidget {
  final bool isTeacher;

  const MonthlyReportScreen({super.key, required this.isTeacher});

  @override
  _MonthlyReportScreenState createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  final DatabaseService _databaseService = DatabaseService();
  String _selectedMonth = 'January';
  String _selectedClass = 'All';
  String _searchQuery = '';
  List<Student> _students = [];
  Map<String, Map<int, String>> _studentAttendance = {};
  bool _isLoading = true;
  bool _isClassStudent = true; // Default to class students

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

  // Get unique class grades
  List<String> get _classGrades {
    final grades = _students
        .where((s) => s.isClassStudent)
        .map((s) => s.classGrade)
        .where((grade) => grade != null)
        .map((grade) => grade!)
        .toSet()
        .toList();
    grades.sort();
    return ['All', ...grades];
  }

  // Get number of days in selected month (using current year)
  int get _daysInMonth {
    final now = DateTime.now();
    final monthIndex = _months.indexOf(_selectedMonth) + 1;
    return DateTime(now.year, monthIndex + 1, 0).day;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load students
      final students = await _databaseService.getStudents();
      
      // Get current month and year
      final now = DateTime.now();
      final currentMonthIndex = now.month - 1; // 0-based index
      
      setState(() {
        _selectedMonth = _months[currentMonthIndex];
        _students = students;
      });
      
      // Load attendance data for the selected month
      await _loadAttendanceData();
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _loadAttendanceData() async {
    try {
      final monthIndex = _months.indexOf(_selectedMonth) + 1;
      final year = DateTime.now().year;
      
      // Create a map to store attendance by student and day
      final attendanceMap = <String, Map<int, String>>{};
      
      // Initialize the map for all students
      for (final student in _students) {
        attendanceMap[student.id] = {};
      }
      
      // Get all attendance records for the month
      
      // For each day in the month
      for (int day = 1; day <= _daysInMonth; day++) {
        final date = DateTime(year, monthIndex, day);
        final dayAttendance = await _databaseService.getAttendanceForDate(date);
        
        // Add each record to the map
        for (final record in dayAttendance) {
          final day = record.attendanceDate.day;
          attendanceMap[record.studentId] ??= {};
          attendanceMap[record.studentId]![day] = record.status;
        }
      }
      
      if (mounted) {
        setState(() {
          _studentAttendance = attendanceMap;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading attendance data: $e')),
        );
      }
    }
  }

  List<Student> get _filteredStudents {
    return _students.where((student) {
      final nameMatches = student.name.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );

      // Filter by student type first
      if (student.isClassStudent != _isClassStudent) return false;

      // Then filter by class
      if (_isClassStudent) {
        return (_selectedClass == 'All' || student.classGrade == _selectedClass) && nameMatches;
      } else {
        return nameMatches;
      }
    }).toList();
  }

  Future<void> _generateAndDownloadReport() async {
    List<List<dynamic>> rows = [];

    // Generate header row with dates
    List<dynamic> headerRow = ['Name'];

    if (_isClassStudent) {
      headerRow.add('Class');
    } else {
      headerRow.add('Course');
    }
    headerRow.add('Roll Number');

    // Add date columns
    for (int i = 1; i <= _daysInMonth; i++) {
      headerRow.add(i.toString());
    }
    rows.add(headerRow);

    // Add data rows
    for (var student in _filteredStudents) {
      List<dynamic> row = [student.name];

      if (_isClassStudent) {
        row.add(student.classGrade ?? '');
      } else {
        row.add(student.courseName ?? '');
      }
      
      // Add roll number
      row.add(student.rollNumber);

      // Add attendance for each day
      for (int day = 1; day <= _daysInMonth; day++) {
        final status = _getAttendanceStatus(student.id, day);
        row.add(status);
      }
      
      rows.add(row);
    }

    // Generate CSV
    String csv = const ListToCsvConverter().convert(rows);

    // Get directory
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;
    final formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final file = File('$path/attendance_report_$formattedDate.csv');

    // Write to file
    await file.writeAsString(csv);

    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report saved to ${file.path}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
  
  // Get attendance status for a student on a specific day
  String _getAttendanceStatus(String studentId, int day) {
    final studentDayAttendance = _studentAttendance[studentId];
    if (studentDayAttendance == null || !studentDayAttendance.containsKey(day)) {
      return '-'; // No record
    }
    
    final status = studentDayAttendance[day]!;
    
    // Convert database status to display status
    if (status == 'Excused') return 'L'; // Leave
    return status[0]; // First letter (P for Present, A for Absent)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Monthly Report'),
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filter Controls
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Month Dropdown
                      Container(
                        width: 150,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedMonth,
                            isExpanded: true,
                            hint: const Text('Month'),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedMonth = newValue;
                                });
                                _loadAttendanceData();
                              }
                            },
                            items: _months
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        ),
                      ),

                      // Student Type Radio Buttons
                      Row(
                        children: [
                          Radio<bool>(
                            value: true,
                            groupValue: _isClassStudent,
                            onChanged: (bool? value) {
                              if (value != null) {
                                setState(() {
                                  _isClassStudent = value;
                                  _selectedClass = 'All';
                                });
                              }
                            },
                          ),
                          const Text('Class Students'),
                          Radio<bool>(
                            value: false,
                            groupValue: _isClassStudent,
                            onChanged: (bool? value) {
                              if (value != null) {
                                setState(() {
                                  _isClassStudent = value;
                                });
                              }
                            },
                          ),
                          const Text('Course Students'),
                        ],
                      ),

                      // Class Dropdown (only show for class students)
                      if (_isClassStudent)
                        Container(
                          width: 150,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedClass,
                              isExpanded: true,
                              hint: const Text('Class'),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedClass = newValue;
                                  });
                                }
                              },
                              items: _classGrades
                                  .map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                            ),
                          ),
                        ),

                      // Search Field
                      SizedBox(
                        width: 200,
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: 'Search',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Legend
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      _buildLegendItem('P', Colors.green, 'Present'),
                      const SizedBox(width: 16),
                      _buildLegendItem('A', Colors.red, 'Absent'),
                      const SizedBox(width: 16),
                      _buildLegendItem('L', Colors.blue, 'Leave'),
                      const SizedBox(width: 16),
                      _buildLegendItem('-', Colors.grey, 'No Record'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Data Table
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 20,
                        headingRowHeight: 40,
                        dataRowHeight: 40,
                        columns: _buildColumns(),
                        rows: _buildRows(),
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

  Widget _buildLegendItem(String symbol, Color color, String label) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              symbol,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }

  List<DataColumn> _buildColumns() {
    List<DataColumn> columns = [const DataColumn(label: Text('Name'))];

    if (_isClassStudent) {
      columns.add(const DataColumn(label: Text('Class')));
    } else {
      columns.add(const DataColumn(label: Text('Course')));
    }
    
    columns.add(const DataColumn(label: Text('Roll No.')));

    // Add date columns
    for (int i = 1; i <= _daysInMonth; i++) {
      columns.add(
        DataColumn(
          label: Text(
            i.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return columns;
  }

  List<DataRow> _buildRows() {
    return _filteredStudents.map((student) {
      List<DataCell> cells = [DataCell(Text(student.name))];

      if (_isClassStudent) {
        cells.add(DataCell(Text(student.classGrade ?? '')));
      } else {
        cells.add(DataCell(Text(student.courseName ?? '')));
      }
      
      // Add roll number
      cells.add(DataCell(Text(student.rollNumber)));

      // Add attendance cells for each day
      for (int day = 1; day <= _daysInMonth; day++) {
        final status = _getAttendanceStatus(student.id, day);
        
        // Set color based on status
        Color textColor = Colors.grey;
        if (status == 'P') textColor = Colors.green;
        else if (status == 'A') textColor = Colors.red;
        else if (status == 'L') textColor = Colors.blue;

        cells.add(
          DataCell(
            Text(
              status,
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }

      return DataRow(cells: cells);
    }).toList();
  }
}
