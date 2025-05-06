class TeacherSalary {
  final String id;
  final String teacherId;
  final String? teacherName; // For display purposes, not stored in DB
  final String? subject; // For display purposes, not stored in DB
  final double amount;
  final DateTime dueDate;
  final DateTime paymentDate;
  final String status;
  final int month;
  final int year;
  final DateTime createdAt;
  final DateTime updatedAt;

  TeacherSalary({
    required this.id,
    required this.teacherId,
    this.teacherName,
    this.subject,
    required this.amount,
    required this.dueDate,
    required this.paymentDate,
    required this.status,
    required this.month,
    required this.year,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TeacherSalary.fromJson(Map<String, dynamic> json) {
    return TeacherSalary(
      id: json['id'] as String,
      teacherId: json['teacher_id'] as String,
      teacherName: json['teacher_name'] as String?,
      subject: json['subject'] as String?,
      amount: json['amount'] != null ? double.parse(json['amount'].toString()) : 0.0,
      dueDate: DateTime.parse(json['due_date'] as String),
      paymentDate: DateTime.parse(json['payment_date'] as String),
      status: json['status'] as String,
      month: json['month'] as int,
      year: json['year'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'id': id,
      'teacher_id': teacherId,
      'amount': amount,
      'due_date': dueDate.toIso8601String().split('T')[0],
      'payment_date': paymentDate.toIso8601String().split('T')[0],
      'status': status,
      'month': month,
      'year': year,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
    
    return json;
  }
}
