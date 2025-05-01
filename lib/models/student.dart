class Student {
  final String id;
  final String name;
  final String? classGrade; // Optional - only for class students
  final String? courseName; // Optional - only for course students
  final String? batchNumber; // Optional - only for course students
  final String rollNumber;
  final String phoneNumber;
  final bool isPresent;
  final bool isClassStudent; // To determine if student is in class or course
  final DateTime createdAt;
  final DateTime updatedAt;

  Student({
    required this.id,
    required this.name,
    required this.rollNumber,
    required this.phoneNumber,
    this.classGrade,
    this.courseName,
    this.batchNumber,
    this.isPresent = true,
    required this.isClassStudent,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor to create a Student from a map
  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      classGrade: map['classGrade'],
      courseName: map['courseName'],
      batchNumber: map['batchNumber'],
      rollNumber: map['rollNumber']?.toString() ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      isPresent: map['isPresent'] ?? true,
      isClassStudent: map['isClassStudent'] ?? true,
      createdAt: DateTime.parse(map['createdAt'] ?? ''),
      updatedAt: DateTime.parse(map['updatedAt'] ?? ''),
    );
  }

  // Method to convert Student to a map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'classGrade': classGrade,
      'courseName': courseName,
      'batchNumber': batchNumber,
      'rollNumber': rollNumber,
      'phoneNumber': phoneNumber,
      'isPresent': isPresent,
      'isClassStudent': isClassStudent,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as String,
      name: json['name'] as String,
      classGrade: json['class_grade'] as String?,
      rollNumber: json['roll_number'] as String,
      phoneNumber: json['phone_number'] as String,
      courseName: json['course_name'] as String?,
      batchNumber: json['batch_number'] as String?,
      isClassStudent: json['is_class_student'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'class_grade': classGrade,
      'roll_number': rollNumber,
      'phone_number': phoneNumber,
      'course_name': courseName,
      'batch_number': batchNumber,
      'is_class_student': isClassStudent,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
