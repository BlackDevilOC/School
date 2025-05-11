

class TeacherSalary {
  final String id;
  final String teacherId;
  final String teacherName;
  final double amount;
  final DateTime paymentDate;
  final int month;
  final int year;
  final String status; // 'Paid', 'Pending', 'Overdue'
  final String? paymentMethod;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  TeacherSalary({
    required this.id,
    required this.teacherId,
    required this.teacherName,
    required this.amount,
    required this.paymentDate,
    required this.month,
    required this.year,
    required this.status,
    this.paymentMethod,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  // Computed properties
  bool get isPaid => status == 'Paid';
  bool get isOverdue => status == 'Overdue';
  bool get isPending => status == 'Pending';

  // Factory constructor to create a TeacherSalary from JSON
  factory TeacherSalary.fromJson(Map<String, dynamic> json) {
    // Get payment date from the JSON
    DateTime paymentDate;
    if (json.containsKey('payment_date')) {
      paymentDate = DateTime.parse(json['payment_date'] as String);
    } else {
      paymentDate = DateTime.now(); // Fallback
    }
    
    return TeacherSalary(
      id: json['id'] as String,
      teacherId: json['teacher_id'] as String,
      teacherName: json['teacher_name'] as String,
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : 0.0,
      paymentDate: paymentDate,
      month: json['month'] as int,
      year: json['year'] as int,
      status: json['status'] as String,
      paymentMethod: json['payment_method'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // Method to convert TeacherSalary to JSON for database
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teacher_id': teacherId,
      // teacher_name is not stored in the database, it's joined from teachers table
      'amount': amount,
      'payment_date': paymentDate.toIso8601String().split('T')[0],
      'month': month,
      'year': year,
      'status': status,
      'payment_method': paymentMethod,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Create a copy of this TeacherSalary with given fields replaced with new values
  TeacherSalary copyWith({
    String? id,
    String? teacherId,
    String? teacherName,
    double? amount,
    DateTime? paymentDate,
    int? month,
    int? year,
    String? status,
    String? paymentMethod,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TeacherSalary(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      amount: amount ?? this.amount,
      paymentDate: paymentDate ?? this.paymentDate,
      month: month ?? this.month,
      year: year ?? this.year,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TeacherSalary &&
        other.id == id &&
        other.teacherId == teacherId &&
        other.teacherName == teacherName &&
        other.amount == amount &&
        other.paymentDate == paymentDate &&
        other.month == month &&
        other.year == year &&
        other.status == status &&
        other.paymentMethod == paymentMethod &&
        other.notes == notes;
  }

  @override
  int get hashCode => Object.hash(
        id,
        teacherId,
        teacherName,
        amount,
        paymentDate,
        month,
        year,
        status,
        paymentMethod,
        notes,
      );
}
