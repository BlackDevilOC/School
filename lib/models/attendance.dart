import 'base_model.dart';

enum AttendanceStatus { present, absent, late, excused }

enum AttendanceType { student, teacher }

class Attendance extends BaseModel {
  final String userId; // Can be either student or teacher ID
  final AttendanceType type;
  final DateTime date;
  final AttendanceStatus status;
  final String? remarks;
  final String? classGrade; // For students
  final String? courseName; // For course students
  final String? batchNumber; // For course students

  Attendance({
    required super.id,
    required this.userId,
    required this.type,
    required this.date,
    required this.status,
    this.remarks,
    this.classGrade,
    this.courseName,
    this.batchNumber,
    required super.createdAt,
    required super.updatedAt,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'],
      userId: json['user_id'],
      type: AttendanceType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => AttendanceType.student,
      ),
      date: BaseModel.parseDateTime(json['date']) ?? DateTime.now(),
      status: AttendanceStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => AttendanceStatus.absent,
      ),
      remarks: json['remarks'],
      classGrade: json['class_grade'],
      courseName: json['course_name'],
      batchNumber: json['batch_number'],
      createdAt: BaseModel.parseDateTime(json['created_at']) ?? DateTime.now(),
      updatedAt: BaseModel.parseDateTime(json['updated_at']) ?? DateTime.now(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.toString().split('.').last,
      'date': date.toIso8601String(),
      'status': status.toString().split('.').last,
      'remarks': remarks,
      'class_grade': classGrade,
      'course_name': courseName,
      'batch_number': batchNumber,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Attendance copyWith({
    String? userId,
    AttendanceType? type,
    DateTime? date,
    AttendanceStatus? status,
    String? remarks,
    String? classGrade,
    String? courseName,
    String? batchNumber,
  }) {
    return Attendance(
      id: id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      date: date ?? this.date,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
      classGrade: classGrade ?? this.classGrade,
      courseName: courseName ?? this.courseName,
      batchNumber: batchNumber ?? this.batchNumber,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
