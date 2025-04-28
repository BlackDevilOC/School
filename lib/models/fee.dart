class Fee {
  final String id;
  final String studentName;
  final String courseName;
  final double amount;
  final DateTime dueDate;
  final bool isPaid;

  Fee({
    required this.id,
    required this.studentName,
    required this.courseName,
    required this.amount,
    required this.dueDate,
    this.isPaid = false,
  });

  // Factory constructor to create a Fee from a map
  factory Fee.fromMap(Map<String, dynamic> map) {
    return Fee(
      id: map['id'] ?? '',
      studentName: map['studentName'] ?? '',
      courseName: map['courseName'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      dueDate:
          map['dueDate'] != null
              ? DateTime.parse(map['dueDate'])
              : DateTime.now(),
      isPaid: map['isPaid'] ?? false,
    );
  }

  // Method to convert Fee to a map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentName': studentName,
      'courseName': courseName,
      'amount': amount,
      'dueDate': dueDate.toIso8601String(),
      'isPaid': isPaid,
    };
  }
}
