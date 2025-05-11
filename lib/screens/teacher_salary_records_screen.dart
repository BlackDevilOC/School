import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/teacher_salary.dart';
import '../services/database_service.dart';

class TeacherSalaryRecordsScreen extends StatefulWidget {
  final String teacherId;
  final String teacherName;

  const TeacherSalaryRecordsScreen({
    Key? key,
    required this.teacherId,
    required this.teacherName,
  }) : super(key: key);

  @override
  _TeacherSalaryRecordsScreenState createState() => _TeacherSalaryRecordsScreenState();
}

class _TeacherSalaryRecordsScreenState extends State<TeacherSalaryRecordsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = true;
  bool _isDarkMode = false;
  List<TeacherSalary> _salaryRecords = [];
  
  @override
  void initState() {
    super.initState();
    _loadSalaryRecords();
  }
  
  Future<void> _loadSalaryRecords() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final records = await _databaseService.getTeacherSalaryHistory(widget.teacherId);
      setState(() {
        _salaryRecords = records;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading salary records: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        brightness: _isDarkMode ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '${widget.teacherName} - Salary Records',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.green,
          actions: [
            IconButton(
              icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: () {
                setState(() {
                  _isDarkMode = !_isDarkMode;
                });
              },
              tooltip: 'Toggle theme',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildSalaryRecordsList(),
      ),
    );
  }
  
  Widget _buildSalaryRecordsList() {
    if (_salaryRecords.isEmpty) {
      return const Center(
        child: Text(
          'No salary records found for this teacher.',
          style: TextStyle(fontSize: 16),
        ),
      );
    }
    
    return ListView.builder(
      itemCount: _salaryRecords.length,
      itemBuilder: (context, index) {
        final salary = _salaryRecords[index];
        final dateFormat = DateFormat('MMM yyyy');
        final paymentDateFormat = DateFormat('dd MMM yyyy');
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          child: ListTile(
            title: Text(
              '${dateFormat.format(DateTime(salary.year, salary.month))} - ${NumberFormat.currency(symbol: '\$').format(salary.amount)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Payment Date: ${paymentDateFormat.format(salary.paymentDate)}'),
                Text('Status: ${salary.status}'),
                if (salary.paymentMethod != null && salary.paymentMethod!.isNotEmpty)
                  Text('Payment Method: ${salary.paymentMethod}'),
                if (salary.notes != null && salary.notes!.isNotEmpty)
                  Text('Notes: ${salary.notes}'),
              ],
            ),
            trailing: _buildStatusIcon(salary.status),
            contentPadding: const EdgeInsets.all(16),
            isThreeLine: true,
          ),
        );
      },
    );
  }
  
  Widget _buildStatusIcon(String status) {
    IconData iconData;
    Color iconColor;
    
    switch (status) {
      case 'Paid':
        iconData = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case 'Pending':
        iconData = Icons.pending;
        iconColor = Colors.orange;
        break;
      case 'Overdue':
        iconData = Icons.warning;
        iconColor = Colors.red;
        break;
      default:
        iconData = Icons.info;
        iconColor = Colors.blue;
    }
    
    return Icon(iconData, color: iconColor, size: 28);
  }
}
