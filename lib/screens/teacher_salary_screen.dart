import 'package:flutter/material.dart';
import '../services/data_service.dart';

class TeacherSalaryScreen extends StatefulWidget {
  const TeacherSalaryScreen({super.key});

  @override
  _TeacherSalaryScreenState createState() => _TeacherSalaryScreenState();
}

class _TeacherSalaryScreenState extends State<TeacherSalaryScreen> {
  final DataService _dataService = DataService();
  final _formKey = GlobalKey<FormState>();
  bool _isDarkMode = false;
  String? _sortColumn;
  bool _sortAscending = true;
  final TextEditingController _searchController = TextEditingController();

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _salaryController = TextEditingController();
  final TextEditingController _paymentDateController = TextEditingController();
  DateTime? _selectedPaymentDate;

  late List<Map<String, dynamic>> teachers;
  late List<Map<String, dynamic>> filteredTeachers;

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _subjectController.dispose();
    _phoneNumberController.dispose();
    _salaryController.dispose();
    _paymentDateController.dispose();
    super.dispose();
  }

  void _loadTeachers() {
    setState(() {
      teachers = _dataService.teachers;
      _filterTeachers();
    });
  }

  void _filterTeachers() {
    final searchQuery = _searchController.text.toLowerCase();
    setState(() {
      filteredTeachers =
          teachers.where((teacher) {
            return teacher['name'].toLowerCase().contains(searchQuery) ||
                teacher['subject'].toLowerCase().contains(searchQuery);
          }).toList();

      if (_sortColumn != null) {
        _sortTeachers(_sortColumn!, _sortAscending);
      }
    });
  }

  void _sortTeachers(String column, bool ascending) {
    setState(() {
      _sortColumn = column;
      _sortAscending = ascending;

      filteredTeachers.sort((a, b) {
        var aValue;
        var bValue;

        switch (column) {
          case 'name':
            aValue = a['name'];
            bValue = b['name'];
            break;
          case 'subject':
            aValue = a['subject'];
            bValue = b['subject'];
            break;
          case 'salary':
            aValue = a['salary'] ?? 0.0;
            bValue = b['salary'] ?? 0.0;
            break;
          case 'status':
            aValue = a['isPaid'] ?? false;
            bValue = b['isPaid'] ?? false;
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
      initialDate: _selectedPaymentDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedPaymentDate = picked;
        _paymentDateController.text =
            '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  void _togglePaymentStatus(Map<String, dynamic> teacher) {
    final updatedTeacher = Map<String, dynamic>.from(teacher);
    updatedTeacher['isPaid'] = !(teacher['isPaid'] ?? false);

    _dataService.updateTeacher(teacher['id'], updatedTeacher);
    _loadTeachers();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          updatedTeacher['isPaid']
              ? 'Salary marked as Paid'
              : 'Salary marked as Pending',
        ),
        backgroundColor:
            updatedTeacher['isPaid'] ? Colors.green : Colors.orange,
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
            'Teacher Salary',
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
          children: [_buildSearchBar(), Expanded(child: _buildSalaryTable())],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddEditSalaryDialog(),
          backgroundColor: Colors.green,
          child: const Icon(Icons.add),
          tooltip: 'Add salary record',
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          labelText: 'Search',
          prefixIcon: const Icon(Icons.search),
          border: const OutlineInputBorder(),
        ),
        onChanged: (_) => _filterTeachers(),
      ),
    );
  }

  Widget _buildSalaryTable() {
    if (teachers.isEmpty) {
      return Center(
        child: Text(
          'No teachers found.\nAdd teachers from the Manage Teachers page first.',
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
            label: const Text('Name'),
            onSort:
                (columnIndex, ascending) => _sortTeachers('name', ascending),
          ),
          DataColumn(
            label: const Text('Subject'),
            onSort:
                (columnIndex, ascending) => _sortTeachers('subject', ascending),
          ),
          DataColumn(
            label: const Text('Salary'),
            numeric: true,
            onSort:
                (columnIndex, ascending) => _sortTeachers('salary', ascending),
          ),
          DataColumn(label: const Text('Payment Date')),
          DataColumn(
            label: const Text('Status'),
            onSort:
                (columnIndex, ascending) => _sortTeachers('status', ascending),
          ),
        ],
        rows:
            filteredTeachers.map((teacher) {
              final bool isPaid = teacher['isPaid'] ?? false;
              final DateTime paymentDate =
                  teacher['paymentDate'] ?? DateTime.now();
              final bool isOverdue =
                  !isPaid && paymentDate.isBefore(DateTime.now());

              return DataRow(
                cells: [
                  DataCell(Text(teacher['name'])),
                  DataCell(Text(teacher['subject'])),
                  DataCell(
                    Text('\$${(teacher['salary'] ?? 0.0).toStringAsFixed(2)}'),
                  ),
                  DataCell(
                    Text(
                      '${paymentDate.day}/${paymentDate.month}/${paymentDate.year}',
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
                      onTap: () => _togglePaymentStatus(teacher),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isPaid
                                  ? Colors.green.withOpacity(0.1)
                                  : isOverdue
                                  ? Colors.red.withOpacity(0.1)
                                  : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                isPaid
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
                              isPaid
                                  ? Icons.check_circle
                                  : isOverdue
                                  ? Icons.warning
                                  : Icons.pending,
                              color:
                                  isPaid
                                      ? Colors.green
                                      : isOverdue
                                      ? Colors.red
                                      : Colors.orange,
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              isPaid
                                  ? 'Paid'
                                  : isOverdue
                                  ? 'Overdue'
                                  : 'Pending',
                              style: TextStyle(
                                color:
                                    isPaid
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

  void _showAddEditSalaryDialog([Map<String, dynamic>? teacher]) {
    if (teacher != null) {
      _nameController.text = teacher['name'];
      _subjectController.text = teacher['subject'];
      _phoneNumberController.text = teacher['phoneNumber'];
      _salaryController.text = (teacher['salary'] ?? 0.0).toString();
      _selectedPaymentDate = teacher['paymentDate'] ?? DateTime.now();
      _paymentDateController.text =
          '${_selectedPaymentDate!.day}/${_selectedPaymentDate!.month}/${_selectedPaymentDate!.year}';
    } else {
      _nameController.clear();
      _subjectController.clear();
      _phoneNumberController.clear();
      _salaryController.clear();
      _paymentDateController.clear();
      _selectedPaymentDate = null;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              teacher == null ? 'Add Salary Record' : 'Edit Salary Record',
            ),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Teacher Name',
                        border: OutlineInputBorder(),
                      ),
                      validator:
                          (value) =>
                              value?.isEmpty == true ? 'Required field' : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _salaryController,
                      decoration: const InputDecoration(
                        labelText: 'Salary Amount',
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
                      controller: _paymentDateController,
                      decoration: const InputDecoration(
                        labelText: 'Payment Date',
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                      onTap: () => _selectDate(context),
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
                onPressed: () => _saveSalary(teacher),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: Text(teacher == null ? 'Add' : 'Update'),
              ),
            ],
          ),
    );
  }

  void _saveSalary(Map<String, dynamic>? existingTeacher) {
    if (_formKey.currentState?.validate() == true &&
        _selectedPaymentDate != null) {
      final updatedTeacher =
          existingTeacher != null
              ? Map<String, dynamic>.from(existingTeacher)
              : {
                'id': DateTime.now().millisecondsSinceEpoch.toString(),
                'name': _nameController.text,
                'subject': _subjectController.text,
                'phoneNumber': _phoneNumberController.text,
              };

      updatedTeacher['salary'] = double.parse(_salaryController.text);
      updatedTeacher['paymentDate'] = _selectedPaymentDate;
      updatedTeacher['isPaid'] = existingTeacher?['isPaid'] ?? false;

      if (existingTeacher != null) {
        _dataService.updateTeacher(existingTeacher['id'], updatedTeacher);
      } else {
        _dataService.addTeacher(updatedTeacher);
      }

      _loadTeachers();
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            existingTeacher == null
                ? 'Salary record added successfully'
                : 'Salary record updated successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
