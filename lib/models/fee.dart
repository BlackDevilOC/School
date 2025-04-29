import 'base_model.dart';
import 'student.dart';
import 'payment_status.dart';

enum PaymentMethod { cash, bankTransfer, online }

class Fee extends BaseModel {
  final String studentId;
  final String? feeStructureId;
  final DateTime month;
  final double amount;
  final DateTime dueDate;
  final PaymentStatus status;
  final DateTime? paidDate;
  final String? paymentMethod;
  final String? transactionId;
  final String? notes;

  Fee({
    required super.id,
    required this.studentId,
    this.feeStructureId,
    required this.month,
    required this.amount,
    required this.dueDate,
    this.status = PaymentStatus.pending,
    this.paidDate,
    this.paymentMethod,
    this.transactionId,
    this.notes,
    required super.createdAt,
    required super.updatedAt,
  });

  factory Fee.fromJson(Map<String, dynamic> json) {
    return Fee(
      id: json['id'],
      studentId: json['student_id'],
      feeStructureId: json['fee_structure_id'],
      month: BaseModel.parseDateTime(json['month']) ?? DateTime.now(),
      amount: (json['amount'] as num).toDouble(),
      dueDate: BaseModel.parseDateTime(json['due_date']) ?? DateTime.now(),
      status: PaymentStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => PaymentStatus.pending,
      ),
      paidDate: BaseModel.parseDateTime(json['paid_date']),
      paymentMethod: json['payment_method'],
      transactionId: json['transaction_id'],
      notes: json['notes'],
      createdAt: BaseModel.parseDateTime(json['created_at']) ?? DateTime.now(),
      updatedAt: BaseModel.parseDateTime(json['updated_at']) ?? DateTime.now(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'fee_structure_id': feeStructureId,
      'month': month.toIso8601String(),
      'amount': amount,
      'due_date': dueDate.toIso8601String(),
      'status': status.toString().split('.').last,
      'paid_date': paidDate?.toIso8601String(),
      'payment_method': paymentMethod,
      'transaction_id': transactionId,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Fee copyWith({
    String? studentId,
    String? feeStructureId,
    DateTime? month,
    double? amount,
    DateTime? dueDate,
    PaymentStatus? status,
    DateTime? paidDate,
    String? paymentMethod,
    String? transactionId,
    String? notes,
  }) {
    return Fee(
      id: id,
      studentId: studentId ?? this.studentId,
      feeStructureId: feeStructureId ?? this.feeStructureId,
      month: month ?? this.month,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      paidDate: paidDate ?? this.paidDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionId: transactionId ?? this.transactionId,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class FeePayment extends BaseModel {
  final String studentFeeId;
  final double amount;
  final DateTime paymentDate;
  final PaymentMethod paymentMethod;
  final String? transactionReference;
  final String? remarks;

  FeePayment({
    required super.id,
    required this.studentFeeId,
    required this.amount,
    required this.paymentDate,
    required this.paymentMethod,
    this.transactionReference,
    this.remarks,
    required super.createdAt,
    required super.updatedAt,
  });

  factory FeePayment.fromJson(Map<String, dynamic> json) {
    return FeePayment(
      id: json['id'],
      studentFeeId: json['student_fee_id'],
      amount: (json['amount'] as num).toDouble(),
      paymentDate:
          BaseModel.parseDateTime(json['payment_date']) ?? DateTime.now(),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.toString().split('.').last == json['payment_method'],
        orElse: () => PaymentMethod.cash,
      ),
      transactionReference: json['transaction_reference'],
      remarks: json['remarks'],
      createdAt: BaseModel.parseDateTime(json['created_at']) ?? DateTime.now(),
      updatedAt: BaseModel.parseDateTime(json['updated_at']) ?? DateTime.now(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_fee_id': studentFeeId,
      'amount': amount,
      'payment_date': paymentDate.toIso8601String(),
      'payment_method': paymentMethod.toString().split('.').last,
      'transaction_reference': transactionReference,
      'remarks': remarks,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  FeePayment copyWith({
    String? studentFeeId,
    double? amount,
    DateTime? paymentDate,
    PaymentMethod? paymentMethod,
    String? transactionReference,
    String? remarks,
  }) {
    return FeePayment(
      id: id,
      studentFeeId: studentFeeId ?? this.studentFeeId,
      amount: amount ?? this.amount,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionReference: transactionReference ?? this.transactionReference,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
