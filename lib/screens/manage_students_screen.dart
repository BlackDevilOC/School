import 'package:flutter/material.dart';
import '../models/student.dart';
import '../services/database_service.dart';
import 'package:uuid/uuid.dart';

class ManageStudentsScreen extends StatefulWidget {
  const ManageStudentsScreen({super.key});

  @override
  _ManageStudentsScreenState createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends State<ManageStudentsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final Uuid _uuid = const Uuid();
  List<Student> _students = [];
  bool _isLoading = true;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _classGradeController = TextEditingController();
  final TextEditingController _rollNumberController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _courseNameController = TextEditingController();
  final TextEditingController _batchNumberController = TextEditingController();

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
      final students = await _databaseService.getStudents();
      setState(() {
        _students = students;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading students: $e')),
      );
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
      _isEditing = true;
      _isClassStudent = student.isClassStudent;
    } else {
      _resetForm();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                top: 16,
                left: 16,
                right: 16,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _isEditing ? 'Edit Student' : 'Add New Student',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Please enter a name' : null,
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('Class Student'),
                      value: _isClassStudent,
                      onChanged: (value) {
                        setModalState(() => _isClassStudent = value);
                      },
                    ),
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
      appBar: AppBar(
        title: const Text('Manage Students'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStudents,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _students.isEmpty
              ? const Center(child: Text('No students found'))
              : ListView.builder(
                  itemCount: _students.length,
                  itemBuilder: (context, index) {
                    final student = _students[index];
                    return ListTile(
                      title: Text(student.name),
                      subtitle: Text(
                        student.isClassStudent
                            ? 'Class: ${student.classGrade}'
                            : 'Course: ${student.courseName}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showForm(student: student),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteStudent(student.id),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
