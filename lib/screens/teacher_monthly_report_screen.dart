import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../services/database_service.dart';
import '../models/teacher.dart';

class TeacherMonthlyReportScreen extends StatefulWidget {
  const TeacherMonthlyReportScreen({super.key});

  @override
  _TeacherMonthlyReportScreenState createState() => _TeacherMonthlyReportScreenState();
}

class _TeacherMonthlyReportScreenState extends State<TeacherMonthlyReportScreen> {
  final DatabaseService _databaseService = DatabaseService();
  String _selectedMonth = 'January';
  String _searchQuery = '';
  List<Teacher> _teachers = [];
  Map<String, Map<int, String>> _teacherAttendance = {};
  bool _isLoading = true;

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

  // We use these status codes directly instead of display names

  // Map for short status codes
  final Map<String, String> _statusCodes = {
    'Present': 'P',
    'Absent': 'A',
    'Excused': 'L', // 'L' for Leave
  };

  // Map for status colors
  final Map<String, Color> _statusColors = {
    'P': Colors.green,
    'A': Colors.red,
    'L': Colors.blue,
    '-': Colors.grey,
  };

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
      // Load teachers
      final teachers = await _databaseService.getTeachers();
      
      // Get current month and year
      final now = DateTime.now();
      final currentMonthIndex = now.month - 1; // 0-based index
      
      setState(() {
        _selectedMonth = _months[currentMonthIndex];
        _teachers = teachers;
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
    setState(() {
      _isLoading = true;
    });
    
    try {
      final monthIndex = _months.indexOf(_selectedMonth) + 1;
      final year = DateTime.now().year;
      
      // The _daysInMonth getter will automatically update based on the selected month
      
      // Create a map to store attendance by teacher and day
      final attendanceMap = <String, Map<int, String>>{};
      
      // Initialize the map for all teachers
      for (final teacher in _teachers) {
        attendanceMap[teacher.id] = {};
      }
      
      // For each day in the month
      for (int day = 1; day <= _daysInMonth; day++) {
        final date = DateTime(year, monthIndex, day);
        final dayAttendance = await _databaseService.getTeacherAttendanceForDate(date);
        
        // Add each record to the map
        for (final record in dayAttendance) {
          final day = record.attendanceDate.day;
          attendanceMap[record.teacherId] ??= {};
          attendanceMap[record.teacherId]![day] = record.status;
        }
      }
      
      if (mounted) {
        setState(() {
          _teacherAttendance = attendanceMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading attendance data: $e')),
        );
      }
    }
  }

  List<Teacher> get _filteredTeachers {
    return _teachers.where((teacher) {
      final nameMatches = teacher.name.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
      return nameMatches;
    }).toList();
  }

  Future<void> _generateAndDownloadReport() async {
    try {
      // Create CSV data
      List<List<dynamic>> csvData = [];
      
      // Add header row
      List<dynamic> header = ['Name', 'Subject', 'Qualification'];
      
      // Add date columns to header
      for (int i = 1; i <= _daysInMonth; i++) {
        header.add(i.toString());
      }
      
      csvData.add(header);
      
      // Add data rows
      for (final teacher in _filteredTeachers) {
        List<dynamic> row = [
          teacher.name,
          teacher.subject,
          teacher.qualification,
        ];
        
        // Add attendance data
        for (int day = 1; day <= _daysInMonth; day++) {
          final status = _getAttendanceStatus(teacher.id, day);
          row.add(status);
        }
        
        csvData.add(row);
      }
      
      // Convert to CSV string
      String csv = const ListToCsvConverter().convert(csvData);
      
      // Get documents directory
      final directory = await getApplicationDocumentsDirectory();
      final path = directory.path;
      
      // Create file name with date
      final now = DateTime.now();
      final fileName = 'teacher_attendance_${_selectedMonth}_${now.year}_${now.millisecondsSinceEpoch}.csv';
      
      // Write to file
      final file = File('$path/$fileName');
      await file.writeAsString(csv);
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report saved to: $path/$fileName'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating report: $e')),
        );
      }
    }
  }

  String _getAttendanceStatus(String teacherId, int day) {
    // Get the raw status from the attendance map
    final rawStatus = _teacherAttendance[teacherId]?[day];
    
    // If no status is found, return "-" for no record
    if (rawStatus == null) return '-';
    
    // Convert the database status to a display code
    return _statusCodes[rawStatus] ?? '-';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Monthly Report'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Month and Year selector
                Container(
                  margin: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          'Select Month',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                      Container(
                        height: 80,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _months.length,
                          itemBuilder: (context, index) {
                            final month = _months[index];
                            final isSelected = month == _selectedMonth;
                            return GestureDetector(
                              onTap: () {
                                if (!_isLoading && month != _selectedMonth) {
                                  setState(() => _selectedMonth = month);
                                  _loadAttendanceData();
                                }
                              },
                              child: Stack(
                                children: [
                                  Container(
                                    width: 100,
                                    margin: const EdgeInsets.symmetric(horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.green : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected ? Colors.green.shade700 : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          month.substring(0, 3),
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected ? Colors.white : Colors.grey.shade700,
                                          ),
                                        ),
                                        Text(
                                          DateTime.now().year.toString(),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isSelected ? Colors.white.withOpacity(0.8) : Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Loading indicator overlay
                                  if (isSelected && _isLoading)
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Center(
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Search bar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by teacher name',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              color: Colors.grey.shade500,
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),

                // Legend
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          'Attendance Status',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildLegendItem('P', Colors.green, 'Present'),
                          _buildLegendItem('A', Colors.red, 'Absent'),
                          _buildLegendItem('L', Colors.blue, 'Leave'),
                          _buildLegendItem('-', Colors.grey, 'No Record'),
                        ],
                      ),
                    ],
                  ),
                ),

                // Data Table
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              dividerColor: Colors.grey.shade200,
                              dataTableTheme: DataTableTheme.of(context).copyWith(
                                headingTextStyle: TextStyle(
                                  color: Colors.green.shade800,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                dataTextStyle: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            child: DataTable(
                              columnSpacing: 20,
                              headingRowHeight: 50,
                              dataRowHeight: 50,
                              headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
                              border: TableBorder(
                                horizontalInside: BorderSide(color: Colors.grey.shade200),
                              ),
                              columns: _buildColumns(),
                              rows: _buildRows(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          borderRadius: BorderRadius.circular(30),
        ),
        child: FloatingActionButton.extended(
          onPressed: _generateAndDownloadReport,
          label: const Text(
            'Download Report',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          icon: const Icon(Icons.download_rounded),
          backgroundColor: Colors.green,
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildLegendItem(String symbol, Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
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
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  List<DataColumn> _buildColumns() {
    List<DataColumn> columns = [
      const DataColumn(label: Text('Name')),
      const DataColumn(label: Text('Subject')),
      const DataColumn(label: Text('Qualification')),
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
    return _filteredTeachers.map((teacher) {
      List<DataCell> cells = [
        DataCell(Text(teacher.name)),
        DataCell(Text(teacher.subject)),
        DataCell(Text(teacher.qualification ?? '')),
      ];

      // Add attendance cells for each day
      for (int day = 1; day <= _daysInMonth; day++) {
        final status = _getAttendanceStatus(teacher.id, day);
        
        // Set color based on status
        Color textColor = _statusColors[status] != null ? _statusColors[status]! : Colors.grey;

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
