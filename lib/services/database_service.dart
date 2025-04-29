import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/student.dart';
import '../models/teacher.dart';
import '../models/attendance.dart';
import '../models/fee.dart';
import '../models/salary.dart';

class DatabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // Teachers CRUD
  Future<List<Teacher>> getAllTeachers() async {
    try {
      final response = await _client.from('teachers').select().order('name');
      return (response as List).map((json) => Teacher.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching teachers: $e');
      return [];
    }
  }

  Future<Teacher?> getTeacher(String id) async {
    try {
      final response =
          await _client.from('teachers').select().eq('id', id).single();
      return Teacher.fromJson(response);
    } catch (e) {
      print('Error fetching teacher: $e');
      return null;
    }
  }

  Future<bool> addTeacher(Teacher teacher) async {
    try {
      await _client.from('teachers').insert(teacher.toJson());
      return true;
    } catch (e) {
      print('Error adding teacher: $e');
      return false;
    }
  }

  Future<bool> updateTeacher(Teacher teacher) async {
    try {
      await _client
          .from('teachers')
          .update(teacher.toJson())
          .eq('id', teacher.id);
      return true;
    } catch (e) {
      print('Error updating teacher: $e');
      return false;
    }
  }

  Future<bool> deleteTeacher(String id) async {
    try {
      await _client.from('teachers').delete().eq('id', id);
      return true;
    } catch (e) {
      print('Error deleting teacher: $e');
      return false;
    }
  }

  // Students CRUD
  Future<List<Student>> getAllStudents() async {
    try {
      final response = await _client.from('students').select().order('name');
      return (response as List).map((json) => Student.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching students: $e');
      return [];
    }
  }

  Future<Student?> getStudent(String id) async {
    try {
      final response =
          await _client.from('students').select().eq('id', id).single();
      return Student.fromJson(response);
    } catch (e) {
      print('Error fetching student: $e');
      return null;
    }
  }

  Future<bool> addStudent(Student student) async {
    try {
      await _client.from('students').insert(student.toJson());
      return true;
    } catch (e) {
      print('Error adding student: $e');
      return false;
    }
  }

  Future<bool> updateStudent(Student student) async {
    try {
      await _client
          .from('students')
          .update(student.toJson())
          .eq('id', student.id);
      return true;
    } catch (e) {
      print('Error updating student: $e');
      return false;
    }
  }

  Future<bool> deleteStudent(String id) async {
    try {
      await _client.from('students').delete().eq('id', id);
      return true;
    } catch (e) {
      print('Error deleting student: $e');
      return false;
    }
  }

  // Attendance CRUD
  Future<List<Attendance>> getAttendance({
    required DateTime date,
    AttendanceType? type,
    String? userId,
    bool isTeacher = false,
  }) async {
    try {
      var query = _client
          .from('attendance')
          .select()
          .eq('date', date.toIso8601String());

      if (type != null) {
        query = query.eq('type', type.toString().split('.').last);
      }

      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      if (isTeacher) {
        query = query.eq('is_teacher', true);
      } else {
        query = query.eq('is_teacher', false);
      }

      final response = await query;
      return (response as List)
          .map((json) => Attendance.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching attendance: $e');
      return [];
    }
  }

  Future<bool> markAttendance(Attendance attendance) async {
    try {
      // Check if attendance already exists for this user on this date
      final existing = await _client
          .from('attendance')
          .select()
          .eq('user_id', attendance.userId)
          .eq('date', attendance.date.toIso8601String())
          .maybeSingle();

      if (existing != null) {
        // Update existing attendance
        await _client
            .from('attendance')
            .update(attendance.toJson())
            .eq('id', existing['id']);
      } else {
        // Add new attendance
        await _client.from('attendance').insert(attendance.toJson());
      }
      return true;
    } catch (e) {
      print('Error marking attendance: $e');
      return false;
    }
  }

  // Fees CRUD
  Future<List<Fee>> getStudentFees(String studentId) async {
    try {
      final response = await _client
          .from('student_fees')
          .select()
          .eq('student_id', studentId)
          .order('month');
      return (response as List).map((json) => Fee.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching student fees: $e');
      return [];
    }
  }

  Future<bool> addFee(Fee fee) async {
    try {
      await _client.from('student_fees').insert(fee.toJson());
      return true;
    } catch (e) {
      print('Error adding fee: $e');
      return false;
    }
  }

  Future<bool> updateFeeStatus(String feeId, PaymentStatus status) async {
    try {
      await _client.from('student_fees').update(
          {'status': status.toString().split('.').last}).eq('id', feeId);
      return true;
    } catch (e) {
      print('Error updating fee status: $e');
      return false;
    }
  }

  // Salary Management
  Future<List<Salary>> getTeacherSalaries(String teacherId) async {
    try {
      final response = await _client
          .from('teacher_salaries')
          .select()
          .eq('teacher_id', teacherId)
          .order('month');
      return (response as List).map((json) => Salary.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching teacher salaries: $e');
      return [];
    }
  }

  Future<bool> addSalary(Salary salary) async {
    try {
      await _client.from('teacher_salaries').insert(salary.toJson());
      return true;
    } catch (e) {
      print('Error adding salary: $e');
      return false;
    }
  }

  Future<bool> updateSalaryStatus(String salaryId, PaymentStatus status) async {
    try {
      await _client.from('teacher_salaries').update(
          {'status': status.toString().split('.').last}).eq('id', salaryId);
      return true;
    } catch (e) {
      print('Error updating salary status: $e');
      return false;
    }
  }

  // Reports and Analytics
  Future<Map<String, dynamic>> getMonthlyReport(
      String month, String year) async {
    try {
      // Get student attendance
      final studentAttendance = await _client
          .from('attendance')
          .select()
          .eq('is_teacher', false)
          .gte('date', '$year-$month-01')
          .lte('date', '$year-$month-31');

      // Get teacher attendance
      final teacherAttendance = await _client
          .from('attendance')
          .select()
          .eq('is_teacher', true)
          .gte('date', '$year-$month-01')
          .lte('date', '$year-$month-31');

      // Get fee records
      final feeRecords = await _client
          .from('student_fees')
          .select()
          .eq('month', '$year-$month-01');

      // Get salary records
      final salaryRecords = await _client
          .from('teacher_salaries')
          .select()
          .eq('month', '$year-$month-01');

      return {
        'student_attendance': studentAttendance,
        'teacher_attendance': teacherAttendance,
        'fee_records': feeRecords,
        'salary_records': salaryRecords,
      };
    } catch (e) {
      print('Error generating monthly report: $e');
      return {};
    }
  }

  // Historical Data
  Future<Map<String, dynamic>> getStudentHistory(String studentId) async {
    try {
      final attendance = await _client
          .from('attendance')
          .select()
          .eq('user_id', studentId)
          .order('date');

      final fees = await _client
          .from('student_fees')
          .select()
          .eq('student_id', studentId)
          .order('month');

      return {
        'attendance': attendance,
        'fees': fees,
      };
    } catch (e) {
      print('Error fetching student history: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> getTeacherHistory(String teacherId) async {
    try {
      final attendance = await _client
          .from('attendance')
          .select()
          .eq('user_id', teacherId)
          .order('date');

      final salaries = await _client
          .from('teacher_salaries')
          .select()
          .eq('teacher_id', teacherId)
          .order('month');

      return {
        'attendance': attendance,
        'salaries': salaries,
      };
    } catch (e) {
      print('Error fetching teacher history: $e');
      return {};
    }
  }
}
