import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/teacher.dart';
import '../models/teacher_salary.dart';
import '../services/database_service.dart';
import 'teacher_salary_records_screen.dart';

class TeacherSalaryScreen extends StatefulWidget {
  const TeacherSalaryScreen({Key? key}) : super(key: key);

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
  bool _isLoading = true;

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _salaryController = TextEditingController();
  final TextEditingController _paymentDateController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _paymentMethodController =
      TextEditingController();
  DateTime? _selectedPaymentDate;
  String _selectedStatus = 'Pending';
  String _selectedPaymentMethod = 'Bank Transfer';

  List<Teacher> _teachers = [];
  List<TeacherSalary> _salaries = [];
  List<TeacherSalary> _filteredSalaries = [];

  // Get unique payment methods
  List<String> get _paymentMethods {
    final methods = _salaries
        .where((s) => s.paymentMethod != null && s.paymentMethod!.isNotEmpty)
        .map((s) => s.paymentMethod!)
        .toSet()
        .toList();
    methods.sort();
    return ['Bank Transfer', 'Cash', 'Check', ...methods];
  }

  // Get total unpaid amount
  double get _totalUnpaidAmount {
    return _salaries
        .where((s) => !s.isPaid)
        .fold(0.0, (sum, salary) => sum + salary.amount);
  }

  // Get count of unpaid salaries
  int get _unpaidCount {
    return _salaries.where((s) => !s.isPaid).length;
  }

  // Get count of overdue salaries
  int get _overdueCount {
    return _salaries.where((s) => s.isOverdue).length;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load teachers
      _teachers = await _databaseService.getTeachers();

      // Generate current month salaries if needed
      await _databaseService.generateCurrentMonthTeacherSalaries();

      // Update overdue salaries
      await _databaseService.updateOverdueTeacherSalaries();

      // Load current month salaries
      _salaries = await _databaseService.getCurrentMonthTeacherSalaries();
      _filterSalaries();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _salaryController.dispose();
    _paymentDateController.dispose();
    _notesController.dispose();
    _paymentMethodController.dispose();
    super.dispose();
  }

  void _filterSalaries() {
    setState(() {
      if (_searchController.text.isEmpty) {
        _filteredSalaries = List.from(_salaries);
      } else {
        final query = _searchController.text.toLowerCase();
        _filteredSalaries = _salaries
            .where((salary) =>
                salary.teacherName.toLowerCase().contains(query) ||
                salary.status.toLowerCase().contains(query) ||
                (salary.paymentMethod != null &&
                    salary.paymentMethod!.toLowerCase().contains(query)))
            .toList();
      }

      if (_sortColumn != null) {
        _sortSalaries(_sortColumn!, _sortAscending);
      }
    });
  }

  void _sortSalaries(String column, bool ascending) {
    setState(() {
      _sortColumn = column;
      _sortAscending = ascending;

      _filteredSalaries.sort((a, b) {
        var aValue;
        var bValue;

        switch (column) {
          case 'name':
            aValue = a.teacherName;
            bValue = b.teacherName;
            break;
          case 'amount':
            aValue = a.amount;
            bValue = b.amount;
            break;
          case 'paymentDate':
            aValue = a.paymentDate;
            bValue = b.paymentDate;
            break;
          case 'status':
            aValue = a.status;
            bValue = b.status;
            break;
          default:
            return 0;
        }

        int result;
        if (aValue is String) {
          result = aValue.compareTo(bValue);
        } else if (aValue is num) {
          result = aValue.compareTo(bValue);
        } else if (aValue is DateTime) {
          result = aValue.compareTo(bValue);
        } else {
          result = 0;
        }

        return ascending ? result : -result;
      });
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedPaymentDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedPaymentDate = picked;
        _paymentDateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _togglePaymentStatus(TeacherSalary salary) async {
    final newStatus = salary.isPaid ? 'Pending' : 'Paid';

    try {
      await _databaseService.updateTeacherSalaryStatus(salary.id, newStatus);
      await _loadData(); // Reload data

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == 'Paid'
                ? 'Salary marked as Paid'
                : 'Salary marked as Pending',
          ),
          backgroundColor: newStatus == 'Paid' ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating salary status: $e')),
      );
    }
  }

  void _viewSalaryHistory(String teacherId, String teacherName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeacherSalaryRecordsScreen(
          teacherId: teacherId,
          teacherName: teacherName,
        ),
      ),
    ).then((_) => _loadData()); // Reload data when returning
  }

  Future<void> _showAddEditSalaryDialog([TeacherSalary? salary]) async {
    // Clear previous form data
    _nameController.clear();
    _salaryController.clear();
    _paymentDateController.clear();
    _notesController.clear();
    _selectedPaymentDate = null;
    _selectedStatus = 'Pending';
    _selectedPaymentMethod = 'Bank Transfer';

    // If editing, populate form with salary data
    Teacher? selectedTeacher;
    if (salary != null) {
      selectedTeacher = _teachers.firstWhere((t) => t.id == salary.teacherId);
      _nameController.text = salary.teacherName;
      _salaryController.text = salary.amount.toString();
      _selectedPaymentDate = salary.paymentDate;
      _paymentDateController.text =
          DateFormat('dd/MM/yyyy').format(salary.paymentDate);
      _selectedStatus = salary.status;
      _selectedPaymentMethod = salary.paymentMethod ?? 'Bank Transfer';
      _notesController.text = salary.notes ?? '';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text(salary == null ? 'Add Salary Record' : 'Edit Salary Record'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Teacher dropdown
                DropdownButtonFormField<Teacher>(
                  decoration: const InputDecoration(labelText: 'Teacher'),
                  value: selectedTeacher,
                  items: _teachers.map((teacher) {
                    return DropdownMenuItem<Teacher>(
                      value: teacher,
                      child: Text(teacher.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _nameController.text = value.name;
                        _salaryController.text = value.salary.toString();
                      });
                    }
                  },
                  validator: (value) =>
                      value == null ? 'Please select a teacher' : null,
                ),
                const SizedBox(height: 16),

                // Salary amount
                TextFormField(
                  controller: _salaryController,
                  decoration: const InputDecoration(labelText: 'Salary Amount'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter salary amount';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Payment date
                TextFormField(
                  controller: _paymentDateController,
                  decoration: const InputDecoration(labelText: 'Payment Date'),
                  readOnly: true,
                  onTap: () => _selectDate(context),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select payment date';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Status dropdown
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Status'),
                  value: _selectedStatus,
                  items: ['Paid', 'Pending', 'Overdue'].map((status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(status),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedStatus = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Payment method dropdown
                DropdownButtonFormField<String>(
                  decoration:
                      const InputDecoration(labelText: 'Payment Method'),
                  value: _selectedPaymentMethod,
                  items: _paymentMethods.map((method) {
                    return DropdownMenuItem<String>(
                      value: method,
                      child: Text(method),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedPaymentMethod = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Notes
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 3,
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
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final now = DateTime.now();
                final selectedTeacher = _teachers.firstWhere(
                  (t) => t.name == _nameController.text,
                  orElse: () => _teachers.first,
                );

                try {
                  if (salary == null) {
                    // Create new salary record
                    final newSalary = TeacherSalary(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      teacherId: selectedTeacher.id,
                      teacherName: selectedTeacher.name,
                      amount: double.parse(_salaryController.text),
                      paymentDate: _selectedPaymentDate ?? now,
                      month: now.month,
                      year: now.year,
                      status: _selectedStatus,
                      paymentMethod: _selectedPaymentMethod,
                      notes: _notesController.text.isNotEmpty
                          ? _notesController.text
                          : null,
                      createdAt: now,
                      updatedAt: now,
                    );

                    await _databaseService.addTeacherSalary(newSalary);
                  } else {
                    // Update existing salary record
                    final updatedSalary = salary.copyWith(
                      teacherId: selectedTeacher.id,
                      teacherName: selectedTeacher.name,
                      amount: double.parse(_salaryController.text),
                      paymentDate: _selectedPaymentDate ?? now,
                      status: _selectedStatus,
                      paymentMethod: _selectedPaymentMethod,
                      notes: _notesController.text.isNotEmpty
                          ? _notesController.text
                          : null,
                      updatedAt: now,
                    );

                    await _databaseService.updateTeacherSalary(updatedSalary);
                  }

                  // Close dialog and reload data
                  if (mounted) {
                    Navigator.pop(context);
                    await _loadData();
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving salary record: $e')),
                  );
                }
              }
            },
            child: Text(salary == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        brightness: _isDarkMode ? Brightness.dark : Brightness.light,
      ),
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
                children: [
                  _buildSearchBar(),
                  _buildSummaryCards(),
                  Expanded(child: _buildSalaryTable()),
                ],
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
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _filterSalaries();
                  },
                )
              : null,
        ),
        onChanged: (_) => _filterSalaries(),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: Card(
              color: Colors.blue.shade100,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Unpaid',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currencyFormat.format(_totalUnpaidAmount),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Card(
              color: Colors.orange.shade100,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pending',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_unpaidCount salaries',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Card(
              color: Colors.red.shade100,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Overdue',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_overdueCount salaries',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalaryTable() {
    if (_salaries.isEmpty) {
      return const Center(
        child: Text(
          'No salary records found for the current month.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    if (_filteredSalaries.isEmpty) {
      return const Center(
        child: Text(
          'No matching salary records found.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns: [
            DataColumn(
              label: const Text('Name'),
              onSort: (columnIndex, ascending) =>
                  _sortSalaries('name', ascending),
            ),
            DataColumn(
              label: const Text('Amount'),
              numeric: true,
              onSort: (columnIndex, ascending) =>
                  _sortSalaries('amount', ascending),
            ),
            DataColumn(
              label: const Text('Payment Date'),
              onSort: (columnIndex, ascending) =>
                  _sortSalaries('paymentDate', ascending),
            ),
            DataColumn(
              label: const Text('Status'),
              onSort: (columnIndex, ascending) =>
                  _sortSalaries('status', ascending),
            ),
            const DataColumn(label: Text('Actions')),
          ],
          rows: _filteredSalaries.map((salary) {
            final dateFormat = DateFormat('dd/MM/yyyy');
            final currencyFormat = NumberFormat.currency(symbol: '\$');

            return DataRow(
              cells: [
                DataCell(Text(salary.teacherName)),
                DataCell(Text(currencyFormat.format(salary.amount))),
                DataCell(
                  Text(
                    dateFormat.format(salary.paymentDate),
                    style: salary.isOverdue
                        ? const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          )
                        : null,
                  ),
                ),
                DataCell(
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: salary.isPaid
                          ? Colors.green.shade100
                          : salary.isOverdue
                              ? Colors.red.shade100
                              : Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      salary.status,
                      style: TextStyle(
                        color: salary.isPaid
                            ? Colors.green.shade800
                            : salary.isOverdue
                                ? Colors.red.shade800
                                : Colors.orange.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          salary.isPaid
                              ? Icons.unpublished
                              : Icons.check_circle,
                          color: salary.isPaid ? Colors.orange : Colors.green,
                        ),
                        onPressed: () => _togglePaymentStatus(salary),
                        tooltip:
                            salary.isPaid ? 'Mark as Unpaid' : 'Mark as Paid',
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showAddEditSalaryDialog(salary),
                        tooltip: 'Edit Salary',
                      ),
                      IconButton(
                        icon: const Icon(Icons.history, color: Colors.purple),
                        onPressed: () => _viewSalaryHistory(
                            salary.teacherId, salary.teacherName),
                        tooltip: 'View Salary History',
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
