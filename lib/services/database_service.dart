import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/student.dart';
import '../models/attendance.dart';
import '../models/fee.dart';

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
}
