import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/fee.dart';
import '../models/student.dart';
import '../services/database_service.dart';

class FeeRecordsScreen extends StatefulWidget {
  const FeeRecordsScreen({super.key});

  @override
  _FeeRecordsScreenState createState() => _FeeRecordsScreenState();
}

class _FeeRecordsScreenState extends State<FeeRecordsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  bool _isDarkMode = false;
  String? _sortColumn;
  bool _sortAscending = true;
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  // Filter options
  bool _isClassStudent = true; // Default to class students
  String _selectedClass = 'All';
  String _selectedMonth = 'All';
  String _selectedYear = 'All';
  String _selectedStatus = 'All';

  List<Fee> _fees = [];
  List<Fee> _filteredFees = [];
  List<Student> _students = [];
  Map<String, List<Fee>> _unpaidFeesByStudent = {};

  // Get unique class grades
  List<String> get _classGrades {
    final grades = _students
        .where((s) => s.isClassStudent && s.classGrade != null && s.classGrade!.isNotEmpty)
        .map((s) => s.classGrade!)
        .toSet()
        .toList();
    grades.sort();
    return ['All', ...grades];
  }

  // Get unique course names
  List<String> get _courseNames {
    final courses = _students
        .where((s) => !s.isClassStudent && s.courseName != null && s.courseName!.isNotEmpty)
        .map((s) => s.courseName!)
        .toSet()
        .toList();
    courses.sort();
    return ['All', ...courses];
  }

  // Get unique months
  List<String> get _months {
    final months = _fees
        .map((f) => f.month)
        .toSet()
        .toList();
    
    // Sort months numerically
    months.sort((a, b) {
      final aNum = int.tryParse(a) ?? 0;
      final bNum = int.tryParse(b) ?? 0;
      return aNum.compareTo(bNum);
    });
    
    // Convert to month names
    final monthNames = months.map((m) {
      final monthNum = int.tryParse(m) ?? 1;
      return DateFormat('MMMM').format(DateTime(2022, monthNum));
    }).toList();
    
    return ['All', ...monthNames];
  }

  // Get unique years
  List<String> get _years {
    final years = _fees
        .map((f) => f.year.toString())
        .toSet()
        .toList();
    years.sort();
    return ['All', ...years];
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load all students
      final students = await _databaseService.getStudents();
      
      // Load fee history
      final List<Fee> allFees = [];
      
      // For each student, get their fee history
      for (final student in students) {
        final studentFees = await _databaseService.getStudentFeeHistory(student.id);
        allFees.addAll(studentFees);
        
        // Check for unpaid fees in current_month_fees
        final currentMonthFees = await _databaseService.getCurrentMonthFees();
        final unpaidFees = currentMonthFees
            .where((fee) => fee.studentId == student.id && fee.status != 'Paid')
            .toList();
        
        if (unpaidFees.isNotEmpty) {
          _unpaidFeesByStudent[student.id] = unpaidFees;
        }
      }
      
      setState(() {
        _students = students;
        _fees = allFees;
        _filterFees();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading fee records: $e')),
        );
      }
    }
  }

  void _filterFees() {
    final searchQuery = _searchController.text.toLowerCase();
    setState(() {
      _filteredFees = _fees.where((fee) {
        // Find the student for this fee
        final student = _students.firstWhere(
          (s) => s.id == fee.studentId,
          orElse: () => Student(
            id: '',
            name: '',
            rollNumber: '',
            phoneNumber: '',
            isClassStudent: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        
        // Skip if student not found
        if (student.id.isEmpty) return false;
        
        // Filter by student type
        if (_isClassStudent != student.isClassStudent) return false;
        
        // Filter by class/course
        if (_isClassStudent) {
          if (_selectedClass != 'All' && student.classGrade != _selectedClass) {
            return false;
          }
        } else {
          if (_selectedClass != 'All' && student.courseName != _selectedClass) {
            return false;
          }
        }
        
        // Filter by month
        if (_selectedMonth != 'All') {
          final monthIndex = _months.indexOf(_selectedMonth) - 1;
          if (monthIndex >= 0) {
            final monthNum = (monthIndex + 1).toString();
            if (fee.month != monthNum) {
              return false;
            }
          }
        }
        
        // Filter by year
        if (_selectedYear != 'All' && fee.year.toString() != _selectedYear) {
          return false;
        }
        
        // Filter by status
        if (_selectedStatus != 'All' && fee.status != _selectedStatus) {
          return false;
        }
        
        // Filter by search query
        return fee.studentName.toLowerCase().contains(searchQuery) ||
            (student.classGrade?.toLowerCase().contains(searchQuery) ?? false) ||
            (student.courseName?.toLowerCase().contains(searchQuery) ?? false);
      }).toList();
      
      if (_sortColumn != null) {
        _sortFees(_sortColumn!, _sortAscending);
      }
    });
  }

  void _sortFees(String column, bool ascending) {
    setState(() {
      _sortColumn = column;
      _sortAscending = ascending;
      
      _filteredFees.sort((a, b) {
        var aValue;
        var bValue;
        
        switch (column) {
          case 'studentName':
            aValue = a.studentName;
            bValue = b.studentName;
            break;
          case 'class':
            final aStudent = _students.firstWhere((s) => s.id == a.studentId, orElse: () => Student(
              id: '', name: '', rollNumber: '', phoneNumber: '', 
              isClassStudent: true, createdAt: DateTime.now(), updatedAt: DateTime.now(),
            ));
            final bStudent = _students.firstWhere((s) => s.id == b.studentId, orElse: () => Student(
              id: '', name: '', rollNumber: '', phoneNumber: '', 
              isClassStudent: true, createdAt: DateTime.now(), updatedAt: DateTime.now(),
            ));
            aValue = aStudent.classGrade ?? '';
            bValue = bStudent.classGrade ?? '';
            break;
          case 'course':
            final aStudent = _students.firstWhere((s) => s.id == a.studentId, orElse: () => Student(
              id: '', name: '', rollNumber: '', phoneNumber: '', 
              isClassStudent: true, createdAt: DateTime.now(), updatedAt: DateTime.now(),
            ));
            final bStudent = _students.firstWhere((s) => s.id == b.studentId, orElse: () => Student(
              id: '', name: '', rollNumber: '', phoneNumber: '', 
              isClassStudent: true, createdAt: DateTime.now(), updatedAt: DateTime.now(),
            ));
            aValue = aStudent.courseName ?? '';
            bValue = bStudent.courseName ?? '';
            break;
          case 'amount':
            aValue = a.amount;
            bValue = b.amount;
            break;
          case 'paymentDate':
            aValue = a.createdAt;
            bValue = b.createdAt;
            break;
          case 'dueDate':
            aValue = a.dueDate;
            bValue = b.dueDate;
            break;
          case 'status':
            aValue = a.status;
            bValue = b.status;
            break;
          case 'month':
            aValue = int.tryParse(a.month) ?? 0;
            bValue = int.tryParse(b.month) ?? 0;
            break;
          case 'year':
            aValue = a.year;
            bValue = b.year;
            break;
          default:
            aValue = a.studentName;
            bValue = b.studentName;
        }
        
        if (aValue is String && bValue is String) {
          return ascending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
        } else if (aValue is num && bValue is num) {
          return ascending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
        } else if (aValue is DateTime && bValue is DateTime) {
          return ascending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
        } else {
          return 0;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine if we're on a mobile or web layout based on screen width
    final isWebLayout = MediaQuery.of(context).size.width > 800;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fee Records'),
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              setState(() {
                _isDarkMode = !_isDarkMode;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.purple.withOpacity(0.1), Colors.white],
                ),
              ),
              child: Column(
                children: [
                  if (_unpaidFeesByStudent.isNotEmpty)
                    _buildUnpaidFeesWarning(),
                  isWebLayout
                      ? _buildWebLayout(context)
                      : _buildMobileLayout(context),
                ],
              ),
            ),
    );
  }

  Widget _buildWebLayout(BuildContext context) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side - Filter options
          Expanded(
            flex: 1,
            child: Card(
              margin: const EdgeInsets.all(16),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Filter Options",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFilterControls(isVertical: true),
                    const SizedBox(height: 16),
                    Expanded(child: _buildSearchBar()),
                  ],
                ),
              ),
            ),
          ),
          // Right side - Fee table
          Expanded(
            flex: 3,
            child: Card(
              margin: const EdgeInsets.all(16),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildFeeTable(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          // Filter options
          Card(
            margin: const EdgeInsets.all(16),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Filter Options",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFilterControls(isVertical: false),
                  const SizedBox(height: 16),
                  _buildSearchBar(),
                ],
              ),
            ),
          ),
          // Fee table
          Expanded(
            child: Card(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildFeeTable(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterControls({required bool isVertical}) {
    if (isVertical) {
      // Vertical layout for web
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student type filter
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Student Type:", style: TextStyle(fontWeight: FontWeight.bold)),
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
                          _filterFees();
                        });
                      }
                    },
                  ),
                  const Text('Class Students'),
                ],
              ),
              Row(
                children: [
                  Radio<bool>(
                    value: false,
                    groupValue: _isClassStudent,
                    onChanged: (bool? value) {
                      if (value != null) {
                        setState(() {
                          _isClassStudent = value;
                          _selectedClass = 'All';
                          _filterFees();
                        });
                      }
                    },
                  ),
                  const Text('Course Students'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Class/Course filter
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isClassStudent ? "Class:" : "Course:", 
                style: const TextStyle(fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 8),
              DropdownButton<String>(
                isExpanded: true,
                value: _selectedClass,
                items: (_isClassStudent ? _classGrades : _courseNames)
                    .map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedClass = newValue;
                      _filterFees();
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Month filter
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Month:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButton<String>(
                isExpanded: true,
                value: _selectedMonth,
                items: _months.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedMonth = newValue;
                      _filterFees();
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Year filter
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Year:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButton<String>(
                isExpanded: true,
                value: _selectedYear,
                items: _years.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedYear = newValue;
                      _filterFees();
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Status filter
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Status:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButton<String>(
                isExpanded: true,
                value: _selectedStatus,
                items: ['All', 'Paid', 'Pending', 'Overdue'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedStatus = newValue;
                      _filterFees();
                    });
                  }
                },
              ),
            ],
          ),
        ],
      );
    } else {
      // Horizontal layout for mobile
      return Column(
        children: [
          // Student type filter
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
                      _filterFees();
                    });
                  }
                },
              ),
              const Text('Class Students'),
              const SizedBox(width: 20),
              Radio<bool>(
                value: false,
                groupValue: _isClassStudent,
                onChanged: (bool? value) {
                  if (value != null) {
                    setState(() {
                      _isClassStudent = value;
                      _selectedClass = 'All';
                      _filterFees();
                    });
                  }
                },
              ),
              const Text('Course Students'),
            ],
          ),
          const SizedBox(height: 16),
          
          // Dropdown filters
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              // Class/Course filter
              SizedBox(
                width: 150,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isClassStudent ? "Class:" : "Course:", 
                      style: const TextStyle(fontWeight: FontWeight.bold)
                    ),
                    const SizedBox(height: 4),
                    DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedClass,
                      items: (_isClassStudent ? _classGrades : _courseNames)
                          .map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedClass = newValue;
                            _filterFees();
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              
              // Month filter
              SizedBox(
                width: 150,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Month:", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedMonth,
                      items: _months.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedMonth = newValue;
                            _filterFees();
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              
              // Year filter
              SizedBox(
                width: 100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Year:", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedYear,
                      items: _years.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedYear = newValue;
                            _filterFees();
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              
              // Status filter
              SizedBox(
                width: 120,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Status:", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedStatus,
                      items: ['All', 'Paid', 'Pending', 'Overdue'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedStatus = newValue;
                            _filterFees();
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: const InputDecoration(
        labelText: 'Search',
        prefixIcon: Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      onChanged: (value) {
        _filterFees();
      },
    );
  }

  Widget _buildUnpaidFeesWarning() {
    // Calculate total unpaid amount and count months
    double totalUnpaid = 0;
    final Map<String, Map<String, bool>> monthsByStudent = {};
    
    _unpaidFeesByStudent.forEach((studentId, fees) {
      for (final fee in fees) {
        totalUnpaid += fee.amount;
        
        if (!monthsByStudent.containsKey(studentId)) {
          monthsByStudent[studentId] = {};
        }
        
        final monthYear = '${fee.month}/${fee.year}';
        monthsByStudent[studentId]![monthYear] = true;
      }
    });
    
    // Count students with multiple unpaid months
    int studentsWithMultipleUnpaid = 0;
    monthsByStudent.forEach((studentId, months) {
      if (months.length > 1) {
        studentsWithMultipleUnpaid++;
      }
    });
    
    // Get screen width to make layout responsive
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.red.shade100,
      child: isWideScreen
          // Wide screen layout - horizontal arrangement
          ? Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red.shade800, size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Unpaid Fees Warning',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.red.shade800,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  'Total: \$${totalUnpaid.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Students: ${_unpaidFeesByStudent.length}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _showUnpaidFeesDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: const Text('View Details', style: TextStyle(fontSize: 13)),
                ),
              ],
            )
          // Narrow screen layout - more compact vertical arrangement
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red.shade800, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Unpaid Fees Warning',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.red.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total: \$${totalUnpaid.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          'Students: ${_unpaidFeesByStudent.length}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: _showUnpaidFeesDetails,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: const Size(80, 30),
                      ),
                      child: const Text('View Details', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  void _showUnpaidFeesDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unpaid Fees Details'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _unpaidFeesByStudent.length,
            itemBuilder: (context, index) {
              final studentId = _unpaidFeesByStudent.keys.elementAt(index);
              final fees = _unpaidFeesByStudent[studentId]!;
              final student = _students.firstWhere(
                (s) => s.id == studentId,
                orElse: () => Student(
                  id: '', name: 'Unknown', rollNumber: '', phoneNumber: '',
                  isClassStudent: true, createdAt: DateTime.now(), updatedAt: DateTime.now(),
                ),
              );
              
              // Calculate total for this student
              double studentTotal = 0;
              for (final fee in fees) {
                studentTotal += fee.amount;
              }
              
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        student.isClassStudent
                            ? 'Class: ${student.classGrade}'
                            : 'Course: ${student.courseName}',
                      ),
                      const Divider(),
                      ...fees.map((fee) {
                        final monthName = DateFormat('MMMM').format(
                          DateTime(2022, int.tryParse(fee.month) ?? 1),
                        );
                        return ListTile(
                          dense: true,
                          title: Text('$monthName ${fee.year}'),
                          subtitle: Text('Due: ${fee.formattedDueDate}'),
                          trailing: Text(
                            '\$${fee.amount.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        );
                      }).toList(),
                      const Divider(),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Total: \$${studentTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeTable() {
    if (_filteredFees.isEmpty) {
      return const Center(
        child: Text('No fee records found matching your filters'),
      );
    }
    
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(
            _isDarkMode ? Colors.grey[800] : Colors.grey[200],
          ),
          dataRowColor: MaterialStateProperty.all(
            _isDarkMode ? Colors.grey[700] : Colors.white,
          ),
          columns: [
            DataColumn(
              label: const Text('Student Name'),
              onSort: (columnIndex, ascending) {
                _sortFees('studentName', ascending);
              },
            ),
            DataColumn(
              label: Text(_isClassStudent ? 'Class' : 'Course'),
              onSort: (columnIndex, ascending) {
                _sortFees(_isClassStudent ? 'class' : 'course', ascending);
              },
            ),
            DataColumn(
              label: const Text('Amount'),
              onSort: (columnIndex, ascending) {
                _sortFees('amount', ascending);
              },
            ),
            DataColumn(
              label: const Text('Payment Date'),
              onSort: (columnIndex, ascending) {
                _sortFees('paymentDate', ascending);
              },
            ),
            DataColumn(
              label: const Text('Due Date'),
              onSort: (columnIndex, ascending) {
                _sortFees('dueDate', ascending);
              },
            ),
            DataColumn(
              label: const Text('Month/Year'),
              onSort: (columnIndex, ascending) {
                _sortFees('month', ascending);
              },
            ),
            DataColumn(
              label: const Text('Status'),
              onSort: (columnIndex, ascending) {
                _sortFees('status', ascending);
              },
            ),
          ],
          rows: _filteredFees.map((fee) {
            final student = _students.firstWhere(
              (s) => s.id == fee.studentId,
              orElse: () => Student(
                id: '', name: '', rollNumber: '', phoneNumber: '',
                isClassStudent: true, createdAt: DateTime.now(), updatedAt: DateTime.now(),
              ),
            );
            
            final monthName = DateFormat('MMMM').format(
              DateTime(2022, int.tryParse(fee.month) ?? 1),
            );
            
            return DataRow(
              cells: [
                DataCell(Text(
                  fee.studentName,
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white : Colors.black,
                  ),
                )),
                DataCell(Text(
                  _isClassStudent
                      ? (student.classGrade ?? '')
                      : (student.courseName ?? ''),
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white : Colors.black,
                  ),
                )),
                DataCell(Text(
                  '\$${fee.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white : Colors.black,
                  ),
                )),
                DataCell(Text(
                  DateFormat('MM/dd/yyyy').format(fee.createdAt),
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white : Colors.black,
                  ),
                )),
                DataCell(Text(
                  DateFormat('MM/dd/yyyy').format(fee.dueDate),
                  style: TextStyle(
                    color: fee.isOverdue
                        ? Colors.red
                        : (_isDarkMode ? Colors.white : Colors.black),
                  ),
                )),
                DataCell(Text(
                  '$monthName ${fee.year}',
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white : Colors.black,
                  ),
                )),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: fee.isPaid
                          ? Colors.green.withOpacity(0.2)
                          : (fee.isOverdue
                              ? Colors.red.withOpacity(0.2)
                              : Colors.orange.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          fee.isPaid
                              ? Icons.check_circle
                              : (fee.isOverdue
                                  ? Icons.error
                                  : Icons.pending),
                          size: 16,
                          color: fee.isPaid
                              ? Colors.green
                              : (fee.isOverdue ? Colors.red : Colors.orange),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          fee.status,
                          style: TextStyle(
                            color: fee.isPaid
                                ? Colors.green
                                : (fee.isOverdue ? Colors.red : Colors.orange),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
