import 'package:flutter/material.dart';
import 'routes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Screen'),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomBox(
                label: 'Student Record',
                icon: Icons.school,
                onTap: () {
                  Navigator.pushNamed(context, Routes.studentRecord);
                },
              ),
              const SizedBox(height: 20),
              CustomBox(
                label: 'Teacher Record',
                icon: Icons.person,
                onTap: () {
                  Navigator.pushNamed(context, Routes.teacherRecord);
                },
              ),
            ],
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
    super.key,
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
        elevation: 4,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
          child: Column(
            children: [
              Icon(icon, size: 40, color: Colors.green),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
