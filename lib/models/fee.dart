import 'package:intl/intl.dart';

class Fee {
  final String id;
  final String studentId;
  final String studentName;
  final String? classGrade;
  final String? courseName;
  final double amount;
  final DateTime dueDate;
  final String status; // "Paid", "Pending", "Overdue"
  final String month;
  final int year;
  final DateTime createdAt;
  final DateTime updatedAt;

  Fee({
    required this.id,
    required this.studentId,
    required this.studentName,
    this.classGrade,
    this.courseName,
    required this.amount,
    required this.dueDate,
    required this.status,
    required this.month,
    required this.year,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create a Fee from a JSON object
  factory Fee.fromJson(Map<String, dynamic> json) {
    return Fee(
      id: json['id'],
      studentId: json['student_id'],
      studentName: json['student_name'] ?? '',
      classGrade: json['class_grade'],
      courseName: json['course_name'],
      amount: (json['amount'] is int)
          ? (json['amount'] as int).toDouble()
          : json['amount'],
      dueDate: DateTime.parse(json['due_date']),
      status: json['status'],
      month: json['month'],
      year: json['year'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  // Convert a Fee to a JSON object
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'student_name': studentName,
      'class_grade': classGrade,
      'course_name': courseName,
      'amount': amount,
      'due_date': dueDate.toIso8601String(),
      'status': status,
      'month': month,
      'year': year,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Format the due date as a string
  String get formattedDueDate {
    return DateFormat('MM/dd/yyyy').format(dueDate);
  }

  // Check if the fee is overdue
  bool get isOverdue {
    return status == 'Overdue';
  }

  // Check if the fee is paid
  bool get isPaid {
    return status == 'Paid';
  }
}
