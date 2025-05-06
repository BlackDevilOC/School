import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/student.dart';
import '../models/attendance.dart';
import '../models/fee.dart';
import '../models/teacher.dart';
import '../models/teacher_attendance.dart';
import '../models/teacher_salary.dart';

class DatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Student operations
  Future<List<Student>> getStudents() async {
    final response = await _supabase
        .from('students')
        .select()
        .order('created_at', ascending: false);

    return (response as List).map((json) => Student.fromJson(json)).toList();
  }

  Future<Student> addStudent(Student student) async {
    try {
      // Insert the student
      final response = await _supabase
          .from('students')
          .insert(student.toJson())
          .select()
          .single();
      
      final newStudent = Student.fromJson(response);
      
      // Create a fee entry for the current month
      await _addCurrentMonthFee(newStudent);
      
      return newStudent;
    } catch (e) {
      print('Error adding student: $e');
      rethrow;
    }
  }

  Future<Student> updateStudent(Student student) async {
    try {
      // Update the student
      final response = await _supabase
          .from('students')
          .update(student.toJson())
          .eq('id', student.id)
          .select()
          .single();
      
      final updatedStudent = Student.fromJson(response);
      
      // Update the fee entry for the current month
      await _updateCurrentMonthFee(updatedStudent);
      
      return updatedStudent;
    } catch (e) {
      print('Error updating student: $e');
      rethrow;
    }
  }

  Future<void> deleteStudent(String id) async {
    await _supabase.from('students').delete().eq('id', id);
  }

  // Attendance operations
  Future<List<Attendance>> getAttendanceForDate(DateTime date) async {
    final response = await _supabase
        .from('attendance')
        .select()
        .eq('attendance_date', date.toIso8601String().split('T')[0])
        .order('created_at', ascending: false);

    return (response as List).map((json) => Attendance.fromJson(json)).toList();
  }

  Future<Attendance> addAttendance(Attendance attendance) async {
    final response =
        await _supabase
            .from('attendance')
            .insert(attendance.toJson())
            .select()
            .single();

    return Attendance.fromJson(response);
  }

  Future<Attendance> updateAttendance(Attendance attendance) async {
    // Create a map without month and year fields for update
    final Map<String, dynamic> updateData = {
      'student_id': attendance.studentId,
      'attendance_date': attendance.attendanceDate.toIso8601String().split('T')[0],
      'status': attendance.status,
      'updated_at': DateTime.now().toIso8601String(),
    };

    final response =
        await _supabase
            .from('attendance')
            .update(updateData)
            .eq('id', attendance.id)
            .select()
            .single();

    return Attendance.fromJson(response);
  }

  Future<void> deleteAttendance(String id) async {
    await _supabase.from('attendance').delete().eq('id', id);
  }

  Future<List<Attendance>> getStudentAttendance(String studentId) async {
    final response = await _supabase
        .from('attendance')
        .select()
        .eq('student_id', studentId)
        .order('attendance_date', ascending: false);

    return (response as List).map((json) => Attendance.fromJson(json)).toList();
  }

  // Fee operations
  Future<List<Fee>> getCurrentMonthFees() async {
    try {
      final response = await _supabase
          .from('current_month_fees')
          .select()
          .order('due_date', ascending: true);

      final fees = (response as List).map((json) => Fee.fromJson(json)).toList();
      
      // Fetch student details to populate the studentName, classGrade, and courseName fields
      final studentIds = fees.map((fee) => fee.studentId).toSet().toList();
      
      if (studentIds.isNotEmpty) {
        final studentsResponse = await _supabase
            .from('students')
            .select();
        
        // Filter students manually if inFilter doesn't work
        final students = (studentsResponse as List)
            .where((student) => studentIds.contains(student['id']))
            .map((json) => Student.fromJson(json))
            .toList();
        
        // Create a map for quick lookup
        final studentMap = {for (var student in students) student.id: student};
        
        // Create a new list with updated fee objects
        final updatedFees = fees.map((fee) {
          final student = studentMap[fee.studentId];
          if (student != null) {
            return Fee(
              id: fee.id,
              studentId: fee.studentId,
              studentName: student.name,
              classGrade: student.classGrade,
              courseName: student.courseName,
              amount: fee.amount,
              dueDate: fee.dueDate,
              status: fee.status,
              month: fee.month,
              year: fee.year,
              createdAt: fee.createdAt,
              updatedAt: fee.updatedAt,
            );
          }
          return fee;
        }).toList();
        
        return updatedFees;
      }
      
      return fees;
    } catch (e) {
      print('Error fetching fees: $e');
      rethrow;
    }
  }

  Future<Fee> updateFeeStatus(String feeId, String status) async {
    try {
      final response = await _supabase
          .from('current_month_fees')
          .update({'status': status, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', feeId)
          .select()
          .single();
      
      final updatedFee = Fee.fromJson(response);
      
      // If the fee is marked as paid, move it to fee_history
      if (status == 'Paid') {
        await _moveToFeeHistory(feeId);
      }
      
      return updatedFee;
    } catch (e) {
      print('Error updating fee status: $e');
      rethrow;
    }
  }

  Future<List<Fee>> getStudentFeeHistory(String studentId) async {
    try {
      final response = await _supabase
          .from('fee_history')
          .select()
          .eq('student_id', studentId)
          .order('payment_date', ascending: false);
      
      return (response as List).map((json) => Fee.fromJson(json)).toList();
    } catch (e) {
      print('Error getting student fee history: $e');
      rethrow;
    }
  }

  // Helper method to add a fee entry for the current month
  Future<void> _addCurrentMonthFee(Student student) async {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;
    final dueDate = DateTime(now.year, now.month + 1, 1); // First day of next month
    
    try {
      // Check if a fee entry already exists for this student in the current month
      final existingFee = await _supabase
          .from('current_month_fees')
          .select()
          .eq('student_id', student.id)
          .eq('month', currentMonth)
          .eq('year', currentYear);
      
      if (existingFee.isEmpty) {
        // Create a new fee entry
        await _supabase.from('current_month_fees').insert({
          'student_id': student.id,
          'amount': student.feeAmount,
          'due_date': dueDate.toIso8601String().split('T')[0],
          'status': 'Pending',
          'month': currentMonth.toString(), // Convert to string
          'year': currentYear,
        });
      }
    } catch (e) {
      print('Error adding current month fee: $e');
      // Don't rethrow - we don't want to fail the student creation if fee creation fails
    }
  }

  // Helper method to update a fee entry for the current month
  Future<void> _updateCurrentMonthFee(Student student) async {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;
    
    try {
      // Check if a fee entry exists for this student in the current month
      final existingFee = await _supabase
          .from('current_month_fees')
          .select()
          .eq('student_id', student.id)
          .eq('month', currentMonth)
          .eq('year', currentYear);
      
      if (existingFee.isNotEmpty) {
        // Update the existing fee entry
        await _supabase
            .from('current_month_fees')
            .update({
              'amount': student.feeAmount,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('student_id', student.id)
            .eq('month', currentMonth)
            .eq('year', currentYear);
      } else {
        // Create a new fee entry
        await _addCurrentMonthFee(student);
      }
    } catch (e) {
      print('Error updating current month fee: $e');
    }
  }

  // Move a fee from current_month_fees to fee_history when paid
  Future<void> _moveToFeeHistory(String feeId) async {
    try {
      // Get the fee details
      final feeResponse = await _supabase
          .from('current_month_fees')
          .select()
          .eq('id', feeId)
          .single();
      
      final fee = Fee.fromJson(feeResponse);
      
      // Only move to history if the fee is paid
      if (fee.status == 'Paid') {
        // Add to fee_history
        await _supabase.from('fee_history').insert({
          'student_id': fee.studentId,
          'amount': fee.amount,
          'payment_date': DateTime.now().toIso8601String().split('T')[0],
          'due_date': fee.dueDate.toIso8601String().split('T')[0],
          'status': fee.status,
        });
      }
    } catch (e) {
      print('Error moving fee to history: $e');
    }
  }

  // Create current month fees for all students who don't have one
  Future<void> generateCurrentMonthFees() async {
    try {
      final now = DateTime.now();
      final currentMonth = now.month;
      final currentYear = now.year;
      
      // Get all students
      final studentsResponse = await _supabase
          .from('students')
          .select();
      
      final students = (studentsResponse as List).map((json) => Student.fromJson(json)).toList();
      
      // Get all current month fees
      final feesResponse = await _supabase
          .from('current_month_fees')
          .select()
          .eq('month', currentMonth)
          .eq('year', currentYear);
      
      final existingFees = (feesResponse as List).map((json) => Fee.fromJson(json)).toList();
      
      // Create a set of student IDs who already have a fee entry
      final studentIdsWithFees = existingFees.map((fee) => fee.studentId).toSet();
      
      // Create fee entries for students who don't have one
      for (final student in students) {
        if (!studentIdsWithFees.contains(student.id)) {
          await _addCurrentMonthFee(student);
        }
      }
    } catch (e) {
      print('Error generating current month fees: $e');
      rethrow;
    }
  }

  // Check and update overdue fees
  Future<void> updateOverdueFees() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Get all pending fees with due dates before today
      final response = await _supabase
          .from('current_month_fees')
          .select()
          .eq('status', 'Pending');
      
      final fees = (response as List).map((json) => Fee.fromJson(json)).toList();
      
      // Update status to Overdue for fees with due dates before today
      for (final fee in fees) {
        final dueDate = DateTime(fee.dueDate.year, fee.dueDate.month, fee.dueDate.day);
        if (dueDate.isBefore(today)) {
          await _supabase
              .from('current_month_fees')
              .update({'status': 'Overdue', 'updated_at': DateTime.now().toIso8601String()})
              .eq('id', fee.id);
        }
      }
    } catch (e) {
      print('Error updating overdue fees: $e');
    }
  }

  // Teacher operations
  Future<List<Teacher>> getTeachers() async {
    final response = await _supabase
        .from('teachers')
        .select()
        .order('created_at', ascending: false);

    return (response as List).map((json) => Teacher.fromMap(json)).toList();
  }

  Future<Teacher> addTeacher(Teacher teacher) async {
    try {
      // Insert the teacher
      final response = await _supabase
          .from('teachers')
          .insert(teacher.toMap())
          .select()
          .single();
      
      final newTeacher = Teacher.fromMap(response);
      
      // Create a salary entry for the current month
      await _addCurrentMonthSalary(newTeacher);
      
      return newTeacher;
    } catch (e) {
      print('Error adding teacher: $e');
      rethrow;
    }
  }

  Future<Teacher> updateTeacher(Teacher teacher) async {
    try {
      // Update the teacher
      final response = await _supabase
          .from('teachers')
          .update(teacher.toMap())
          .eq('id', teacher.id)
          .select()
          .single();
      
      final updatedTeacher = Teacher.fromMap(response);
      
      // Update the salary entry for the current month
      await _updateCurrentMonthSalary(updatedTeacher);
      
      return updatedTeacher;
    } catch (e) {
      print('Error updating teacher: $e');
      rethrow;
    }
  }

  Future<void> deleteTeacher(String id) async {
    await _supabase.from('teachers').delete().eq('id', id);
  }

  // Teacher Attendance operations
  Future<List<TeacherAttendance>> getTeacherAttendanceForDate(DateTime date) async {
    final response = await _supabase
        .from('teacher_attendance')
        .select()
        .eq('attendance_date', date.toIso8601String().split('T')[0])
        .order('created_at', ascending: false);

    return (response as List).map((json) => TeacherAttendance.fromJson(json)).toList();
  }

  Future<TeacherAttendance> addTeacherAttendance(TeacherAttendance attendance) async {
    final response =
        await _supabase
            .from('teacher_attendance')
            .insert(attendance.toJson())
            .select()
            .single();

    return TeacherAttendance.fromJson(response);
  }

  Future<TeacherAttendance> updateTeacherAttendance(TeacherAttendance attendance) async {
    // Create a map without month and year fields for update
    final Map<String, dynamic> updateData = {
      'teacher_id': attendance.teacherId,
      'attendance_date': attendance.attendanceDate.toIso8601String().split('T')[0],
      'status': attendance.status,
      'updated_at': DateTime.now().toIso8601String(),
    };

    final response =
        await _supabase
            .from('teacher_attendance')
            .update(updateData)
            .eq('id', attendance.id)
            .select()
            .single();

    return TeacherAttendance.fromJson(response);
  }

  Future<void> deleteTeacherAttendance(String id) async {
    await _supabase.from('teacher_attendance').delete().eq('id', id);
  }

  Future<List<TeacherAttendance>> getTeacherAttendance(String teacherId) async {
    final response = await _supabase
        .from('teacher_attendance')
        .select()
        .eq('teacher_id', teacherId)
        .order('attendance_date', ascending: false);

    return (response as List).map((json) => TeacherAttendance.fromJson(json)).toList();
  }

  // Teacher Salary operations
  Future<List<TeacherSalary>> getCurrentMonthSalaries() async {
    try {
      final response = await _supabase
          .from('current_month_salary')
          .select()
          .order('due_date', ascending: true);

      final salaries = (response as List).map((json) => TeacherSalary.fromJson(json)).toList();
      
      // Fetch teacher details to populate the teacherName and subject fields
      final teacherIds = salaries.map((salary) => salary.teacherId).toSet().toList();
      
      if (teacherIds.isNotEmpty) {
        final teachersResponse = await _supabase
            .from('teachers')
            .select();
        
        // Filter teachers manually
        final teachers = (teachersResponse as List)
            .where((teacher) => teacherIds.contains(teacher['id']))
            .map((json) => Teacher.fromMap(json))
            .toList();
        
        // Create a map for quick lookup
        final teacherMap = {for (var teacher in teachers) teacher.id: teacher};
        
        // Create a new list with updated salary objects
        final updatedSalaries = salaries.map((salary) {
          final teacher = teacherMap[salary.teacherId];
          if (teacher != null) {
            return TeacherSalary(
              id: salary.id,
              teacherId: salary.teacherId,
              teacherName: teacher.name,
              subject: teacher.subject,
              amount: salary.amount,
              dueDate: salary.dueDate,
              paymentDate: salary.paymentDate,
              status: salary.status,
              month: salary.month,
              year: salary.year,
              createdAt: salary.createdAt,
              updatedAt: salary.updatedAt,
            );
          }
          return salary;
        }).toList();
        
        return updatedSalaries;
      }
      
      return salaries;
    } catch (e) {
      print('Error fetching salaries: $e');
      rethrow;
    }
  }

  Future<TeacherSalary> updateSalaryStatus(String salaryId, String status) async {
    try {
      final response = await _supabase
          .from('current_month_salary')
          .update({'status': status, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', salaryId)
          .select()
          .single();
      
      final updatedSalary = TeacherSalary.fromJson(response);
      
      // If the salary is marked as paid, move it to salary_history
      if (status == 'Paid') {
        await _moveToSalaryHistory(salaryId);
      }
      
      return updatedSalary;
    } catch (e) {
      print('Error updating salary status: $e');
      rethrow;
    }
  }

  Future<List<TeacherSalary>> getTeacherSalaryHistory(String teacherId) async {
    try {
      final response = await _supabase
          .from('teacher_salary_history')
          .select()
          .eq('teacher_id', teacherId)
          .order('payment_date', ascending: false);
      
      return (response as List).map((json) => TeacherSalary.fromJson(json)).toList();
    } catch (e) {
      print('Error getting teacher salary history: $e');
      rethrow;
    }
  }

  // Helper method to add a salary entry for the current month
  Future<void> _addCurrentMonthSalary(Teacher teacher) async {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;
    final dueDate = DateTime(now.year, now.month + 1, 1); // First day of next month
    
    try {
      // Check if a salary entry already exists for this teacher in the current month
      final existingSalary = await _supabase
          .from('current_month_salary')
          .select()
          .eq('teacher_id', teacher.id)
          .eq('month', currentMonth)
          .eq('year', currentYear);
      
      if (existingSalary.isEmpty) {
        // Create a new salary entry
        await _supabase.from('current_month_salary').insert({
          'teacher_id': teacher.id,
          'amount': teacher.salary,
          'payment_date': now.toIso8601String().split('T')[0],
          'due_date': dueDate.toIso8601String().split('T')[0],
          'status': 'Pending',
          'month': currentMonth,
          'year': currentYear,
        });
      }
    } catch (e) {
      print('Error adding current month salary: $e');
      // Don't rethrow - we don't want to fail the teacher creation if salary creation fails
    }
  }

  // Helper method to update a salary entry for the current month
  Future<void> _updateCurrentMonthSalary(Teacher teacher) async {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;
    
    try {
      // Check if a salary entry exists for this teacher in the current month
      final existingSalary = await _supabase
          .from('current_month_salary')
          .select()
          .eq('teacher_id', teacher.id)
          .eq('month', currentMonth)
          .eq('year', currentYear);
      
      if (existingSalary.isNotEmpty) {
        // Update the existing salary entry
        await _supabase
            .from('current_month_salary')
            .update({
              'amount': teacher.salary,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('teacher_id', teacher.id)
            .eq('month', currentMonth)
            .eq('year', currentYear);
      } else {
        // Create a new salary entry
        await _addCurrentMonthSalary(teacher);
      }
    } catch (e) {
      print('Error updating current month salary: $e');
    }
  }

  // Move a salary from current_month_salary to teacher_salary_history when paid
  Future<void> _moveToSalaryHistory(String salaryId) async {
    try {
      // Get the salary details
      final salaryResponse = await _supabase
          .from('current_month_salary')
          .select()
          .eq('id', salaryId)
          .single();
      
      final salary = TeacherSalary.fromJson(salaryResponse);
      
      // Only move to history if the salary is paid
      if (salary.status == 'Paid') {
        // Add to teacher_salary_history
        await _supabase.from('teacher_salary_history').insert({
          'teacher_id': salary.teacherId,
          'amount': salary.amount,
          'payment_date': DateTime.now().toIso8601String().split('T')[0],
          'due_date': salary.dueDate.toIso8601String().split('T')[0],
          'status': salary.status,
        });
      }
    } catch (e) {
      print('Error moving salary to history: $e');
    }
  }

  // Create current month salaries for all teachers who don't have one
  Future<void> generateCurrentMonthSalaries() async {
    try {
      final now = DateTime.now();
      final currentMonth = now.month;
      final currentYear = now.year;
      
      // Get all teachers
      final teachersResponse = await _supabase
          .from('teachers')
          .select();
      
      final teachers = (teachersResponse as List).map((json) => Teacher.fromMap(json)).toList();
      
      // Get all current month salaries
      final salariesResponse = await _supabase
          .from('current_month_salary')
          .select()
          .eq('month', currentMonth)
          .eq('year', currentYear);
      
      final existingSalaries = (salariesResponse as List).map((json) => TeacherSalary.fromJson(json)).toList();
      
      // Create a set of teacher IDs who already have a salary entry
      final teacherIdsWithSalaries = existingSalaries.map((salary) => salary.teacherId).toSet();
      
      // Create salary entries for teachers who don't have one
      for (final teacher in teachers) {
        if (!teacherIdsWithSalaries.contains(teacher.id)) {
          await _addCurrentMonthSalary(teacher);
        }
      }
    } catch (e) {
      print('Error generating current month salaries: $e');
      rethrow;
    }
  }

  // Check and update overdue salaries
  Future<void> updateOverdueSalaries() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Get all pending salaries with due dates before today
      final response = await _supabase
          .from('current_month_salary')
          .select()
          .eq('status', 'Pending');
      
      final salaries = (response as List).map((json) => TeacherSalary.fromJson(json)).toList();
      
      // Update status to Overdue for salaries with due dates before today
      for (final salary in salaries) {
        final dueDate = DateTime(salary.dueDate.year, salary.dueDate.month, salary.dueDate.day);
        if (dueDate.isBefore(today)) {
          await _supabase
              .from('current_month_salary')
              .update({'status': 'Overdue', 'updated_at': DateTime.now().toIso8601String()})
              .eq('id', salary.id);
        }
      }
    } catch (e) {
      print('Error updating overdue salaries: $e');
    }
  }
}
