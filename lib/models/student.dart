import 'base_model.dart';

enum StudentType { classStudent, courseStudent }

class Student extends BaseModel {
  final String name;
  final String fatherName;
  final StudentType studentType;
  final String? classGrade;
  final int rollNumber;
  final String phoneNumber;
  final String? courseName;
  final String? batchNumber;
  final DateTime admissionDate;
  final bool isPresent;

  Student({
    required super.id,
    required this.name,
    required this.fatherName,
    required this.studentType,
    this.classGrade,
    required this.rollNumber,
    required this.phoneNumber,
    this.courseName,
    this.batchNumber,
    required this.admissionDate,
    required super.createdAt,
    required super.updatedAt,
    this.isPresent = true,
  }) : assert(
          (studentType == StudentType.classStudent &&
                  classGrade != null &&
                  courseName == null &&
                  batchNumber == null) ||
              (studentType == StudentType.courseStudent &&
                  classGrade == null &&
                  courseName != null &&
                  batchNumber != null),
          'Student type must match corresponding fields',
        );

  factory Student.fromJson(Map<String, dynamic> json) {
    final studentType = json['student_type'] == 'class'
        ? StudentType.classStudent
        : StudentType.courseStudent;

    return Student(
      id: json['id'],
      name: json['name'],
      fatherName: json['father_name'],
      studentType: studentType,
      classGrade: json['class_grade'],
      rollNumber: json['roll_number'],
      phoneNumber: json['phone_number'],
      courseName: json['course_name'],
      batchNumber: json['batch_number'],
      admissionDate:
          BaseModel.parseDateTime(json['admission_date']) ?? DateTime.now(),
      createdAt: BaseModel.parseDateTime(json['created_at']) ?? DateTime.now(),
      updatedAt: BaseModel.parseDateTime(json['updated_at']) ?? DateTime.now(),
      isPresent: json['is_present'] ?? true,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'father_name': fatherName,
      'student_type':
          studentType == StudentType.classStudent ? 'class' : 'course',
      'class_grade': classGrade,
      'roll_number': rollNumber,
      'phone_number': phoneNumber,
      'course_name': courseName,
      'batch_number': batchNumber,
      'admission_date': admissionDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_present': isPresent,
    };
  }

  Student copyWith({
    String? name,
    String? fatherName,
    StudentType? studentType,
    String? classGrade,
    int? rollNumber,
    String? phoneNumber,
    String? courseName,
    String? batchNumber,
    DateTime? admissionDate,
    bool? isPresent,
  }) {
    return Student(
      id: id,
      name: name ?? this.name,
      fatherName: fatherName ?? this.fatherName,
      studentType: studentType ?? this.studentType,
      classGrade: classGrade ?? this.classGrade,
      rollNumber: rollNumber ?? this.rollNumber,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      courseName: courseName ?? this.courseName,
      batchNumber: batchNumber ?? this.batchNumber,
      admissionDate: admissionDate ?? this.admissionDate,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isPresent: isPresent ?? this.isPresent,
    );
  }
}
