import 'base_model.dart';

class Teacher extends BaseModel {
  final String name;
  final String subject;
  final String phoneNumber;
  final double baseSalary;
  final DateTime joiningDate;
  final bool isPresent;

  Teacher({
    required super.id,
    required this.name,
    required this.subject,
    required this.phoneNumber,
    required this.baseSalary,
    required this.joiningDate,
    required super.createdAt,
    required super.updatedAt,
    this.isPresent = true,
  });

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      id: json['id'],
      name: json['name'],
      subject: json['subject'],
      phoneNumber: json['phone_number'],
      baseSalary: (json['base_salary'] as num).toDouble(),
      joiningDate:
          BaseModel.parseDateTime(json['joining_date']) ?? DateTime.now(),
      createdAt: BaseModel.parseDateTime(json['created_at']) ?? DateTime.now(),
      updatedAt: BaseModel.parseDateTime(json['updated_at']) ?? DateTime.now(),
      isPresent: json['is_present'] ?? true,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'subject': subject,
      'phone_number': phoneNumber,
      'base_salary': baseSalary,
      'joining_date': joiningDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_present': isPresent,
    };
  }

  Teacher copyWith({
    String? name,
    String? subject,
    String? phoneNumber,
    double? baseSalary,
    DateTime? joiningDate,
    bool? isPresent,
  }) {
    return Teacher(
      id: id,
      name: name ?? this.name,
      subject: subject ?? this.subject,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      baseSalary: baseSalary ?? this.baseSalary,
      joiningDate: joiningDate ?? this.joiningDate,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isPresent: isPresent ?? this.isPresent,
    );
  }
}
