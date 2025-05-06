import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/fee.dart';
import '../services/database_service.dart';

class FeeStructureScreen extends StatefulWidget {
  const FeeStructureScreen({super.key});

  @override
  _FeeStructureScreenState createState() => _FeeStructureScreenState();
}

class _FeeStructureScreenState extends State<FeeStructureScreen> {
  final DatabaseService _databaseService = DatabaseService();
  bool _isDarkMode = false;
  String? _sortColumn;
  bool _sortAscending = true;
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  bool _isClassStudent = true; // Default to class students
  String _selectedClass = 'All';

  List<Fee> _fees = [];
  List<Fee> _filteredFees = [];

  // Get unique class grades
  List<String> get _classGrades {
    final grades = _fees
        .where((f) => f.classGrade != null && f.classGrade!.isNotEmpty)
        .map((f) => f.classGrade!)
        .toSet()
        .toList();
    grades.sort();
    return ['All', ...grades];
  }

  // Get unique course names
  List<String> get _courseNames {
    final courses = _fees
        .where((f) => f.courseName != null && f.courseName!.isNotEmpty)
        .map((f) => f.courseName!)
        .toSet()
        .toList();
    courses.sort();
    return ['All', ...courses];
  }

  @override
  void initState() {
    super.initState();
    _loadFees();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFees() async {
    setState(() => _isLoading = true);
    
    try {
      // First, ensure all students have current month fee entries
      await _databaseService.generateCurrentMonthFees();
      
      // Update any overdue fees
      await _databaseService.updateOverdueFees();
      
      // Now fetch the current month fees
      final fees = await _databaseService.getCurrentMonthFees();
      
      setState(() {
        _fees = fees;
        _filterFees();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading fees: $e')),
        );
      }
    }
  }

  void _filterFees() {
    final searchQuery = _searchController.text.toLowerCase();
    setState(() {
      _filteredFees = _fees.where((fee) {
        // First filter by student type (class or course)
        final hasClassGrade = fee.classGrade != null && fee.classGrade!.isNotEmpty;
        if (hasClassGrade != _isClassStudent) return false;

        // Then filter by class or course
        if (_isClassStudent) {
          if (_selectedClass != 'All' && fee.classGrade != _selectedClass) {
            return false;
          }
        } else {
          if (_selectedClass != 'All' && fee.courseName != _selectedClass) {
            return false;
          }
        }

        // Finally filter by search query
        return fee.studentName.toLowerCase().contains(searchQuery) ||
            (fee.classGrade?.toLowerCase().contains(searchQuery) ?? false) ||
            (fee.courseName?.toLowerCase().contains(searchQuery) ?? false);
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
            aValue = a.classGrade ?? '';
            bValue = b.classGrade ?? '';
            break;
          case 'course':
            aValue = a.courseName ?? '';
            bValue = b.courseName ?? '';
            break;
          case 'amount':
            aValue = a.amount;
            bValue = b.amount;
            break;
          case 'dueDate':
            aValue = a.dueDate;
            bValue = b.dueDate;
            break;
          case 'status':
            aValue = a.status;
            bValue = b.status;
            break;
          default:
            aValue = a.studentName;
            bValue = b.studentName;
        }

        if (aValue is String && bValue is String) {
          return ascending
              ? aValue.compareTo(bValue)
              : bValue.compareTo(aValue);
        } else if (aValue is num && bValue is num) {
          return ascending
              ? aValue.compareTo(bValue)
              : bValue.compareTo(aValue);
        } else if (aValue is DateTime && bValue is DateTime) {
          return ascending
              ? aValue.compareTo(bValue)
              : bValue.compareTo(aValue);
        } else {
          return 0;
        }
      });
    });
  }

  Future<void> _togglePaymentStatus(Fee fee) async {
    try {
      final newStatus = fee.status == 'Paid' ? 'Pending' : 'Paid';
      await _databaseService.updateFeeStatus(fee.id, newStatus);
      
      // Refresh the fees list
      _loadFees();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fee status updated to $newStatus'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating fee status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fee Structure'),
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
            onPressed: _loadFees,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilterOptions(),
                _buildSearchBar(),
                Expanded(child: _buildFeeTable()),
              ],
            ),
    );
  }

  Widget _buildFilterOptions() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const SizedBox(height: 8),
          Row(
            children: [
              Text(_isClassStudent ? 'Filter by Class:' : 'Filter by Course:'),
              const SizedBox(width: 16),
              DropdownButton<String>(
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
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          labelText: 'Search',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
        ),
        onChanged: (value) {
          _filterFees();
        },
      ),
    );
  }

  Widget _buildFeeTable() {
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
              label: const Text('Due Date'),
              onSort: (columnIndex, ascending) {
                _sortFees('dueDate', ascending);
              },
            ),
            DataColumn(
              label: const Text('Status'),
              onSort: (columnIndex, ascending) {
                _sortFees('status', ascending);
              },
            ),
            const DataColumn(
              label: Text('Actions'),
            ),
          ],
          rows: _filteredFees.map((fee) {
            final isOverdue = fee.status == 'Overdue';
            final isPaid = fee.status == 'Paid';

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
                      ? (fee.classGrade ?? '')
                      : (fee.courseName ?? ''),
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
                  DateFormat('MM/dd/yyyy').format(fee.dueDate),
                  style: TextStyle(
                    color: isOverdue
                        ? Colors.red
                        : (_isDarkMode ? Colors.white : Colors.black),
                  ),
                )),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isPaid
                          ? Colors.green.withOpacity(0.2)
                          : (isOverdue
                              ? Colors.red.withOpacity(0.2)
                              : Colors.orange.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPaid
                              ? Icons.check_circle
                              : (isOverdue
                                  ? Icons.error
                                  : Icons.pending),
                          size: 16,
                          color: isPaid
                              ? Colors.green
                              : (isOverdue ? Colors.red : Colors.orange),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          fee.status,
                          style: TextStyle(
                            color: isPaid
                                ? Colors.green
                                : (isOverdue ? Colors.red : Colors.orange),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          isPaid ? Icons.undo : Icons.check,
                          color: isPaid ? Colors.orange : Colors.green,
                        ),
                        onPressed: () => _togglePaymentStatus(fee),
                        tooltip: isPaid ? 'Mark as Pending' : 'Mark as Paid',
                      ),
                    ],
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
