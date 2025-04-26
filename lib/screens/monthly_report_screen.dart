import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../services/data_service.dart';

class MonthlyReportScreen extends StatefulWidget {
  final bool isTeacher;

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
  bool _showFullStatus =
      false; // Changed to false for minimal format by default

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

  // Get number of days in selected month (using 2024 as it's a leap year)
  int get _daysInMonth {
    final monthIndex = _months.indexOf(_selectedMonth) + 1;
    return DateTime(2024, monthIndex + 1, 0).day;
  }

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

    // Generate header row with dates
    List<dynamic> headerRow =
        widget.isTeacher
            ? ['Name', 'Subject']
            : ['Name', 'Father Name', 'Class'];

    // Add date columns
    for (int i = 1; i <= _daysInMonth; i++) {
      headerRow.add(i.toString());
    }
    rows.add(headerRow);

    // Add data rows
    for (var data in _filteredData) {
      List<dynamic> row =
          widget.isTeacher
              ? [data['name'], data['subject']]
              : [data['name'], data['fatherName'] ?? 'N/A', data['classGrade']];

      // Add dummy attendance data for each day
      for (int i = 1; i <= _daysInMonth; i++) {
        // This is dummy data - replace with actual attendance data when implementing database
        row.add(data['isPresent'] ? 'P' : 'A');
      }
      rows.add(row);
    }

    String csv = const ListToCsvConverter().convert(rows);

    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        '${widget.isTeacher ? 'teacher' : 'student'}_attendance_${_selectedMonth.toLowerCase()}.csv';
    final file = File('${directory.path}/$fileName');

    await file.writeAsString(csv);

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
        actions: [
          // Toggle button for attendance display format
          IconButton(
            icon: Icon(
              _showFullStatus ? Icons.short_text : Icons.format_list_bulleted,
            ),
            onPressed: () {
              setState(() {
                _showFullStatus = !_showFullStatus;
              });
            },
            tooltip:
                _showFullStatus ? 'Show minimal format' : 'Show full format',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              alignment: WrapAlignment.start,
              children: [
                // Month Dropdown
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<String>(
                    value: _selectedMonth,
                    decoration: const InputDecoration(
                      labelText: 'Month',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
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
                ),

                // Class Dropdown (only for students)
                if (!widget.isTeacher)
                  SizedBox(
                    width: 150,
                    child: DropdownButtonFormField<String>(
                      value: _selectedClass,
                      decoration: const InputDecoration(
                        labelText: 'Class',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
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
                  ),

                // Search Bar
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
                      prefixIcon: Icon(Icons.search, size: 20),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _updateFilteredData();
                      });
                    },
                  ),
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

  List<DataColumn> _buildColumns() {
    List<DataColumn> columns =
        widget.isTeacher
            ? [
              const DataColumn(label: Text('Name')),
              const DataColumn(label: Text('Subject')),
            ]
            : [
              const DataColumn(label: Text('Name')),
              const DataColumn(label: Text('Father Name')),
              const DataColumn(label: Text('Class')),
            ];

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
    return _filteredData.map((data) {
      List<DataCell> cells =
          widget.isTeacher
              ? [DataCell(Text(data['name'])), DataCell(Text(data['subject']))]
              : [
                DataCell(Text(data['name'])),
                DataCell(Text(data['fatherName'] ?? 'N/A')),
                DataCell(Text(data['classGrade'])),
              ];

      // Add attendance cells for each day
      for (int i = 1; i <= _daysInMonth; i++) {
        // This is dummy data - replace with actual attendance data when implementing database
        final isPresent = data['isPresent'];
        final attendanceText =
            _showFullStatus
                ? (isPresent ? 'Present' : 'Absent')
                : (isPresent ? 'P' : 'A');
        final textColor = isPresent ? Colors.green : Colors.red;

        cells.add(
          DataCell(
            Text(
              attendanceText,
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }

      return DataRow(cells: cells);
    }).toList();
  }
}
