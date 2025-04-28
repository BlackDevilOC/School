import 'package:flutter/material.dart';
import '../services/data_service.dart';

class ManageStudentsScreen extends StatefulWidget {
  const ManageStudentsScreen({super.key});

  @override
  _ManageStudentsScreenState createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends State<ManageStudentsScreen> {
  final DataService _dataService = DataService();
  late List<Map<String, dynamic>> students;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _classGradeController = TextEditingController();
  final TextEditingController _rollNumberController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();

  String? _currentStudentId;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    students = _dataService.students;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _classGradeController.dispose();
    _rollNumberController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _classGradeController.clear();
    _rollNumberController.clear();
    _phoneNumberController.clear();
    _currentStudentId = null;
    _isEditing = false;
  }

  void _showForm({Map<String, dynamic>? student}) {
    if (student != null) {
      // Editing existing student
      _currentStudentId = student['id'];
      _nameController.text = student['name'];
      _classGradeController.text = student['classGrade'];
      _rollNumberController.text = student['rollNumber'].toString();
      _phoneNumberController.text = student['phoneNumber'];
      _isEditing = true;
    } else {
      // Adding new student
      _resetForm();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => SingleChildScrollView(
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
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.green,
                            width: 2.0,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: _classGradeController,
                      decoration: InputDecoration(
                        labelText: 'Class/Grade',
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.green,
                            width: 2.0,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter class/grade';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: _rollNumberController,
                      decoration: InputDecoration(
                        labelText: 'Roll Number',
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.green,
                            width: 2.0,
                          ),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter roll number';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Roll number must be a valid number';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneNumberController,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.green,
                            width: 2.0,
                          ),
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter phone number';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _resetForm();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade500,
                          ),
                          child: Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: _saveStudent,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          child: Text(_isEditing ? 'Update' : 'Save'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  void _saveStudent() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context);

      final name = _nameController.text;
      final classGrade = _classGradeController.text;
      final rollNumber = int.parse(_rollNumberController.text);
      final phoneNumber = _phoneNumberController.text;

      setState(() {
        if (_isEditing) {
          // Update existing student
          final updatedStudent = {
            'id': _currentStudentId!,
            'name': name,
            'classGrade': classGrade,
            'rollNumber': rollNumber,
            'phoneNumber': phoneNumber,
            // Keep isPresent value if exists, otherwise set default value
            'isPresent':
                students.firstWhere(
                  (s) => s['id'] == _currentStudentId,
                )['isPresent'] ??
                true,
          };

          _dataService.updateStudent(_currentStudentId!, updatedStudent);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Student updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Add new student
          final newId =
              (int.parse(students.isNotEmpty ? students.last['id'] : '0') + 1)
                  .toString();
          final newStudent = {
            'id': newId,
            'name': name,
            'classGrade': classGrade,
            'rollNumber': rollNumber,
            'phoneNumber': phoneNumber,
            'isPresent': true, // Default new students to present
          };

          _dataService.addStudent(newStudent);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Student added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
        // Refresh students list from data service
        students = _dataService.students;
      });

      _resetForm();
    }
  }

  void _deleteStudent(String id) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Delete Student'),
            content: Text('Are you sure you want to delete this student?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _dataService.deleteStudent(id);
                    // Refresh students list from data service
                    students = _dataService.students;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Student deleted successfully'),
                      backgroundColor: Colors.red.shade700,
                    ),
                  );
                },
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Students'),
        backgroundColor: Colors.green,
      ),
      body:
          students.isEmpty
              ? Center(
                child: Text(
                  'No students found.\nAdd a student using the button below.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              )
              : ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final student = students[index];
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 3,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green.shade200,
                        child: Text(
                          student['name'][0],
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        student['name'],
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Class: ${student['classGrade']}',
                            style: TextStyle(color: Colors.black87),
                          ),
                          Text(
                            'Roll #: ${student['rollNumber']}',
                            style: TextStyle(color: Colors.black87),
                          ),
                          Text(
                            'Phone: ${student['phoneNumber']}',
                            style: TextStyle(color: Colors.black87),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue.shade700),
                            onPressed: () => _showForm(student: student),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete,
                              color: Colors.red.shade700,
                            ),
                            onPressed: () => _deleteStudent(student['id']),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        backgroundColor: Colors.green,
        child: Icon(Icons.add),
      ),
    );
  }
}
