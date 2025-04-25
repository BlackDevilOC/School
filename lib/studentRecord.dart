import 'package:flutter/material.dart';

class StudentRecordScreen extends StatelessWidget {
  final List<String> options = [
    'Attendance',
    'Fees Structure',
    'Student Registration',
    'Time Table',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Student Record'),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: options.length,
            separatorBuilder: (context, index) => SizedBox(height: 20),
            itemBuilder: (context, index) {
              return CustomBox(
                label: options[index],
                icon: Icons.arrow_forward_ios,
                onTap: () {
                  if (options[index] == 'Attendance') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AttendanceScreen(),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${options[index]} tapped')),
                    );
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class CustomBox extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const CustomBox({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Icon(icon, color: Colors.green),
            ],
          ),
        ),
      ),
    );
  }
}

class AttendanceScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Attendance'), backgroundColor: Colors.green),
      body: Center(
        child: Text(
          'Attendance Page Content Here',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
