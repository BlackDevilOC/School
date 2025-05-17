import 'package:flutter/material.dart';
import '../models/student.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';
import 'package:uuid/uuid.dart';

class ManageStudentsScreen extends StatefulWidget {
  const ManageStudentsScreen({super.key});

  @override
  _ManageStudentsScreenState createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends State<ManageStudentsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final SyncService _syncService = SyncService(DatabaseService());
  final Uuid _uuid = const Uuid();
  List<Student> _students = [];
  bool _isLoading = true;
  final _scrollController = ScrollController();

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _classGradeController = TextEditingController();
  final TextEditingController _rollNumberController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _courseNameController = TextEditingController();
  final TextEditingController _batchNumberController = TextEditingController();
  final TextEditingController _feeAmountController = TextEditingController();

  String? _currentStudentId;
  bool _isEditing = false;
  bool _isClassStudent = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    try {
      // Load cached data first
      final cachedStudents = await _syncService.getStudentsWithCache();
      if (cachedStudents.isNotEmpty) {
        setState(() {
          _students = cachedStudents;
          _isLoading = false;
        });
      }

      // Load fresh data
      final students = await _databaseService.getStudents();
      if (mounted) {
        setState(() {
          _students = students;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading students: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _classGradeController.dispose();
    _rollNumberController.dispose();
    _phoneNumberController.dispose();
    _courseNameController.dispose();
    _batchNumberController.dispose();
    _feeAmountController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _classGradeController.clear();
    _rollNumberController.clear();
    _phoneNumberController.clear();
    _courseNameController.clear();
    _batchNumberController.clear();
    _feeAmountController.clear();
    _currentStudentId = null;
    _isEditing = false;
    setState(() => _isClassStudent = true);
  }

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) return;

    final student = Student(
      id: _isEditing ? _currentStudentId! : _uuid.v4(),
      name: _nameController.text,
      classGrade: _isClassStudent ? _classGradeController.text : null,
      rollNumber: _rollNumberController.text,
      phoneNumber: _phoneNumberController.text,
      courseName: !_isClassStudent ? _courseNameController.text : null,
      batchNumber: !_isClassStudent ? _batchNumberController.text : null,
      isClassStudent: _isClassStudent,
      feeAmount: double.tryParse(_feeAmountController.text) ?? 0.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      if (_isEditing) {
        await _databaseService.updateStudent(student);
      } else {
        await _databaseService.addStudent(student);
      }
      _resetForm();
      await _loadStudents();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving student: $e')),
      );
    }
  }

  Future<void> _deleteStudent(String id) async {
    try {
      await _databaseService.deleteStudent(id);
      await _loadStudents();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting student: $e')),
      );
    }
  }

  void _showForm({Student? student}) {
    if (student != null) {
      _currentStudentId = student.id;
      _nameController.text = student.name;
      _classGradeController.text = student.classGrade ?? '';
      _rollNumberController.text = student.rollNumber;
      _phoneNumberController.text = student.phoneNumber;
      _courseNameController.text = student.courseName ?? '';
      _batchNumberController.text = student.batchNumber ?? '';
      _feeAmountController.text = student.feeAmount.toString();
      _isEditing = true;
      setState(() => _isClassStudent = student.isClassStudent);
    } else {
      _resetForm();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 1,
                      itemBuilder: (context, index) {
                        return Text(
                          _isEditing ? 'Edit Student' : 'Add New Student',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Please enter name' : null,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text('Class Student'),
                            value: true,
                            groupValue: _isClassStudent,
                            onChanged: (value) {
                              setState(() => _isClassStudent = value!);
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text('Course Student'),
                            value: false,
                            groupValue: _isClassStudent,
                            onChanged: (value) {
                              setState(() => _isClassStudent = value!);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_isClassStudent) ...[
                      TextFormField(
                        controller: _classGradeController,
                        decoration:
                            const InputDecoration(labelText: 'Class/Grade'),
                        validator: (value) =>
                            _isClassStudent && (value?.isEmpty ?? true)
                                ? 'Please enter class/grade'
                                : null,
                      ),
                    ] else ...[
                      TextFormField(
                        controller: _courseNameController,
                        decoration:
                            const InputDecoration(labelText: 'Course Name'),
                        validator: (value) =>
                            !_isClassStudent && (value?.isEmpty ?? true)
                                ? 'Please enter course name'
                                : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _batchNumberController,
                        decoration:
                            const InputDecoration(labelText: 'Batch Number'),
                        validator: (value) =>
                            !_isClassStudent && (value?.isEmpty ?? true)
                                ? 'Please enter batch number'
                                : null,
                      ),
                    ],
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _rollNumberController,
                      decoration:
                          const InputDecoration(labelText: 'Roll Number'),
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Please enter roll number'
                          : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneNumberController,
                      decoration:
                          const InputDecoration(labelText: 'Phone Number'),
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Please enter phone number'
                          : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _feeAmountController,
                      decoration: const InputDecoration(
                        labelText: 'Fee Amount',
                        prefixText: '\$',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter fee amount';
                        }
                        if (double.tryParse(value!) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _saveStudent,
                      child: Text(_isEditing ? 'Update' : 'Add'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Manage Students'),
        backgroundColor: Colors.green,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStudents,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStudents,
        child: _isLoading && _students.isEmpty
            ? const Center(child: CircularProgressIndicator(color: Colors.green))
            : _students.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_off, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No students found',
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => _showForm(),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Student'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Determine if we should use a grid or list based on screen width
                        final isWideScreen = constraints.maxWidth > 600;
                        
                        if (isWideScreen) {
                          // Grid layout for wider screens
                          return GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 3.5,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: _students.length,
                            itemBuilder: (context, index) {
                              return _buildStudentCard(_students[index]);
                            },
                          );
                        } else {
                          // List layout for narrower screens
                          return ListView.builder(
                            itemCount: _students.length,
                            itemBuilder: (context, index) {
                              return _buildStudentCard(_students[index]);
                            },
                          );
                        }
                      },
                    ),
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
        tooltip: 'Add Student',
      ),
    );
  }
  
  Widget _buildStudentCard(Student student) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () => _showForm(student: student),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar/Icon
              CircleAvatar(
                backgroundColor: Colors.green.shade100,
                radius: 16,
                child: Text(
                  student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                  style: TextStyle(fontSize: 14, color: Colors.green.shade800),
                ),
              ),
              const SizedBox(width: 10),
              // Student details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      student.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          student.isClassStudent
                              ? 'Class: ${student.classGrade}'
                              : 'Course: ${student.courseName ?? "N/A"}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.phone, size: 12, color: Colors.grey[600]),
                        const SizedBox(width: 2),
                        Text(
                          student.phoneNumber,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    if (student.feeAmount > 0)
                      Row(
                        children: [
                          Icon(Icons.attach_money, size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 2),
                          Text(
                            '${student.feeAmount.toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              // Action buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                    onPressed: () => _showForm(student: student),
                    tooltip: 'Edit',
                    constraints: const BoxConstraints(maxHeight: 30, maxWidth: 30),
                    padding: EdgeInsets.zero,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                    onPressed: () => _showDeleteConfirmation(student),
                    tooltip: 'Delete',
                    constraints: const BoxConstraints(maxHeight: 30, maxWidth: 30),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _showDeleteConfirmation(Student student) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                Text('Are you sure you want to delete ${student.name}?'),
                const SizedBox(height: 8),
                const Text('This action cannot be undone.'),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteStudent(student.id);
              },
            ),
          ],
        );
      },
    );
  }
}
