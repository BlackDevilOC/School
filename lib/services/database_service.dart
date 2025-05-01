import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/student.dart';
import '../models/attendance.dart';

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
    final response =
        await _supabase
            .from('attendance')
            .update(attendance.toJson())
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
}
