class Teacher {
  final String id;
  final String name;
  final String subject;
  final String phoneNumber;
  final bool isPresent;

  Teacher({
    required this.id,
    required this.name,
    required this.subject,
    required this.phoneNumber,
    this.isPresent = true,
  });

  // Factory constructor to create a Teacher from a map
  factory Teacher.fromMap(Map<String, dynamic> map) {
    return Teacher(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      subject: map['subject'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      isPresent: map['isPresent'] ?? true,
    );
  }

  // Method to convert Teacher to a map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'subject': subject,
      'phoneNumber': phoneNumber,
      'isPresent': isPresent,
    };
  }
}
