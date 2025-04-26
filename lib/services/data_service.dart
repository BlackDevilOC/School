// This service handles data management and synchronization
// between different screens in the application

import '../models/fee_structure.dart';
import '../models/payment_record.dart';

class DataService {
  // Singleton pattern
  static final DataService _instance = DataService._internal();

  factory DataService() {
    return _instance;
  }

  DataService._internal();

  // Student data
  final List<Map<String, dynamic>> _students = [
    {
      'id': '1',
      'name': 'Alice Brown',
      'fatherName': 'John Brown',
      'classGrade': '10th',
      'rollNumber': 101,
      'phoneNumber': '555-111-2222',
      'isPresent': true,
    },
    {
      'id': '2',
      'name': 'Bob Johnson',
      'fatherName': 'Mike Johnson',
      'classGrade': '9th',
      'rollNumber': 102,
      'phoneNumber': '555-333-4444',
      'isPresent': false,
    },
    {
      'id': '3',
      'name': 'Charlie Davis',
      'fatherName': 'William Davis',
      'classGrade': '11th',
      'rollNumber': 103,
      'phoneNumber': '555-555-6666',
      'isPresent': true,
    },
    {
      'id': '4',
      'name': 'Diana Smith',
      'fatherName': 'Robert Smith',
      'classGrade': '10th',
      'rollNumber': 104,
      'phoneNumber': '555-777-8888',
      'isPresent': true,
    },
    {
      'id': '5',
      'name': 'Edward Wilson',
      'fatherName': 'James Wilson',
      'classGrade': '9th',
      'rollNumber': 105,
      'phoneNumber': '555-999-0000',
      'isPresent': false,
    },
  ];

  // Teacher data
  final List<Map<String, dynamic>> _teachers = [
    {
      'id': '1',
      'name': 'John Smith',
      'subject': 'Mathematics',
      'phoneNumber': '555-123-4567',
      'isPresent': true,
    },
    {
      'id': '2',
      'name': 'Sarah Johnson',
      'subject': 'Science',
      'phoneNumber': '555-987-6543',
      'isPresent': false,
    },
    {
      'id': '3',
      'name': 'David Wilson',
      'subject': 'English',
      'phoneNumber': '555-456-7890',
      'isPresent': true,
    },
    {
      'id': '4',
      'name': 'Emily Brown',
      'subject': 'History',
      'phoneNumber': '555-234-5678',
      'isPresent': true,
    },
    {
      'id': '5',
      'name': 'Michael Davis',
      'subject': 'Physical Education',
      'phoneNumber': '555-876-5432',
      'isPresent': false,
    },
  ];

  // Fee structures for different classes
  final List<FeeStructure> _feeStructures = [
    FeeStructure(
      id: '1',
      className: '9th',
      monthlyFee: 5000.0,
      admissionFee: 10000.0,
      examFee: 2000.0,
      libraryFee: 500.0,
      transportFee: 1000.0,
      otherFees: {'Computer Lab': 500.0, 'Sports': 300.0},
    ),
    FeeStructure(
      id: '2',
      className: '10th',
      monthlyFee: 5500.0,
      admissionFee: 10000.0,
      examFee: 2000.0,
      libraryFee: 500.0,
      transportFee: 1000.0,
      otherFees: {'Computer Lab': 500.0, 'Sports': 300.0},
    ),
    FeeStructure(
      id: '3',
      className: '11th',
      monthlyFee: 6000.0,
      admissionFee: 12000.0,
      examFee: 2500.0,
      libraryFee: 600.0,
      transportFee: 1000.0,
      otherFees: {'Computer Lab': 700.0, 'Sports': 300.0},
    ),
    FeeStructure(
      id: '4',
      className: '12th',
      monthlyFee: 6500.0,
      admissionFee: 12000.0,
      examFee: 2500.0,
      libraryFee: 600.0,
      transportFee: 1000.0,
      otherFees: {'Computer Lab': 700.0, 'Sports': 300.0},
    ),
  ];

  // Salary structures for different designations
  final List<SalaryStructure> _salaryStructures = [
    SalaryStructure(
      id: '1',
      designation: 'Junior Teacher',
      basicSalary: 30000.0,
      houseRent: 5000.0,
      medicalAllowance: 2000.0,
      transportAllowance: 1500.0,
      otherAllowances: {'Performance': 2000.0},
      deductions: {'Tax': 1500.0, 'Insurance': 1000.0},
    ),
    SalaryStructure(
      id: '2',
      designation: 'Senior Teacher',
      basicSalary: 45000.0,
      houseRent: 7000.0,
      medicalAllowance: 3000.0,
      transportAllowance: 2000.0,
      otherAllowances: {'Performance': 3000.0},
      deductions: {'Tax': 2250.0, 'Insurance': 1500.0},
    ),
    SalaryStructure(
      id: '3',
      designation: 'Head of Department',
      basicSalary: 60000.0,
      houseRent: 10000.0,
      medicalAllowance: 4000.0,
      transportAllowance: 2500.0,
      otherAllowances: {'Performance': 5000.0, 'Position': 3000.0},
      deductions: {'Tax': 3000.0, 'Insurance': 2000.0},
    ),
  ];

  // Payment records
  final List<FeePaymentRecord> _feePayments = [];
  final List<SalaryPaymentRecord> _salaryPayments = [];

  // Get all students
  List<Map<String, dynamic>> get students => _students;

  // Get all teachers
  List<Map<String, dynamic>> get teachers => _teachers;

  // Get all fee structures
  List<FeeStructure> get feeStructures => _feeStructures;

  // Get all salary structures
  List<SalaryStructure> get salaryStructures => _salaryStructures;

  // Get all fee payments
  List<FeePaymentRecord> get feePayments => _feePayments;

  // Get all salary payments
  List<SalaryPaymentRecord> get salaryPayments => _salaryPayments;

  // Get fee structure by class
  FeeStructure? getFeeStructureByClass(String className) {
    try {
      return _feeStructures.firstWhere((fee) => fee.className == className);
    } catch (e) {
      return null;
    }
  }

  // Get salary structure by designation
  SalaryStructure? getSalaryStructureByDesignation(String designation) {
    try {
      return _salaryStructures.firstWhere(
        (salary) => salary.designation == designation,
      );
    } catch (e) {
      return null;
    }
  }

  // Add a new student
  void addStudent(Map<String, dynamic> student) {
    // Add isPresent field if not present
    if (!student.containsKey('isPresent')) {
      student['isPresent'] = true;
    }
    _students.add(student);
  }

  // Update a student
  void updateStudent(String id, Map<String, dynamic> updatedStudent) {
    final index = _students.indexWhere((student) => student['id'] == id);
    if (index != -1) {
      // Keep isPresent value if not provided
      if (!updatedStudent.containsKey('isPresent')) {
        updatedStudent['isPresent'] = _students[index]['isPresent'];
      }
      _students[index] = updatedStudent;
    }
  }

  // Delete a student
  void deleteStudent(String id) {
    _students.removeWhere((student) => student['id'] == id);
  }

  // Update student attendance
  void updateStudentAttendance(String id, bool isPresent) {
    final index = _students.indexWhere((student) => student['id'] == id);
    if (index != -1) {
      _students[index]['isPresent'] = isPresent;
    }
  }

  // Add a new teacher
  void addTeacher(Map<String, dynamic> teacher) {
    // Add isPresent field if not present
    if (!teacher.containsKey('isPresent')) {
      teacher['isPresent'] = true;
    }
    _teachers.add(teacher);
  }

  // Update a teacher
  void updateTeacher(String id, Map<String, dynamic> updatedTeacher) {
    final index = _teachers.indexWhere((teacher) => teacher['id'] == id);
    if (index != -1) {
      // Keep isPresent value if not provided
      if (!updatedTeacher.containsKey('isPresent')) {
        updatedTeacher['isPresent'] = _teachers[index]['isPresent'];
      }
      _teachers[index] = updatedTeacher;
    }
  }

  // Delete a teacher
  void deleteTeacher(String id) {
    _teachers.removeWhere((teacher) => teacher['id'] == id);
  }

  // Update teacher attendance
  void updateTeacherAttendance(String id, bool isPresent) {
    final index = _teachers.indexWhere((teacher) => teacher['id'] == id);
    if (index != -1) {
      _teachers[index]['isPresent'] = isPresent;
    }
  }

  // Update fee structure
  void updateFeeStructure(String id, FeeStructure updatedFee) {
    final index = _feeStructures.indexWhere((fee) => fee.id == id);
    if (index != -1) {
      _feeStructures[index] = updatedFee;
    }
  }

  // Update salary structure
  void updateSalaryStructure(String id, SalaryStructure updatedSalary) {
    final index = _salaryStructures.indexWhere((salary) => salary.id == id);
    if (index != -1) {
      _salaryStructures[index] = updatedSalary;
    }
  }

  // Add new fee structure
  void addFeeStructure(FeeStructure feeStructure) {
    _feeStructures.add(feeStructure);
  }

  // Add new salary structure
  void addSalaryStructure(SalaryStructure salaryStructure) {
    _salaryStructures.add(salaryStructure);
  }

  // Delete fee structure
  void deleteFeeStructure(String id) {
    _feeStructures.removeWhere((fee) => fee.id == id);
  }

  // Delete salary structure
  void deleteSalaryStructure(String id) {
    _salaryStructures.removeWhere((salary) => salary.id == id);
  }

  // Get fee payments by student ID
  List<FeePaymentRecord> getFeePaymentsByStudent(String studentId) {
    return _feePayments
        .where((payment) => payment.studentId == studentId)
        .toList();
  }

  // Get fee payments by class
  List<FeePaymentRecord> getFeePaymentsByClass(String className) {
    return _feePayments
        .where((payment) => payment.className == className)
        .toList();
  }

  // Get fee payments by month and year
  List<FeePaymentRecord> getFeePaymentsByMonth(String month, int year) {
    return _feePayments
        .where((payment) => payment.month == month && payment.year == year)
        .toList();
  }

  // Get salary payments by teacher ID
  List<SalaryPaymentRecord> getSalaryPaymentsByTeacher(String teacherId) {
    return _salaryPayments
        .where((payment) => payment.teacherId == teacherId)
        .toList();
  }

  // Get salary payments by month and year
  List<SalaryPaymentRecord> getSalaryPaymentsByMonth(String month, int year) {
    return _salaryPayments
        .where((payment) => payment.month == month && payment.year == year)
        .toList();
  }

  // Add new fee payment
  void addFeePayment(FeePaymentRecord payment) {
    _feePayments.add(payment);
  }

  // Add new salary payment
  void addSalaryPayment(SalaryPaymentRecord payment) {
    _salaryPayments.add(payment);
  }

  // Update fee payment
  void updateFeePayment(String id, FeePaymentRecord updatedPayment) {
    final index = _feePayments.indexWhere((payment) => payment.id == id);
    if (index != -1) {
      _feePayments[index] = updatedPayment;
    }
  }

  // Update salary payment
  void updateSalaryPayment(String id, SalaryPaymentRecord updatedPayment) {
    final index = _salaryPayments.indexWhere((payment) => payment.id == id);
    if (index != -1) {
      _salaryPayments[index] = updatedPayment;
    }
  }

  // Delete fee payment
  void deleteFeePayment(String id) {
    _feePayments.removeWhere((payment) => payment.id == id);
  }

  // Delete salary payment
  void deleteSalaryPayment(String id) {
    _salaryPayments.removeWhere((payment) => payment.id == id);
  }

  // Get pending fee payments by student
  List<FeePaymentRecord> getPendingFeePayments(String studentId) {
    return _feePayments
        .where(
          (payment) => payment.studentId == studentId && !payment.isFullyPaid,
        )
        .toList();
  }

  // Get pending salary payments by teacher
  List<SalaryPaymentRecord> getPendingSalaryPayments(String teacherId) {
    return _salaryPayments
        .where(
          (payment) => payment.teacherId == teacherId && !payment.isFullyPaid,
        )
        .toList();
  }
}
