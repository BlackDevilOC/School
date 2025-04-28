class Student {
  final String id;
  final String name;
  final String? classGrade; // Optional - only for class students
  final String? courseName; // Optional - only for course students
  final String? batchNumber; // Optional - only for course students
  final int rollNumber;
  final String phoneNumber;
  final bool isPresent;
  final bool isClassStudent; // To determine if student is in class or course

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
  });

  // Factory constructor to create a Student from a map
  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      classGrade: map['classGrade'],
      courseName: map['courseName'],
      batchNumber: map['batchNumber'],
      rollNumber: map['rollNumber'] ?? 0,
      phoneNumber: map['phoneNumber'] ?? '',
      isPresent: map['isPresent'] ?? true,
      isClassStudent: map['isClassStudent'] ?? true,
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
    };
  }
}
