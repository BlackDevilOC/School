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
  final TextEditingController _courseNameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();
  DateTime? _selectedDueDate;

  List<Fee> _fees = [];
  List<Fee> _filteredFees = [];

  @override
  void initState() {
    super.initState();
    _loadFees();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _studentNameController.dispose();
    _courseNameController.dispose();
    _amountController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  void _loadFees() {
    // In a real app, this would load from a database
    // For now, we'll use dummy data
    _fees = [
      Fee(
        id: '1',
        studentName: 'John Doe',
        courseName: 'Mathematics',
        amount: 500.0,
        dueDate: DateTime.now().add(const Duration(days: 7)),
        isPaid: false,
      ),
      Fee(
        id: '2',
        studentName: 'Jane Smith',
        courseName: 'Science',
        amount: 600.0,
        dueDate: DateTime.now().add(const Duration(days: 14)),
        isPaid: true,
      ),
    ];
    _filterFees();
  }

  void _filterFees() {
    final searchQuery = _searchController.text.toLowerCase();
    setState(() {
      _filteredFees =
          _fees.where((fee) {
            return fee.studentName.toLowerCase().contains(searchQuery) ||
                fee.courseName.toLowerCase().contains(searchQuery);
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
          case 'courseName':
            aValue = a.courseName;
            bValue = b.courseName;
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

  void _showAddEditFeeDialog([Fee? fee]) {
    if (fee != null) {
      _studentNameController.text = fee.studentName;
      _courseNameController.text = fee.courseName;
      _amountController.text = fee.amount.toString();
      _selectedDueDate = fee.dueDate;
      _dueDateController.text =
          '${fee.dueDate.day}/${fee.dueDate.month}/${fee.dueDate.year}';
    } else {
      _studentNameController.clear();
      _courseNameController.clear();
      _amountController.clear();
      _dueDateController.clear();
      _selectedDueDate = null;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(fee == null ? 'Add Fee Record' : 'Edit Fee Record'),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _studentNameController,
                      decoration: const InputDecoration(
                        labelText: 'Student Name',
                        border: OutlineInputBorder(),
                      ),
                      validator:
                          (value) =>
                              value?.isEmpty == true ? 'Required field' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _courseNameController,
                      decoration: const InputDecoration(
                        labelText: 'Course/Program Name',
                        border: OutlineInputBorder(),
                      ),
                      validator:
                          (value) =>
                              value?.isEmpty == true ? 'Required field' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Fee Amount',
                        border: OutlineInputBorder(),
                        prefixText: '\$',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty == true) return 'Required field';
                        if (double.tryParse(value!) == null) {
                          return 'Please enter a valid amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _dueDateController,
                      decoration: InputDecoration(
                        labelText: 'Due Date',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () => _selectDate(context),
                        ),
                      ),
                      readOnly: true,
                      validator:
                          (value) =>
                              value?.isEmpty == true ? 'Required field' : null,
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
                onPressed: () {
                  if (_formKey.currentState?.validate() == true) {
                    final newFee = Fee(
                      id:
                          fee?.id ??
                          DateTime.now().millisecondsSinceEpoch.toString(),
                      studentName: _studentNameController.text,
                      courseName: _courseNameController.text,
                      amount: double.parse(_amountController.text),
                      dueDate: _selectedDueDate!,
                      isPaid: fee?.isPaid ?? false,
                    );

                    setState(() {
                      if (fee != null) {
                        // Update existing fee
                        final index = _fees.indexWhere((f) => f.id == fee.id);
                        if (index != -1) {
                          _fees[index] = newFee;
                        }
                      } else {
                        // Add new fee
                        _fees.add(newFee);
                      }
                      _filterFees();
                    });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          fee == null
                              ? 'Fee record added successfully'
                              : 'Fee record updated successfully',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                child: Text(fee == null ? 'Add' : 'Update'),
              ),
            ],
          ),
    );
  }

  void _deleteFee(Fee fee) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Fee Record'),
            content: Text(
              'Are you sure you want to delete the fee record for ${fee.studentName}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _fees.removeWhere((f) => f.id == fee.id);
                    _filterFees();
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fee record deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  void _togglePaymentStatus(Fee fee) {
    setState(() {
      final index = _fees.indexWhere((f) => f.id == fee.id);
      if (index != -1) {
        final updatedFee = Fee(
          id: fee.id,
          studentName: fee.studentName,
          courseName: fee.courseName,
          amount: fee.amount,
          dueDate: fee.dueDate,
          isPaid: !fee.isPaid,
        );
        _fees[index] = updatedFee;
        _filterFees();
      }
    });
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search',
                  hintText: 'Search by student or course name',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (value) => _filterFees(),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    columns: [
                      DataColumn(
                        label: const Text('Student Name'),
                        onSort:
                            (_, ascending) =>
                                _sortFees('studentName', ascending),
                      ),
                      DataColumn(
                        label: const Text('Course Name'),
                        onSort:
                            (_, ascending) =>
                                _sortFees('courseName', ascending),
                      ),
                      DataColumn(
                        label: const Text('Amount'),
                        numeric: true,
                        onSort:
                            (_, ascending) => _sortFees('amount', ascending),
                      ),
                      DataColumn(
                        label: const Text('Due Date'),
                        onSort:
                            (_, ascending) => _sortFees('dueDate', ascending),
                      ),
                      DataColumn(
                        label: const Text('Status'),
                        onSort:
                            (_, ascending) => _sortFees('status', ascending),
                      ),
                      const DataColumn(label: Text('Actions')),
                    ],
                    rows:
                        _filteredFees.map((fee) {
                          return DataRow(
                            cells: [
                              DataCell(Text(fee.studentName)),
                              DataCell(Text(fee.courseName)),
                              DataCell(
                                Text('\$${fee.amount.toStringAsFixed(2)}'),
                              ),
                              DataCell(
                                Text(
                                  '${fee.dueDate.day}/${fee.dueDate.month}/${fee.dueDate.year}',
                                ),
                              ),
                              DataCell(
                                GestureDetector(
                                  onTap: () => _togglePaymentStatus(fee),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          fee.isPaid
                                              ? Colors.green.withOpacity(0.1)
                                              : Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      fee.isPaid ? 'Paid' : 'Pending',
                                      style: TextStyle(
                                        color:
                                            fee.isPaid
                                                ? Colors.green
                                                : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      ),
                                      onPressed:
                                          () => _showAddEditFeeDialog(fee),
                                      tooltip: 'Edit',
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _deleteFee(fee),
                                      tooltip: 'Delete',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                  ),
                ),
              ),
            ),
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
}
