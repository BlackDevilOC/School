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
    final response =
        await _supabase
            .from('students')
            .insert(student.toJson())
            .select()
            .single();

    return Student.fromJson(response);
  }

  Future<Student> updateStudent(Student student) async {
    final response =
        await _supabase
            .from('students')
            .update(student.toJson())
            .eq('id', student.id)
            .select()
            .single();

    return Student.fromJson(response);
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
          .select()
          .inFilter('id', studentIds);
      
      final students = (studentsResponse as List).map((json) => Student.fromJson(json)).toList();
      
      // Create a map for quick lookup
      final studentMap = {for (var student in students) student.id: student};
      
      // Update fee objects with student information
      for (var fee in fees) {
        final student = studentMap[fee.studentId];
        if (student != null) {
          fee = Fee(
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
      }
    }
    
    return fees;
  }

  Future<Fee> updateFeeStatus(String feeId, String status) async {
    final response = await _supabase
        .from('current_month_fees')
        .update({'status': status, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', feeId)
        .select()
        .single();

    return Fee.fromJson(response);
  }

  Future<List<Fee>> getStudentFeeHistory(String studentId) async {
    final response = await _supabase
        .from('fee_history')
        .select()
        .eq('student_id', studentId)
        .order('payment_date', ascending: false);

    return (response as List).map((json) => Fee.fromJson(json)).toList();
  }
}
