class Attendance {
  final String id;
  final String studentId;
  final DateTime attendanceDate;
  final String status;
  final int? month;  // Make month optional since it's generated in the database
  final int? year;   // Make year optional since it's generated in the database
  final DateTime createdAt;
  final DateTime updatedAt;

  Attendance({
    required this.id,
    required this.studentId,
    required this.attendanceDate,
    required this.status,
    this.month,  // Optional now
    this.year,   // Optional now
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
    // Create the base map without month and year
    final Map<String, dynamic> json = {
      'id': id,
      'student_id': studentId,
      'attendance_date': attendanceDate.toIso8601String().split('T')[0],
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
    
    // Only include month and year if they're not null and we're updating an existing record
    // This is to handle cases where we might be updating a record and need to include these fields
    if (month != null) {
      json['month'] = month;
    }
    if (year != null) {
      json['year'] = year;
    }
    
    return json;
  }
}
