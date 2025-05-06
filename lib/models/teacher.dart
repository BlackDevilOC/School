class Teacher {
  final String id;
  final String name;
  final String subject;
  final String? qualification;
  final String phoneNumber;
  final double salary;
  final DateTime createdAt;
  final DateTime updatedAt;

  Teacher({
    required this.id,
    required this.name,
    required this.subject,
    this.qualification,
    required this.phoneNumber,
    required this.salary,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor to create a Teacher from a map
  factory Teacher.fromMap(Map<String, dynamic> map) {
    return Teacher(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      subject: map['subject'] ?? '',
      qualification: map['qualification'],
      phoneNumber: map['phone_number'] ?? '',
      salary: map['salary'] != null ? double.parse(map['salary'].toString()) : 0.0,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : DateTime.now(),
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at']) 
          : DateTime.now(),
    );
  }

  // Method to convert Teacher to a map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'subject': subject,
      'qualification': qualification,
      'phone_number': phoneNumber,
      'salary': salary,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
