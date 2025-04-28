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
  String _selectedBatch = 'All';
  String _searchQuery = '';
  List<Map<String, dynamic>> _filteredData = [];
  bool _showFullStatus = false;
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
    final grades =
        _dataService.students
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
        _dataService.students
            .where((s) => s['isClassStudent'] == false)
            .map((s) => s['batchNumber'] as String)
            .toSet()
            .toList();
    batches.sort();
    return ['All', ...batches];
  }

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

            // Filter by student type first
            if (student['isClassStudent'] != _isClassStudent) return false;

            // Then filter by class or batch
            if (_isClassStudent) {
              return _selectedClass == 'All' ||
                  student['classGrade'] == _selectedClass;
            } else {
              return _selectedBatch == 'All' ||
                  student['batchNumber'] == _selectedBatch;
            }
          }).toList();
    }
    setState(() {});
  }

  Future<void> _generateAndDownloadReport() async {
    List<List<dynamic>> rows = [];

    // Generate header row with dates
    List<dynamic> headerRow = ['Name'];

    if (widget.isTeacher) {
      headerRow.add('Subject');
    } else {
      if (_isClassStudent) {
        headerRow.add('Class');
      } else {
        headerRow.add('Course');
        headerRow.add('Batch');
      }
      headerRow.add('Fee Status');
    }

    // Add date columns
    for (int i = 1; i <= _daysInMonth; i++) {
      headerRow.add(i.toString());
    }
    rows.add(headerRow);

    // Add data rows
    for (var data in _filteredData) {
      List<dynamic> row = [data['name']];

      if (widget.isTeacher) {
        row.add(data['subject']);
      } else {
        if (_isClassStudent) {
          row.add(data['classGrade']);
        } else {
          row.add(data['courseName']);
          row.add(data['batchNumber']);
        }
        // Add fee status
        final feeAmount = data['feeAmount']?.toString() ?? 'N/A';
        row.add('\$$feeAmount');
      }

      // Add dummy attendance data for each day
      for (int i = 1; i <= _daysInMonth; i++) {
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

                if (!widget.isTeacher) ...[
                  // Student Type Radio Buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Radio<bool>(
                        value: true,
                        groupValue: _isClassStudent,
                        onChanged: (bool? value) {
                          if (value != null) {
                            setState(() {
                              _isClassStudent = value;
                              _selectedClass = 'All';
                              _selectedBatch = 'All';
                              _updateFilteredData();
                            });
                          }
                        },
                      ),
                      Text('Class Students'),
                      Radio<bool>(
                        value: false,
                        groupValue: _isClassStudent,
                        onChanged: (bool? value) {
                          if (value != null) {
                            setState(() {
                              _isClassStudent = value;
                              _selectedClass = 'All';
                              _selectedBatch = 'All';
                              _updateFilteredData();
                            });
                          }
                        },
                      ),
                      Text('Course Students'),
                    ],
                  ),

                  // Class/Batch Dropdown
                  if (_isClassStudent)
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
                            _classGrades.map((String grade) {
                              return DropdownMenuItem(
                                value: grade,
                                child: Text(grade),
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
                    )
                  else
                    SizedBox(
                      width: 150,
                      child: DropdownButtonFormField<String>(
                        value: _selectedBatch,
                        decoration: const InputDecoration(
                          labelText: 'Batch',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                        ),
                        items:
                            _batchNumbers.map((String batch) {
                              return DropdownMenuItem(
                                value: batch,
                                child: Text(batch),
                              );
                            }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedBatch = newValue;
                              _updateFilteredData();
                            });
                          }
                        },
                      ),
                    ),
                ],

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
    List<DataColumn> columns = [const DataColumn(label: Text('Name'))];

    if (widget.isTeacher) {
      columns.add(const DataColumn(label: Text('Subject')));
    } else {
      if (_isClassStudent) {
        columns.add(const DataColumn(label: Text('Class')));
      } else {
        columns.add(const DataColumn(label: Text('Course')));
        columns.add(const DataColumn(label: Text('Batch')));
      }
      columns.add(const DataColumn(label: Text('Fee Status')));
    }

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
      List<DataCell> cells = [DataCell(Text(data['name']))];

      if (widget.isTeacher) {
        cells.add(DataCell(Text(data['subject'])));
      } else {
        if (_isClassStudent) {
          cells.add(DataCell(Text(data['classGrade'])));
        } else {
          cells.add(DataCell(Text(data['courseName'])));
          cells.add(DataCell(Text(data['batchNumber'])));
        }
        // Add fee status
        final feeAmount = data['feeAmount']?.toString() ?? 'N/A';
        cells.add(DataCell(Text('\$$feeAmount')));
      }

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
