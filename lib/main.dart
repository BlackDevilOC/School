import 'package:academy_portal/Attendance_Screen.dart';
import 'package:flutter/material.dart';
// import 'package:academy_portal/LoginScreen.dart'; // <-- Add this line

void main() {
  runApp(AcademyApp());
}

class AcademyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Academy Portal',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: AttendancePage(),
      //LoginScreen(), // Or change this to AttendancePage() for direct access
    );
  }
}
