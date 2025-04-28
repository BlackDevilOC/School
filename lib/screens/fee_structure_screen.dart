import 'package:flutter/material.dart';
import '../models/fee.dart';
import '../services/data_service.dart';

class FeeStructureScreen extends StatefulWidget {
  const FeeStructureScreen({super.key});

  @override
  _FeeStructureScreenState createState() => _FeeStructureScreenState();
}

class _FeeStructureScreenState extends State<FeeStructureScreen> {
  final DataService _dataService = DataService();
  final _formKey = GlobalKey<FormState>();
  bool _isDarkMode = false;
  String? _sortColumn;
  bool _sortAscending = true;
  final TextEditingController _searchController = TextEditingController();

  // Form controllers
  final TextEditingController _studentNameController = TextEditingController();
  final TextEditingController _classGradeController = TextEditingController();
  final TextEditingController _courseNameController = TextEditingController();
  final TextEditingController _batchNumberController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();
  DateTime? _selectedDueDate;

  bool _isClassStudent = true; // Default to class students
  String _selectedClass = 'All';
  String _selectedBatch = 'All';

  List<Fee> _fees = [];
  List<Fee> _filteredFees = [];

  // Get unique class grades
  List<String> get _classGrades {
    final grades =
        _fees
            .where((f) => f.isClassStudent)
            .map((f) => f.classGrade!)
            .toSet()
            .toList();
    grades.sort();
    return ['All', ...grades];
  }

  // Get unique batch numbers
  List<String> get _batchNumbers {
    final batches =
        _fees
            .where((f) => !f.isClassStudent)
            .map((f) => f.batchNumber!)
            .toSet()
            .toList();
    batches.sort();
    return ['All', ...batches];
  }

  @override
  void initState() {
    super.initState();
    _loadFees();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _studentNameController.dispose();
    _classGradeController.dispose();
    _courseNameController.dispose();
    _batchNumberController.dispose();
    _amountController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  void _loadFees() {
    setState(() {
      _fees = _dataService.fees;
      _filterFees();
    });
  }

  void _filterFees() {
    final searchQuery = _searchController.text.toLowerCase();
    setState(() {
      _filteredFees =
          _fees.where((fee) {
            // First filter by student type
            if (fee.isClassStudent != _isClassStudent) return false;

            // Then filter by class or batch
            if (_isClassStudent) {
              if (_selectedClass != 'All' && fee.classGrade != _selectedClass) {
                return false;
              }
            } else {
              if (_selectedBatch != 'All' &&
                  fee.batchNumber != _selectedBatch) {
                return false;
              }
            }

            // Finally filter by search query
            return fee.studentName.toLowerCase().contains(searchQuery) ||
                (_isClassStudent
                    ? (fee.classGrade?.toLowerCase().contains(searchQuery) ??
                        false)
                    : (fee.courseName?.toLowerCase().contains(searchQuery) ??
                        false));
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
          case 'batch':
            aValue = a.batchNumber ?? '';
            bValue = b.batchNumber ?? '';
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
            aValue = a.isPaid;
            bValue = b.isPaid;
            break;
          default:
            return 0;
        }

        if (!ascending) {
          var temp = aValue;
          aValue = bValue;
          bValue = temp;
        }

        if (aValue is String) {
          return aValue.compareTo(bValue);
        } else if (aValue is num) {
          return aValue.compareTo(bValue);
        } else if (aValue is DateTime) {
          return aValue.compareTo(bValue);
        } else if (aValue is bool) {
          return aValue == bValue ? 0 : (aValue ? 1 : -1);
        }
        return 0;
      });
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDueDate = picked;
        _dueDateController.text =
            '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  void _togglePaymentStatus(Fee fee) {
    final updatedFee = Fee(
      id: fee.id,
      studentName: fee.studentName,
      classGrade: fee.classGrade,
      courseName: fee.courseName,
      batchNumber: fee.batchNumber,
      amount: fee.amount,
      dueDate: fee.dueDate,
      isPaid: !fee.isPaid,
      isClassStudent: fee.isClassStudent,
    );

    _dataService.updateFee(fee.id, updatedFee);
    _loadFees();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          updatedFee.isPaid
              ? 'Payment status updated to Paid'
              : 'Payment status updated to Pending',
        ),
        backgroundColor: updatedFee.isPaid ? Colors.green : Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(
        context,
      ).copyWith(brightness: _isDarkMode ? Brightness.dark : Brightness.light),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Fee Structure',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.green,
          actions: [
            IconButton(
              icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: () {
                setState(() {
                  _isDarkMode = !_isDarkMode;
                });
              },
              tooltip: 'Toggle theme',
            ),
          ],
        ),
        body: Column(
          children: [
            _buildFilterOptions(),
            _buildSearchBar(),
            Expanded(child: _buildFeeTable()),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddEditFeeDialog(),
          backgroundColor: Colors.green,
          child: const Icon(Icons.add),
          tooltip: 'Add new fee record',
        ),
      ),
    );
  }

  Widget _buildFilterOptions() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: RadioListTile<bool>(
                  title: Text('Class Students'),
                  value: true,
                  groupValue: _isClassStudent,
                  onChanged: (bool? value) {
                    if (value != null) {
                      setState(() {
                        _isClassStudent = value;
                        _selectedClass = 'All';
                        _selectedBatch = 'All';
                        _filterFees();
                      });
                    }
                  },
                ),
              ),
              Expanded(
                child: RadioListTile<bool>(
                  title: Text('Course Students'),
                  value: false,
                  groupValue: _isClassStudent,
                  onChanged: (bool? value) {
                    if (value != null) {
                      setState(() {
                        _isClassStudent = value;
                        _selectedClass = 'All';
                        _selectedBatch = 'All';
                        _filterFees();
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          if (_isClassStudent)
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Filter by Class',
                border: OutlineInputBorder(),
              ),
              value: _selectedClass,
              items:
                  _classGrades
                      .map(
                        (grade) =>
                            DropdownMenuItem(value: grade, child: Text(grade)),
                      )
                      .toList(),
              onChanged: (String? value) {
                if (value != null) {
                  setState(() {
                    _selectedClass = value;
                    _filterFees();
                  });
                }
              },
            )
          else
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Filter by Batch',
                border: OutlineInputBorder(),
              ),
              value: _selectedBatch,
              items:
                  _batchNumbers
                      .map(
                        (batch) =>
                            DropdownMenuItem(value: batch, child: Text(batch)),
                      )
                      .toList(),
              onChanged: (String? value) {
                if (value != null) {
                  setState(() {
                    _selectedBatch = value;
                    _filterFees();
                  });
                }
              },
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
        decoration: InputDecoration(
          labelText: 'Search',
          prefixIcon: const Icon(Icons.search),
          border: const OutlineInputBorder(),
        ),
        onChanged: (_) => _filterFees(),
      ),
    );
  }

  Widget _buildFeeTable() {
    if (_fees.isEmpty) {
      return Center(
        child: Text(
          'No fee records found.\nAdd students from the Manage Students page to see their fees here.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(
            label: const Text('Student Name'),
            onSort:
                (columnIndex, ascending) => _sortFees('studentName', ascending),
          ),
          if (_isClassStudent)
            DataColumn(
              label: const Text('Class'),
              onSort: (columnIndex, ascending) => _sortFees('class', ascending),
            )
          else ...[
            DataColumn(
              label: const Text('Course'),
              onSort:
                  (columnIndex, ascending) => _sortFees('course', ascending),
            ),
            DataColumn(
              label: const Text('Batch'),
              onSort: (columnIndex, ascending) => _sortFees('batch', ascending),
            ),
          ],
          DataColumn(
            label: const Text('Amount'),
            numeric: true,
            onSort: (columnIndex, ascending) => _sortFees('amount', ascending),
          ),
          DataColumn(
            label: const Text('Due Date'),
            onSort: (columnIndex, ascending) => _sortFees('dueDate', ascending),
          ),
          DataColumn(
            label: const Text('Status'),
            onSort: (columnIndex, ascending) => _sortFees('status', ascending),
          ),
        ],
        rows:
            _filteredFees.map((fee) {
              final bool isOverdue =
                  !fee.isPaid && fee.dueDate.isBefore(DateTime.now());
              return DataRow(
                cells: [
                  DataCell(Text(fee.studentName)),
                  if (_isClassStudent)
                    DataCell(Text(fee.classGrade ?? ''))
                  else ...[
                    DataCell(Text(fee.courseName ?? '')),
                    DataCell(Text(fee.batchNumber ?? '')),
                  ],
                  DataCell(Text('\$${fee.amount.toStringAsFixed(2)}')),
                  DataCell(
                    Text(
                      '${fee.dueDate.day}/${fee.dueDate.month}/${fee.dueDate.year}',
                      style:
                          isOverdue
                              ? TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              )
                              : null,
                    ),
                  ),
                  DataCell(
                    GestureDetector(
                      onTap: () => _togglePaymentStatus(fee),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              fee.isPaid
                                  ? Colors.green.withOpacity(0.1)
                                  : isOverdue
                                  ? Colors.red.withOpacity(0.1)
                                  : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                fee.isPaid
                                    ? Colors.green
                                    : isOverdue
                                    ? Colors.red
                                    : Colors.orange,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              fee.isPaid
                                  ? Icons.check_circle
                                  : isOverdue
                                  ? Icons.warning
                                  : Icons.pending,
                              color:
                                  fee.isPaid
                                      ? Colors.green
                                      : isOverdue
                                      ? Colors.red
                                      : Colors.orange,
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              fee.isPaid
                                  ? 'Paid'
                                  : isOverdue
                                  ? 'Overdue'
                                  : 'Pending',
                              style: TextStyle(
                                color:
                                    fee.isPaid
                                        ? Colors.green
                                        : isOverdue
                                        ? Colors.red
                                        : Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
      ),
    );
  }

  void _showAddEditFeeDialog([Fee? fee]) {
    if (fee != null) {
      _studentNameController.text = fee.studentName;
      if (fee.isClassStudent) {
        _classGradeController.text = fee.classGrade ?? '';
      } else {
        _courseNameController.text = fee.courseName ?? '';
        _batchNumberController.text = fee.batchNumber ?? '';
      }
      _amountController.text = fee.amount.toString();
      _selectedDueDate = fee.dueDate;
      _dueDateController.text =
          '${fee.dueDate.day}/${fee.dueDate.month}/${fee.dueDate.year}';
      _isClassStudent = fee.isClassStudent;
    } else {
      _studentNameController.clear();
      _classGradeController.clear();
      _courseNameController.clear();
      _batchNumberController.clear();
      _amountController.clear();
      _dueDateController.clear();
      _selectedDueDate = null;
    }

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              return AlertDialog(
                title: Text(fee == null ? 'Add Fee Record' : 'Edit Fee Record'),
                content: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<bool>(
                                title: Text('Class'),
                                value: true,
                                groupValue: _isClassStudent,
                                onChanged: (bool? value) {
                                  if (value != null) {
                                    setDialogState(() {
                                      _isClassStudent = value;
                                    });
                                  }
                                },
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<bool>(
                                title: Text('Course'),
                                value: false,
                                groupValue: _isClassStudent,
                                onChanged: (bool? value) {
                                  if (value != null) {
                                    setDialogState(() {
                                      _isClassStudent = value;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _studentNameController,
                          decoration: const InputDecoration(
                            labelText: 'Student Name',
                            border: OutlineInputBorder(),
                          ),
                          validator:
                              (value) =>
                                  value?.isEmpty == true
                                      ? 'Required field'
                                      : null,
                        ),
                        SizedBox(height: 16),
                        if (_isClassStudent)
                          TextFormField(
                            controller: _classGradeController,
                            decoration: const InputDecoration(
                              labelText: 'Class/Grade',
                              border: OutlineInputBorder(),
                            ),
                            validator:
                                (value) =>
                                    value?.isEmpty == true
                                        ? 'Required field'
                                        : null,
                          )
                        else ...[
                          TextFormField(
                            controller: _courseNameController,
                            decoration: const InputDecoration(
                              labelText: 'Course Name',
                              border: OutlineInputBorder(),
                            ),
                            validator:
                                (value) =>
                                    value?.isEmpty == true
                                        ? 'Required field'
                                        : null,
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: _batchNumberController,
                            decoration: const InputDecoration(
                              labelText: 'Batch Number',
                              border: OutlineInputBorder(),
                            ),
                            validator:
                                (value) =>
                                    value?.isEmpty == true
                                        ? 'Required field'
                                        : null,
                          ),
                        ],
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _amountController,
                          decoration: const InputDecoration(
                            labelText: 'Amount',
                            border: OutlineInputBorder(),
                            prefixText: '\$',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value?.isEmpty == true) return 'Required field';
                            if (double.tryParse(value!) == null)
                              return 'Enter valid amount';
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _dueDateController,
                          decoration: const InputDecoration(
                            labelText: 'Due Date',
                            border: OutlineInputBorder(),
                          ),
                          readOnly: true,
                          onTap: () => _selectDate(context),
                          validator:
                              (value) =>
                                  value?.isEmpty == true
                                      ? 'Required field'
                                      : null,
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => _saveFee(fee),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: Text(fee == null ? 'Add' : 'Update'),
                  ),
                ],
              );
            },
          ),
    );
  }

  void _saveFee(Fee? existingFee) {
    if (_formKey.currentState?.validate() == true && _selectedDueDate != null) {
      final newFee = Fee(
        id: existingFee?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        studentName: _studentNameController.text,
        classGrade: _isClassStudent ? _classGradeController.text : null,
        courseName: !_isClassStudent ? _courseNameController.text : null,
        batchNumber: !_isClassStudent ? _batchNumberController.text : null,
        amount: double.parse(_amountController.text),
        dueDate: _selectedDueDate!,
        isPaid: existingFee?.isPaid ?? false,
        isClassStudent: _isClassStudent,
      );

      setState(() {
        if (existingFee != null) {
          final index = _fees.indexWhere((fee) => fee.id == existingFee.id);
          if (index != -1) {
            _fees[index] = newFee;
          }
        } else {
          _fees.add(newFee);
        }
        _filterFees();
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            existingFee == null
                ? 'Fee added successfully'
                : 'Fee updated successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
