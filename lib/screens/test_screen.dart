import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/student.dart';
import '../models/teacher.dart';
import '../models/attendance.dart';
import '../models/fee.dart' as fee_model;
import '../models/salary.dart' as salary_model;

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final DatabaseService _dbService = DatabaseService();
  String _testResult = '';
  bool _isLoading = false;

  Future<void> _runAllTests() async {
    setState(() {
      _isLoading = true;
      _testResult = 'Running all tests...\n';
    });

    try {
      // Test Student Management
      _testResult += '\nTesting Student Management...\n';
      final student = Student(
        id: 'test-student-1',
        name: 'Test Student',
        fatherName: 'Test Father',
        studentType: StudentType.classStudent,
        classGrade: '10th',
        rollNumber: 101,
        phoneNumber: '+1234567890',
        admissionDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _dbService.addStudent(student);
      _testResult += '✓ Student added successfully\n';

      // Test Teacher Management
      _testResult += '\nTesting Teacher Management...\n';
      final teacher = Teacher(
        id: 'test-teacher-1',
        name: 'Test Teacher',
        subject: 'Mathematics',
        phoneNumber: '+1234567890',
        baseSalary: 5000.0,
        joiningDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _dbService.addTeacher(teacher);
      _testResult += '✓ Teacher added successfully\n';

      // Test Attendance
      _testResult += '\nTesting Attendance...\n';
      final studentAttendance = Attendance(
        id: 'test-attendance-1',
        userId: student.id,
        type: AttendanceType.student,
        date: DateTime.now(),
        status: AttendanceStatus.present,
        classGrade: '10th',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _dbService.markAttendance(studentAttendance);
      _testResult += '✓ Student attendance marked\n';

      final teacherAttendance = Attendance(
        id: 'test-attendance-2',
        userId: teacher.id,
        type: AttendanceType.teacher,
        date: DateTime.now(),
        status: AttendanceStatus.present,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _dbService.markAttendance(teacherAttendance);
      _testResult += '✓ Teacher attendance marked\n';

      // Test Fees
      _testResult += '\nTesting Fees...\n';
      final fee = fee_model.Fee(
        id: 'test-fee-1',
        studentId: student.id,
        amount: 1000.0,
        month: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 30)),
        status: fee_model.PaymentStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _dbService.addFee(fee);
      _testResult += '✓ Fee added successfully\n';

      // Test Salaries
      _testResult += '\nTesting Salaries...\n';
      final salary = salary_model.Salary(
        id: 'test-salary-1',
        teacherId: teacher.id,
        amount: 5000.0,
        month: DateTime.now(),
        status: salary_model.PaymentStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _dbService.addSalary(salary);
      _testResult += '✓ Salary added successfully\n';

      // Test Reports
      _testResult += '\nTesting Reports...\n';
      final monthlyReport = await _dbService.getMonthlyReport(
        DateTime.now().month.toString(),
        DateTime.now().year.toString(),
      );
      _testResult += '✓ Monthly Report generated:\n';
      _testResult +=
          '  - Student Attendance: ${monthlyReport['student_attendance'].length} records\n';
      _testResult +=
          '  - Teacher Attendance: ${monthlyReport['teacher_attendance'].length} records\n';
      _testResult +=
          '  - Fee Records: ${monthlyReport['fee_records'].length} records\n';
      _testResult +=
          '  - Salary Records: ${monthlyReport['salary_records'].length} records\n';

      // Test History
      _testResult += '\nTesting History...\n';
      final studentHistory = await _dbService.getStudentHistory(student.id);
      _testResult += '✓ Student History retrieved:\n';
      _testResult +=
          '  - Attendance Records: ${studentHistory['attendance'].length}\n';
      _testResult += '  - Fee Records: ${studentHistory['fees'].length}\n';

      final teacherHistory = await _dbService.getTeacherHistory(teacher.id);
      _testResult += '✓ Teacher History retrieved:\n';
      _testResult +=
          '  - Attendance Records: ${teacherHistory['attendance'].length}\n';
      _testResult +=
          '  - Salary Records: ${teacherHistory['salaries'].length}\n';

      _testResult += '\n✓ All tests completed successfully!';
    } catch (e) {
      _testResult += '\n❌ Error during testing: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Testing'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _runAllTests,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Run All Tests'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _testResult,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
