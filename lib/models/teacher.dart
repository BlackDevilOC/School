class Teacher {
  final String id;
  final String name;
  final String subject;
  final String qualification;
  final String phoneNumber;
  final double salary;
  final DateTime createdAt;
  final DateTime updatedAt;

  Teacher({
    required this.id,
    required this.name,
    required this.subject,
    required this.qualification,
    required this.phoneNumber,
    required this.salary,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor to create a Teacher from JSON
  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      subject: json['subject'] ?? '',
      qualification: json['qualification'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      salary: (json['salary'] is num) ? (json['salary'] as num).toDouble() : 0.0,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
    );
  }

  // Method to convert Teacher to JSON for database
  Map<String, dynamic> toJson() {
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
