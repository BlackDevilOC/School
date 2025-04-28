// This service handles data management and synchronization
// between different screens in the application

class DataService {
  // Singleton pattern
  static final DataService _instance = DataService._internal();

  factory DataService() {
    return _instance;
  }

  DataService._internal();

  // Student data
  final List<Map<String, dynamic>> _students = [
    // Class Students
    {
      'id': '1',
      'name': 'Alice Brown',
      'fatherName': 'John Brown',
      'classGrade': '10th',
      'rollNumber': 101,
      'phoneNumber': '555-111-2222',
      'isPresent': true,
      'isClassStudent': true,
    },
    {
      'id': '2',
      'name': 'Bob Johnson',
      'fatherName': 'Mike Johnson',
      'classGrade': '9th',
      'rollNumber': 102,
      'phoneNumber': '555-333-4444',
      'isPresent': false,
      'isClassStudent': true,
    },
    {
      'id': '3',
      'name': 'Charlie Davis',
      'fatherName': 'William Davis',
      'classGrade': '11th',
      'rollNumber': 103,
      'phoneNumber': '555-555-6666',
      'isPresent': true,
      'isClassStudent': true,
    },
    {
      'id': '4',
      'name': 'Diana Smith',
      'fatherName': 'Robert Smith',
      'classGrade': '10th',
      'rollNumber': 104,
      'phoneNumber': '555-777-8888',
      'isPresent': true,
      'isClassStudent': true,
    },
    {
      'id': '5',
      'name': 'Edward Wilson',
      'fatherName': 'James Wilson',
      'classGrade': '9th',
      'rollNumber': 105,
      'phoneNumber': '555-999-0000',
      'isPresent': false,
      'isClassStudent': true,
    },
    // Course Students
    {
      'id': '6',
      'name': 'Frank Miller',
      'fatherName': 'George Miller',
      'courseName': 'Web Development',
      'batchNumber': 'WD-2024',
      'rollNumber': 201,
      'phoneNumber': '555-111-3333',
      'isPresent': true,
      'isClassStudent': false,
    },
    {
      'id': '7',
      'name': 'Grace Taylor',
      'fatherName': 'Henry Taylor',
      'courseName': 'Web Development',
      'batchNumber': 'WD-2024',
      'rollNumber': 202,
      'phoneNumber': '555-222-4444',
      'isPresent': true,
      'isClassStudent': false,
    },
    {
      'id': '8',
      'name': 'Harry Anderson',
      'fatherName': 'Ian Anderson',
      'courseName': 'Mobile App Development',
      'batchNumber': 'MAD-2024',
      'rollNumber': 301,
      'phoneNumber': '555-333-5555',
      'isPresent': false,
      'isClassStudent': false,
    },
    {
      'id': '9',
      'name': 'Ivy Clark',
      'fatherName': 'Jack Clark',
      'courseName': 'Mobile App Development',
      'batchNumber': 'MAD-2024',
      'rollNumber': 302,
      'phoneNumber': '555-444-6666',
      'isPresent': true,
      'isClassStudent': false,
    },
    {
      'id': '10',
      'name': 'Julia Martin',
      'fatherName': 'Kevin Martin',
      'courseName': 'Data Science',
      'batchNumber': 'DS-2024',
      'rollNumber': 401,
      'phoneNumber': '555-555-7777',
      'isPresent': true,
      'isClassStudent': false,
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

  // Get all students
  List<Map<String, dynamic>> get students => _students;

  // Get all teachers
  List<Map<String, dynamic>> get teachers => _teachers;

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
}
