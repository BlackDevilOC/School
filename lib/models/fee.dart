class Fee {
  final String id;
  final String studentName;
  final String? classGrade; // Optional - only for class students
  final String? courseName; // Optional - only for course students
  final String? batchNumber; // Optional - only for course students
  final double amount;
  final DateTime dueDate;
  final bool isPaid;
  final bool isClassStudent; // To determine if student is in class or course

  Fee({
    required this.id,
    required this.studentName,
    this.classGrade,
    this.courseName,
    this.batchNumber,
    required this.amount,
    required this.dueDate,
    this.isPaid = false,
    required this.isClassStudent,
  });

  // Factory constructor to create a Fee from a map
  factory Fee.fromMap(Map<String, dynamic> map) {
    return Fee(
      id: map['id'] ?? '',
      studentName: map['studentName'] ?? '',
      classGrade: map['classGrade'],
      courseName: map['courseName'],
      batchNumber: map['batchNumber'],
      amount: (map['amount'] ?? 0.0).toDouble(),
      dueDate: map['dueDate'] != null
          ? DateTime.parse(map['dueDate'])
          : DateTime.now(),
      isPaid: map['isPaid'] ?? false,
      isClassStudent: map['isClassStudent'] ?? true,
    );
  }

  // Method to convert Fee to a map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentName': studentName,
      'classGrade': classGrade,
      'courseName': courseName,
      'batchNumber': batchNumber,
      'amount': amount,
      'dueDate': dueDate.toIso8601String(),
      'isPaid': isPaid,
      'isClassStudent': isClassStudent,
    };
  }
}
