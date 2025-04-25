import 'package:flutter/material.dart';
import '../services/data_service.dart';

class ManageTeachersScreen extends StatefulWidget {
  const ManageTeachersScreen({super.key});

  @override
  _ManageTeachersScreenState createState() => _ManageTeachersScreenState();
}

class _ManageTeachersScreenState extends State<ManageTeachersScreen> {
  final DataService _dataService = DataService();
  late List<Map<String, dynamic>> teachers;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();

  String? _currentTeacherId;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    teachers = _dataService.teachers;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subjectController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _subjectController.clear();
    _phoneNumberController.clear();
    _currentTeacherId = null;
    _isEditing = false;
  }

  void _showForm({Map<String, dynamic>? teacher}) {
    if (teacher != null) {
      // Editing existing teacher
      _currentTeacherId = teacher['id'];
      _nameController.text = teacher['name'];
      _subjectController.text = teacher['subject'];
      _phoneNumberController.text = teacher['phoneNumber'];
      _isEditing = true;
    } else {
      // Adding new teacher
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
                      _isEditing ? 'Edit Teacher' : 'Add New Teacher',
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
                      controller: _subjectController,
                      decoration: InputDecoration(
                        labelText: 'Subject',
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
                          return 'Please enter a subject';
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
                          child: Text('Cancel'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade500,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _saveTeacher,
                          child: Text(_isEditing ? 'Update' : 'Save'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
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

  void _saveTeacher() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context);

      final name = _nameController.text;
      final subject = _subjectController.text;
      final phoneNumber = _phoneNumberController.text;

      setState(() {
        if (_isEditing) {
          // Update existing teacher
          final updatedTeacher = {
            'id': _currentTeacherId!,
            'name': name,
            'subject': subject,
            'phoneNumber': phoneNumber,
            // Keep isPresent value if exists, otherwise set default value
            'isPresent':
                teachers.firstWhere(
                  (t) => t['id'] == _currentTeacherId,
                )['isPresent'] ??
                true,
          };

          _dataService.updateTeacher(_currentTeacherId!, updatedTeacher);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Teacher updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Add new teacher
          final newId =
              (int.parse(teachers.isNotEmpty ? teachers.last['id'] : '0') + 1)
                  .toString();
          final newTeacher = {
            'id': newId,
            'name': name,
            'subject': subject,
            'phoneNumber': phoneNumber,
            'isPresent': true, // Default new teachers to present
          };

          _dataService.addTeacher(newTeacher);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Teacher added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
        // Refresh teachers list from data service
        teachers = _dataService.teachers;
      });

      _resetForm();
    }
  }

  void _deleteTeacher(String id) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Delete Teacher'),
            content: Text('Are you sure you want to delete this teacher?'),
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
                    _dataService.deleteTeacher(id);
                    // Refresh teachers list from data service
                    teachers = _dataService.teachers;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Teacher deleted successfully'),
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
        title: Text('Manage Teachers'),
        backgroundColor: Colors.green,
      ),
      body:
          teachers.isEmpty
              ? Center(
                child: Text(
                  'No teachers found.\nAdd a teacher using the button below.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              )
              : ListView.builder(
                itemCount: teachers.length,
                itemBuilder: (context, index) {
                  final teacher = teachers[index];
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 3,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green.shade200,
                        child: Text(
                          teacher['name'][0],
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        teacher['name'],
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Subject: ${teacher['subject']}',
                            style: TextStyle(color: Colors.black87),
                          ),
                          Text(
                            'Phone: ${teacher['phoneNumber']}',
                            style: TextStyle(color: Colors.black87),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue.shade700),
                            onPressed: () => _showForm(teacher: teacher),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete,
                              color: Colors.red.shade700,
                            ),
                            onPressed: () => _deleteTeacher(teacher['id']),
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
