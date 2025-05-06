class TeacherAttendance {
  final String id;
  final String teacherId;
  final DateTime attendanceDate;
  final String status;
  final int? month;  // Make month optional since it's generated in the database
  final int? year;   // Make year optional since it's generated in the database
  final DateTime createdAt;
  final DateTime updatedAt;

  TeacherAttendance({
    required this.id,
    required this.teacherId,
    required this.attendanceDate,
    required this.status,
    this.month,  // Optional now
    this.year,   // Optional now
    required this.createdAt,
    required this.updatedAt,
  });

  factory TeacherAttendance.fromJson(Map<String, dynamic> json) {
    return TeacherAttendance(
      id: json['id'] as String,
      teacherId: json['teacher_id'] as String,
      attendanceDate: DateTime.parse(json['attendance_date'] as String),
      status: json['status'] as String,
      month: json['month'] as int,
      year: json['year'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    // Create the base map without month and year
    final Map<String, dynamic> json = {
      'id': id,
      'teacher_id': teacherId,
      'attendance_date': attendanceDate.toIso8601String().split('T')[0],
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
    
    // Only include month and year if they're not null and we're updating an existing record
    if (month != null) {
      json['month'] = month;
    }
    if (year != null) {
      json['year'] = year;
    }
    
    return json;
  }
}
