class Student {
  final String id;
  final String name;
  final String classGrade;
  final int rollNumber;
  final String phoneNumber;
  final bool isPresent;

  Student({
    required this.id,
    required this.name,
    required this.classGrade,
    required this.rollNumber,
    required this.phoneNumber,
    this.isPresent = true,
  });

  // Factory constructor to create a Student from a map
  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      classGrade: map['classGrade'] ?? '',
      rollNumber: map['rollNumber'] ?? 0,
      phoneNumber: map['phoneNumber'] ?? '',
      isPresent: map['isPresent'] ?? true,
    );
  }

  // Method to convert Student to a map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'classGrade': classGrade,
      'rollNumber': rollNumber,
      'phoneNumber': phoneNumber,
      'isPresent': isPresent,
    };
  }
}
