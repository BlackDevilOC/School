import '../config/supabase_config.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  late final SupabaseClient _client;

  factory SupabaseService() {
    return _instance;
  }

  SupabaseService._internal() {
    _client = SupabaseClient(
      SupabaseConfig.supabaseUrl,
      SupabaseConfig.supabaseAnonKey,
    );
  }

  // Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
  }

  // Teachers
  Future<List<Map<String, dynamic>>> getAllTeachers() async {
    final response = await _client.from('teachers').select().order('name');
    return (response as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getTeacher(String id) async {
    final response =
        await _client.from('teachers').select().eq('id', id).single();
    return response as Map<String, dynamic>;
  }

  Future<void> addTeacher(Map<String, dynamic> teacher) async {
    await _client.from('teachers').insert(teacher);
  }

  Future<void> updateTeacher(String id, Map<String, dynamic> teacher) async {
    await _client.from('teachers').update(teacher).eq('id', id);
  }

  Future<void> deleteTeacher(String id) async {
    await _client.from('teachers').delete().eq('id', id);
  }

  // Teacher Attendance
  Future<void> markTeacherAttendance(Map<String, dynamic> attendance) async {
    await _client.from('teacher_attendance').insert(attendance);
  }

  Future<List<Map<String, dynamic>>> getTeacherAttendance(
    String teacherId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final response = await _client
        .from('teacher_attendance')
        .select()
        .eq('teacher_id', teacherId)
        .gte('date', startDate.toIso8601String())
        .lte('date', endDate.toIso8601String())
        .order('date');
    return (response as List).cast<Map<String, dynamic>>();
  }

  // Students
  Future<List<Map<String, dynamic>>> getAllStudents() async {
    final response = await _client.from('students').select().order('name');
    return (response as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getStudent(String id) async {
    final response =
        await _client.from('students').select().eq('id', id).single();
    return response as Map<String, dynamic>;
  }

  Future<void> addStudent(Map<String, dynamic> student) async {
    await _client.from('students').insert(student);
  }

  Future<void> updateStudent(String id, Map<String, dynamic> student) async {
    await _client.from('students').update(student).eq('id', id);
  }

  Future<void> deleteStudent(String id) async {
    await _client.from('students').delete().eq('id', id);
  }

  // Student Attendance
  Future<void> markStudentAttendance(Map<String, dynamic> attendance) async {
    await _client.from('student_attendance').insert(attendance);
  }

  Future<List<Map<String, dynamic>>> getStudentAttendance(
    String studentId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final response = await _client
        .from('student_attendance')
        .select()
        .eq('student_id', studentId)
        .gte('date', startDate.toIso8601String())
        .lte('date', endDate.toIso8601String())
        .order('date');
    return (response as List).cast<Map<String, dynamic>>();
  }

  // Fee Structure
  Future<List<Map<String, dynamic>>> getFeeStructure() async {
    final response = await _client
        .from('fee_structure')
        .select()
        .is_('valid_until', null)
        .order('valid_from');
    return (response as List).cast<Map<String, dynamic>>();
  }

  Future<void> addFeeStructure(Map<String, dynamic> feeStructure) async {
    await _client.from('fee_structure').insert(feeStructure);
  }

  // Student Fees
  Future<List<Map<String, dynamic>>> getStudentFees(
    String studentId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _client
        .from('student_fees')
        .select('*, fee_structure(*)')
        .eq('student_id', studentId);

    if (startDate != null) {
      query = query.gte('month', startDate.toIso8601String());
    }
    if (endDate != null) {
      query = query.lte('month', endDate.toIso8601String());
    }

    final response = await query.order('month');
    return (response as List).cast<Map<String, dynamic>>();
  }

  Future<void> addStudentFee(Map<String, dynamic> fee) async {
    await _client.from('student_fees').insert(fee);
  }

  Future<void> updateFeeStatus(String feeId, String status) async {
    await _client
        .from('student_fees')
        .update({'status': status}).eq('id', feeId);
  }

  // Fee Payments
  Future<void> recordFeePayment(Map<String, dynamic> payment) async {
    await _client.from('fee_payments').insert(payment);
  }

  Future<List<Map<String, dynamic>>> getFeePayments(String feeId) async {
    final response = await _client
        .from('fee_payments')
        .select()
        .eq('student_fee_id', feeId)
        .order('payment_date');
    return (response as List).cast<Map<String, dynamic>>();
  }

  // Teacher Salary
  Future<List<Map<String, dynamic>>> getTeacherSalaries(
    String teacherId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query =
        _client.from('teacher_salary').select().eq('teacher_id', teacherId);

    if (startDate != null) {
      query = query.gte('month', startDate.toIso8601String());
    }
    if (endDate != null) {
      query = query.lte('month', endDate.toIso8601String());
    }

    final response = await query.order('month');
    return (response as List).cast<Map<String, dynamic>>();
  }

  Future<void> addTeacherSalary(Map<String, dynamic> salary) async {
    await _client.from('teacher_salary').insert(salary);
  }

  Future<void> updateSalaryStatus(String salaryId, String status) async {
    await _client
        .from('teacher_salary')
        .update({'status': status}).eq('id', salaryId);
  }

  // Salary Payments
  Future<void> recordSalaryPayment(Map<String, dynamic> payment) async {
    await _client.from('salary_payments').insert(payment);
  }

  Future<List<Map<String, dynamic>>> getSalaryPayments(String salaryId) async {
    final response = await _client
        .from('salary_payments')
        .select()
        .eq('teacher_salary_id', salaryId)
        .order('payment_date');
    return (response as List).cast<Map<String, dynamic>>();
  }

  // Reports
  Future<List<Map<String, dynamic>>> getMonthlyAttendanceReport(
    DateTime month,
    bool isTeacher,
  ) async {
    final table = isTeacher ? 'teacher_attendance' : 'student_attendance';
    final idField = isTeacher ? 'teacher_id' : 'student_id';
    final joinTable = isTeacher ? 'teachers' : 'students';

    final startDate = DateTime(month.year, month.month, 1);
    final endDate = DateTime(month.year, month.month + 1, 0);

    final response = await _client
        .from(table)
        .select('*, $joinTable(*)')
        .gte('date', startDate.toIso8601String())
        .lte('date', endDate.toIso8601String())
        .order('$idField, date');

    return (response as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getMonthlyFeesReport(
      DateTime month) async {
    final response = await _client
        .from('student_fees')
        .select('*, students(*)')
        .eq('month', DateTime(month.year, month.month, 1).toIso8601String())
        .order('due_date');

    return (response as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getMonthlySalaryReport(
      DateTime month) async {
    final response = await _client
        .from('teacher_salary')
        .select('*, teachers(*)')
        .eq('month', DateTime(month.year, month.month, 1).toIso8601String())
        .order('net_amount');

    return (response as List).cast<Map<String, dynamic>>();
  }
}
