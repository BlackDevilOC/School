class FeePaymentRecord {
  final String id;
  final String studentId;
  final String studentName;
  final String className;
  final String month;
  final int year;
  final double totalFee;
  final double paidAmount;
  final DateTime paymentDate;
  final String paymentMode;
  final String receiptNumber;
  final String remarks;

  FeePaymentRecord({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.month,
    required this.year,
    required this.totalFee,
    required this.paidAmount,
    required this.paymentDate,
    required this.paymentMode,
    required this.receiptNumber,
    required this.remarks,
  });

  double get remainingAmount => totalFee - paidAmount;
  bool get isFullyPaid => remainingAmount <= 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'className': className,
      'month': month,
      'year': year,
      'totalFee': totalFee,
      'paidAmount': paidAmount,
      'paymentDate': paymentDate.toIso8601String(),
      'paymentMode': paymentMode,
      'receiptNumber': receiptNumber,
      'remarks': remarks,
    };
  }

  factory FeePaymentRecord.fromMap(Map<String, dynamic> map) {
    return FeePaymentRecord(
      id: map['id'] ?? '',
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      className: map['className'] ?? '',
      month: map['month'] ?? '',
      year: map['year'] ?? 0,
      totalFee: (map['totalFee'] ?? 0.0).toDouble(),
      paidAmount: (map['paidAmount'] ?? 0.0).toDouble(),
      paymentDate: DateTime.parse(map['paymentDate']),
      paymentMode: map['paymentMode'] ?? '',
      receiptNumber: map['receiptNumber'] ?? '',
      remarks: map['remarks'] ?? '',
    );
  }
}

class SalaryPaymentRecord {
  final String id;
  final String teacherId;
  final String teacherName;
  final String designation;
  final String month;
  final int year;
  final double totalSalary;
  final double paidAmount;
  final DateTime paymentDate;
  final String paymentMode;
  final String transactionId;
  final Map<String, double> deductions;
  final String remarks;

  SalaryPaymentRecord({
    required this.id,
    required this.teacherId,
    required this.teacherName,
    required this.designation,
    required this.month,
    required this.year,
    required this.totalSalary,
    required this.paidAmount,
    required this.paymentDate,
    required this.paymentMode,
    required this.transactionId,
    required this.deductions,
    required this.remarks,
  });

  double get totalDeductions =>
      deductions.values.fold(0, (sum, value) => sum + value);
  double get netSalary => totalSalary - totalDeductions;
  double get remainingAmount => netSalary - paidAmount;
  bool get isFullyPaid => remainingAmount <= 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'designation': designation,
      'month': month,
      'year': year,
      'totalSalary': totalSalary,
      'paidAmount': paidAmount,
      'paymentDate': paymentDate.toIso8601String(),
      'paymentMode': paymentMode,
      'transactionId': transactionId,
      'deductions': deductions,
      'remarks': remarks,
    };
  }

  factory SalaryPaymentRecord.fromMap(Map<String, dynamic> map) {
    return SalaryPaymentRecord(
      id: map['id'] ?? '',
      teacherId: map['teacherId'] ?? '',
      teacherName: map['teacherName'] ?? '',
      designation: map['designation'] ?? '',
      month: map['month'] ?? '',
      year: map['year'] ?? 0,
      totalSalary: (map['totalSalary'] ?? 0.0).toDouble(),
      paidAmount: (map['paidAmount'] ?? 0.0).toDouble(),
      paymentDate: DateTime.parse(map['paymentDate']),
      paymentMode: map['paymentMode'] ?? '',
      transactionId: map['transactionId'] ?? '',
      deductions: Map<String, double>.from(map['deductions'] ?? {}),
      remarks: map['remarks'] ?? '',
    );
  }
}
