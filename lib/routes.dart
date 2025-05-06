import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/student_record_screen.dart';
import 'screens/teacher_record_screen.dart';
import 'screens/student_attendance_screen.dart';
import 'screens/teacher_attendance_screen.dart';
import 'screens/manage_students_screen.dart';
import 'screens/manage_teachers_screen.dart';
import 'screens/fee_structure_screen.dart';
import 'screens/fee_records_screen.dart';

class Routes {
  static const String login = '/login';
  static const String home = '/home';
  static const String studentRecord = '/student_record';
  static const String teacherRecord = '/teacher_record';
  static const String studentAttendance = '/student_attendance';
  static const String teacherAttendance = '/teacher_attendance';
  static const String manageStudents = '/manage_students';
  static const String manageTeachers = '/manage_teachers';
  static const String feeStructure = '/fee_structure';
  static const String feeRecords = '/fee_records';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      login: (context) => LoginScreen(),
      home: (context) => HomeScreen(),
      studentRecord: (context) => StudentRecordScreen(),
      teacherRecord: (context) => TeacherRecordScreen(),
      studentAttendance: (context) => StudentAttendanceScreen(),
      teacherAttendance: (context) => TeacherAttendanceScreen(),
      manageStudents: (context) => ManageStudentsScreen(),
      manageTeachers: (context) => ManageTeachersScreen(),
      feeStructure: (context) => FeeStructureScreen(),
      feeRecords: (context) => FeeRecordsScreen(),
    };
  }
}
