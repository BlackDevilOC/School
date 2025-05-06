import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/teacher.dart';
import '../models/teacher_salary.dart';

class TeacherSalaryScreen extends StatefulWidget {
  const TeacherSalaryScreen({super.key});

  @override
  _TeacherSalaryScreenState createState() => _TeacherSalaryScreenState();
}

class _TeacherSalaryScreenState extends State<TeacherSalaryScreen> {
  final DatabaseService _databaseService = DatabaseService();
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

  late List<Teacher> teachers = [];
  late List<Teacher> filteredTeachers = [];
  late List<TeacherSalary> currentMonthSalaries = [];
  bool _isLoading = true;

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

  Future<void> _loadTeachers() async {
    setState(() => _isLoading = true);
    try {
      final teachersList = await _databaseService.getTeachers();
      
      // Also fetch the current month salaries to get payment status
      final salariesList = await _databaseService.getCurrentMonthSalaries();
      
      setState(() {
        teachers = teachersList;
        currentMonthSalaries = salariesList;
        _filterTeachers();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading teachers: $e')),
        );
      }
    }
  }

  void _filterTeachers() {
    final searchQuery = _searchController.text.toLowerCase();
    setState(() {
      filteredTeachers = teachers.where((teacher) {
        return teacher.name.toLowerCase().contains(searchQuery) ||
            teacher.subject.toLowerCase().contains(searchQuery);
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
            aValue = a.name;
            bValue = b.name;
            break;
          case 'subject':
            aValue = a.subject;
            bValue = b.subject;
            break;
          case 'salary':
            aValue = a.salary;
            bValue = b.salary;
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

  Future<void> _togglePaymentStatus(Teacher teacher) async {
    try {
      // Create a new teacher with updated salary status
      final now = DateTime.now();
      
      // Get current month salary for this teacher
      final salaries = await _databaseService.getCurrentMonthSalaries();
      final teacherSalary = salaries.firstWhere(
        (s) => s.teacherId == teacher.id && s.month == now.month && s.year == now.year,
        orElse: () => TeacherSalary(
          id: '',
          teacherId: teacher.id,
          amount: teacher.salary,
          dueDate: DateTime.now().add(const Duration(days: 30)),
          paymentDate: DateTime.now(),
          status: 'Pending',
          month: now.month,
          year: now.year,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      
      if (teacherSalary.id.isNotEmpty) {
        // Toggle status between Paid and Pending
        final newStatus = teacherSalary.status == 'Paid' ? 'Pending' : 'Paid';
        await _databaseService.updateSalaryStatus(teacherSalary.id, newStatus);
      }
      
      await _loadTeachers();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              teacherSalary.status == 'Paid'
                  ? 'Salary marked as Pending'
                  : 'Salary marked as Paid',
            ),
            backgroundColor:
                teacherSalary.status == 'Paid' ? Colors.orange : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating payment status: $e')),
        );
      }
    }
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
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
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
        decoration: const InputDecoration(
          labelText: 'Search',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
        ),
        onChanged: (_) => _filterTeachers(),
      ),
    );
  }

  Widget _buildSalaryTable() {
    if (teachers.isEmpty) {
      return const Center(
        child: Text(
          'No teachers found.\nAdd teachers from the Manage Teachers page first.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    final now = DateTime.now();

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
          const DataColumn(label: Text('Payment Date')),
          const DataColumn(label: Text('Status')),
        ],
        rows: filteredTeachers.map((teacher) {
          // Find the salary record for this teacher
          final teacherSalary = currentMonthSalaries.firstWhere(
            (s) => s.teacherId == teacher.id && s.month == now.month && s.year == now.year,
            orElse: () => TeacherSalary(
              id: '',
              teacherId: teacher.id,
              amount: teacher.salary,
              dueDate: now.add(const Duration(days: 30)),
              paymentDate: now,
              status: 'Pending',
              month: now.month,
              year: now.year,
              createdAt: now,
              updatedAt: now,
            ),
          );
          
          // Set the status based on the database record
          bool isPaid = teacherSalary.status == 'Paid';
          DateTime paymentDate = teacherSalary.paymentDate;
          bool isOverdue = !isPaid && teacherSalary.dueDate.isBefore(now);
          
          return DataRow(
            cells: [
              DataCell(Text(teacher.name)),
              DataCell(Text(teacher.subject)),
              DataCell(
                Text('\$${teacher.salary.toStringAsFixed(2)}'),
              ),
              DataCell(
                Text(
                  '${paymentDate.day}/${paymentDate.month}/${paymentDate.year}',
                  style: isOverdue
                      ? const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        )
                      : null,
                ),
              ),
              DataCell(
                Builder(
                  builder: (context) {
                    return InkWell(
                      onTap: () => _togglePaymentStatus(teacher),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(isPaid, isOverdue).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getStatusColor(isPaid, isOverdue),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getStatusIcon(isPaid, isOverdue),
                              color: _getStatusColor(isPaid, isOverdue),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getStatusText(isPaid, isOverdue),
                              style: TextStyle(
                                color: _getStatusColor(isPaid, isOverdue),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // Helper methods to avoid nested ternary operators
  Color _getStatusColor(bool isPaid, bool isOverdue) {
    if (isPaid) return Colors.green;
    if (isOverdue) return Colors.red;
    return Colors.orange;
  }

  IconData _getStatusIcon(bool isPaid, bool isOverdue) {
    if (isPaid) return Icons.check_circle;
    if (isOverdue) return Icons.warning;
    return Icons.pending;
  }

  String _getStatusText(bool isPaid, bool isOverdue) {
    if (isPaid) return 'Paid';
    if (isOverdue) return 'Overdue';
    return 'Pending';
  }

  void _showAddEditSalaryDialog([Teacher? existingTeacher]) {
    if (existingTeacher != null) {
      _nameController.text = existingTeacher.name;
      _subjectController.text = existingTeacher.subject;
      _phoneNumberController.text = existingTeacher.phoneNumber;
      _salaryController.text = existingTeacher.salary.toString();
      _selectedPaymentDate = DateTime.now();
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
      builder: (context) => AlertDialog(
        title: Text(
          existingTeacher == null ? 'Add Salary Record' : 'Edit Salary Record',
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
                  validator: (value) =>
                      value?.isEmpty == true ? 'Required field' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _subjectController,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value?.isEmpty == true ? 'Required field' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value?.isEmpty == true ? 'Required field' : null,
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 16),
                TextFormField(
                  controller: _paymentDateController,
                  decoration: const InputDecoration(
                    labelText: 'Payment Date',
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true,
                  onTap: () => _selectDate(context),
                  validator: (value) =>
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
            onPressed: () => _saveSalary(existingTeacher),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text(existingTeacher == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSalary(Teacher? existingTeacher) async {
    if (_formKey.currentState?.validate() == true &&
        _selectedPaymentDate != null) {
      try {
        final now = DateTime.now();
        
        // Create or update teacher
        final teacher = Teacher(
          id: existingTeacher?.id ?? '',
          name: _nameController.text,
          subject: _subjectController.text,
          phoneNumber: _phoneNumberController.text,
          salary: double.parse(_salaryController.text),
          createdAt: existingTeacher?.createdAt ?? now,
          updatedAt: now,
        );

        if (existingTeacher != null) {
          await _databaseService.updateTeacher(teacher);
        } else {
          await _databaseService.addTeacher(teacher);
        }

        await _loadTeachers();
        
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                existingTeacher == null
                    ? 'Teacher added successfully'
                    : 'Teacher updated successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving teacher: $e')),
          );
        }
      }
    }
  }
}
