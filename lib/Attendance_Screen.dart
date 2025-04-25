import 'package:flutter/material.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  List<Map<String, dynamic>> students = [
    {'id': '1', 'name': 'Ali', 'class': '10A', 'attendance': null},
    {'id': '2', 'name': 'Sara', 'class': '10B', 'attendance': null},
    {'id': '3', 'name': 'Ahmed', 'class': '10C', 'attendance': null},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mark Attendance")),
      body:
          !students.isNotEmpty
              ? const Center(child: Text("No students available"))
              : ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final student = students[index];
                  final attendance = student['attendance'];

                  Color getColor() {
                    if (attendance == 'Present') return Colors.green;
                    if (attendance == 'Absent') return Colors.red;
                    return Colors.grey;
                  }

                  IconData getIcon() {
                    if (attendance == 'Present') return Icons.check_circle;
                    if (attendance == 'Absent') return Icons.cancel;
                    return Icons.help_outline;
                  }

                  return Card(
                    child: ListTile(
                      title: Text(student['name']),
                      subtitle: Text("Class: ${student['class']}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.check,
                              color:
                                  attendance == 'Present'
                                      ? Colors.green
                                      : Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                students[index]['attendance'] = 'Present';
                              });
                              _showSnackBar(
                                '${student['name']} marked Present',
                              );
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              color:
                                  attendance == 'Absent'
                                      ? Colors.red
                                      : Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                students[index]['attendance'] = 'Absent';
                              });
                              _showSnackBar('${student['name']} marked Absent');
                            },
                          ),
                        ],
                      ),
                      leading: Icon(getIcon(), color: getColor(), size: 30),
                    ),
                  );
                },
              ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
