class FeeStructure {
  final String id;
  final String className;
  final double monthlyFee;
  final double admissionFee;
  final double examFee;
  final double libraryFee;
  final double transportFee;
  final Map<String, double> otherFees;

  FeeStructure({
    required this.id,
    required this.className,
    required this.monthlyFee,
    required this.admissionFee,
    required this.examFee,
    required this.libraryFee,
    required this.transportFee,
    required this.otherFees,
  });

  double get totalMonthlyFee {
    return monthlyFee +
        libraryFee +
        transportFee +
        otherFees.values.fold(0, (sum, fee) => sum + fee);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'className': className,
      'monthlyFee': monthlyFee,
      'admissionFee': admissionFee,
      'examFee': examFee,
      'libraryFee': libraryFee,
      'transportFee': transportFee,
      'otherFees': otherFees,
    };
  }

  factory FeeStructure.fromMap(Map<String, dynamic> map) {
    return FeeStructure(
      id: map['id'] ?? '',
      className: map['className'] ?? '',
      monthlyFee: (map['monthlyFee'] ?? 0.0).toDouble(),
      admissionFee: (map['admissionFee'] ?? 0.0).toDouble(),
      examFee: (map['examFee'] ?? 0.0).toDouble(),
      libraryFee: (map['libraryFee'] ?? 0.0).toDouble(),
      transportFee: (map['transportFee'] ?? 0.0).toDouble(),
      otherFees: Map<String, double>.from(map['otherFees'] ?? {}),
    );
  }
}

class SalaryStructure {
  final String id;
  final String designation;
  final double basicSalary;
  final double houseRent;
  final double medicalAllowance;
  final double transportAllowance;
  final Map<String, double> otherAllowances;
  final Map<String, double> deductions;

  SalaryStructure({
    required this.id,
    required this.designation,
    required this.basicSalary,
    required this.houseRent,
    required this.medicalAllowance,
    required this.transportAllowance,
    required this.otherAllowances,
    required this.deductions,
  });

  double get totalAllowances {
    return houseRent +
        medicalAllowance +
        transportAllowance +
        otherAllowances.values.fold(0, (sum, allowance) => sum + allowance);
  }

  double get totalDeductions {
    return deductions.values.fold(0, (sum, deduction) => sum + deduction);
  }

  double get netSalary {
    return basicSalary + totalAllowances - totalDeductions;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'designation': designation,
      'basicSalary': basicSalary,
      'houseRent': houseRent,
      'medicalAllowance': medicalAllowance,
      'transportAllowance': transportAllowance,
      'otherAllowances': otherAllowances,
      'deductions': deductions,
    };
  }

  factory SalaryStructure.fromMap(Map<String, dynamic> map) {
    return SalaryStructure(
      id: map['id'] ?? '',
      designation: map['designation'] ?? '',
      basicSalary: (map['basicSalary'] ?? 0.0).toDouble(),
      houseRent: (map['houseRent'] ?? 0.0).toDouble(),
      medicalAllowance: (map['medicalAllowance'] ?? 0.0).toDouble(),
      transportAllowance: (map['transportAllowance'] ?? 0.0).toDouble(),
      otherAllowances: Map<String, double>.from(map['otherAllowances'] ?? {}),
      deductions: Map<String, double>.from(map['deductions'] ?? {}),
    );
  }
}
