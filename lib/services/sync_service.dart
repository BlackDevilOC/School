import 'package:flutter/foundation.dart';
import '../services/database_service.dart';
import '../models/student.dart';
import '../models/attendance.dart';

class SyncService {
  final DatabaseService _databaseService;
  
  SyncService(this._databaseService);

  // Cache for storing data
  static Map<String, dynamic> _cache = {};
  
  Future<List<Student>> getStudentsWithCache() async {
    if (_cache['students'] != null) {
      // Return cached data immediately
      return _cache['students'] as List<Student>;
    }
    
    // Load data in background
    _loadStudentsInBackground();
    
    // Return empty list initially
    return [];
  }
  
  Future<void> _loadStudentsInBackground() async {
    try {
      final students = await _databaseService.getStudents();
      _cache['students'] = students;
    } catch (e) {
      debugPrint('Error loading students: $e');
    }
  }
  
  Future<Map<String, Map<String, int>>> getAttendanceStatsWithCache(List<Student> students) async {
    if (_cache['attendanceStats'] != null) {
      return _cache['attendanceStats'] as Map<String, Map<String, int>>;
    }
    
    _loadAttendanceStatsInBackground(students);
    return {};
  }
  
  Future<void> _loadAttendanceStatsInBackground(List<Student> students) async {
    try {
      final stats = await _calculateAttendanceStats(students);
      _cache['attendanceStats'] = stats;
    } catch (e) {
      debugPrint('Error loading attendance stats: $e');
    }
  }
  
  Future<Map<String, Map<String, int>>> _calculateAttendanceStats(List<Student> students) async {
    final Map<String, Map<String, int>> stats = {};
    final now = DateTime.now();
    
    for (final student in students) {
      final attendance = await _databaseService.getStudentAttendance(student.id);
      final currentMonthAttendance = attendance.where((a) => 
        a.month == now.month && a.year == now.year).toList();
      
      stats[student.id] = {
        'present': currentMonthAttendance.where((a) => a.status == 'Present').length,
        'absent': currentMonthAttendance.where((a) => a.status == 'Absent').length,
        'excused': currentMonthAttendance.where((a) => a.status == 'Excused').length,
        'total': currentMonthAttendance.length,
      };
    }
    
    return stats;
  }
  
  void clearCache() {
    _cache.clear();
  }
}
