import 'package:flutter/material.dart';
import '../services/data_service.dart';
import '../models/fee.dart';

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
  final TextEditingController _courseNameController = TextEditingController();
  final TextEditingController _batchNumberController = TextEditingController();
  final TextEditingController _feeAmountController = TextEditingController();

  String? _currentStudentId;
  bool _isEditing = false;
  bool _isClassStudent = true; // Default to class student

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
    setState(() {
      _isClassStudent = true;
    });
  }

  void _showForm({Map<String, dynamic>? student}) {
    if (student != null) {
      // Editing existing student
      _currentStudentId = student['id'];
      _nameController.text = student['name'];
      _classGradeController.text = student['classGrade'] ?? '';
      _rollNumberController.text = student['rollNumber'].toString();
      _phoneNumberController.text = student['phoneNumber'];
      _courseNameController.text = student['courseName'] ?? '';
      _batchNumberController.text = student['batchNumber'] ?? '';
      _feeAmountController.text = student['feeAmount']?.toString() ?? '';
      _isEditing = true;
      _isClassStudent = student['isClassStudent'] ?? true;
    } else {
      // Adding new student
      _resetForm();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => StatefulBuilder(
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
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<bool>(
                                title: Text('Class Student'),
                                value: true,
                                groupValue: _isClassStudent,
                                onChanged: (bool? value) {
                                  if (value != null) {
                                    setModalState(() {
                                      _isClassStudent = value;
                                    });
                                    setState(() {
                                      _isClassStudent = value;
                                    });
                                  }
                                },
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<bool>(
                                title: Text('Course Student'),
                                value: false,
                                groupValue: _isClassStudent,
                                onChanged: (bool? value) {
                                  if (value != null) {
                                    setModalState(() {
                                      _isClassStudent = value;
                                    });
                                    setState(() {
                                      _isClassStudent = value;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        if (_isClassStudent)
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
                              if (_isClassStudent &&
                                  (value == null || value.isEmpty)) {
                                return 'Please enter class/grade';
                              }
                              return null;
                            },
                          )
                        else ...[
                          TextFormField(
                            controller: _courseNameController,
                            decoration: InputDecoration(
                              labelText: 'Course Name',
                              border: OutlineInputBorder(),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.green,
                                  width: 2.0,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (!_isClassStudent &&
                                  (value == null || value.isEmpty)) {
                                return 'Please enter course name';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 12),
                          TextFormField(
                            controller: _batchNumberController,
                            decoration: InputDecoration(
                              labelText: 'Batch Number',
                              border: OutlineInputBorder(),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.green,
                                  width: 2.0,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (!_isClassStudent &&
                                  (value == null || value.isEmpty)) {
                                return 'Please enter batch number';
                              }
                              return null;
                            },
                          ),
                        ],
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
                        Divider(height: 32),
                        Text(
                          'Fee Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _feeAmountController,
                          decoration: InputDecoration(
                            labelText: 'Fee Amount',
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.green,
                                width: 2.0,
                              ),
                            ),
                            prefixText: '\$',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter fee amount';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid amount';
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
                              onPressed: _submitForm,
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
              );
            },
          ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final student = {
        'name': _nameController.text,
        'isClassStudent': _isClassStudent,
        'rollNumber': int.parse(_rollNumberController.text),
        'phoneNumber': _phoneNumberController.text,
        'feeAmount': double.tryParse(_feeAmountController.text) ?? 0.0,
      };

      if (_isClassStudent) {
        student['classGrade'] = _classGradeController.text;
      } else {
        student['courseName'] = _courseNameController.text;
        student['batchNumber'] = _batchNumberController.text;
      }

      if (_isEditing && _currentStudentId != null) {
        student['id'] = _currentStudentId!;
        _dataService.updateStudent(_currentStudentId!, student);
      } else {
        student['id'] = DateTime.now().millisecondsSinceEpoch.toString();
        _dataService.addStudent(student);
      }

      // Create initial fee record
      if (!_isEditing) {
        final fee = Fee(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          studentName: _nameController.text,
          classGrade: _isClassStudent ? _classGradeController.text : null,
          courseName: !_isClassStudent ? _courseNameController.text : null,
          batchNumber: !_isClassStudent ? _batchNumberController.text : null,
          amount: double.parse(_feeAmountController.text),
          dueDate: DateTime.now().add(
            const Duration(days: 30),
          ), // Default due date to 30 days from now
          isPaid: false,
          isClassStudent: _isClassStudent,
        );
        _dataService.addFee(fee);
      }

      setState(() {
        students = _dataService.students;
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Student updated successfully!'
                : 'Student added successfully!',
          ),
          backgroundColor: Colors.green,
        ),
      );
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
                  final bool isClassStudent = student['isClassStudent'] ?? true;
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
                          if (isClassStudent)
                            Text(
                              'Class: ${student['classGrade']}',
                              style: TextStyle(color: Colors.black87),
                            )
                          else ...[
                            Text(
                              'Course: ${student['courseName']}',
                              style: TextStyle(color: Colors.black87),
                            ),
                            Text(
                              'Batch: ${student['batchNumber']}',
                              style: TextStyle(color: Colors.black87),
                            ),
                          ],
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
