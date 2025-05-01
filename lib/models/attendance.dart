class Attendance {
  final String id;
  final String studentId;
  final DateTime attendanceDate;
  final String status;
  final int month;
  final int year;
  final DateTime createdAt;
  final DateTime updatedAt;

  Attendance({
    required this.id,
    required this.studentId,
    required this.attendanceDate,
    required this.status,
    required this.month,
    required this.year,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      attendanceDate: DateTime.parse(json['attendance_date'] as String),
      status: json['status'] as String,
      month: json['month'] as int,
      year: json['year'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'attendance_date': attendanceDate.toIso8601String().split('T')[0],
      'status': status,
      'month': month,
      'year': year,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
