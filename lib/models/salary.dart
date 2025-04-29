import 'base_model.dart';

enum PaymentStatus { pending, paid, overdue }

class Salary extends BaseModel {
  final String teacherId;
  final double amount;
  final DateTime month;
  final PaymentStatus status;
  final DateTime? paymentDate;
  final String? paymentMethod;
  final String? remarks;

  Salary({
    required super.id,
    required this.teacherId,
    required this.amount,
    required this.month,
    required this.status,
    this.paymentDate,
    this.paymentMethod,
    this.remarks,
    required super.createdAt,
    required super.updatedAt,
  });

  factory Salary.fromJson(Map<String, dynamic> json) {
    return Salary(
      id: json['id'],
      teacherId: json['teacher_id'],
      amount: (json['amount'] as num).toDouble(),
      month: BaseModel.parseDateTime(json['month']) ?? DateTime.now(),
      status: PaymentStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => PaymentStatus.pending,
      ),
      paymentDate: json['payment_date'] != null
          ? BaseModel.parseDateTime(json['payment_date'])
          : null,
      paymentMethod: json['payment_method'],
      remarks: json['remarks'],
      createdAt: BaseModel.parseDateTime(json['created_at']) ?? DateTime.now(),
      updatedAt: BaseModel.parseDateTime(json['updated_at']) ?? DateTime.now(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teacher_id': teacherId,
      'amount': amount,
      'month': month.toIso8601String(),
      'status': status.toString().split('.').last,
      'payment_date': paymentDate?.toIso8601String(),
      'payment_method': paymentMethod,
      'remarks': remarks,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Salary copyWith({
    String? teacherId,
    double? amount,
    DateTime? month,
    PaymentStatus? status,
    DateTime? paymentDate,
    String? paymentMethod,
    String? remarks,
  }) {
    return Salary(
      id: id,
      teacherId: teacherId ?? this.teacherId,
      amount: amount ?? this.amount,
      month: month ?? this.month,
      status: status ?? this.status,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
