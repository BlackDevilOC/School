import 'package:flutter/material.dart';
import '../models/fee_structure.dart';
import '../services/data_service.dart';

class FeeStructureScreen extends StatefulWidget {
  final bool isTeacher;

  const FeeStructureScreen({super.key, required this.isTeacher});

  @override
  _FeeStructureScreenState createState() => _FeeStructureScreenState();
}

class _FeeStructureScreenState extends State<FeeStructureScreen> {
  final DataService _dataService = DataService();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isTeacher ? 'Salary Structure' : 'Fee Structure'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isTeacher ? 'Salary Structures' : 'Fee Structures',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              widget.isTeacher
                  ? _buildSalaryStructureList()
                  : _buildFeeStructureList(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(context),
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFeeStructureList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _dataService.feeStructures.length,
      itemBuilder: (context, index) {
        final feeStructure = _dataService.feeStructures[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ExpansionTile(
            title: Text(
              'Class ${feeStructure.className}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Monthly Fee: ₹${feeStructure.monthlyFee}',
              style: TextStyle(color: Colors.green.shade700),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFeeRow('Admission Fee', feeStructure.admissionFee),
                    _buildFeeRow('Exam Fee', feeStructure.examFee),
                    _buildFeeRow('Library Fee', feeStructure.libraryFee),
                    _buildFeeRow('Transport Fee', feeStructure.transportFee),
                    const Divider(),
                    const Text(
                      'Other Fees:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ...feeStructure.otherFees.entries.map(
                      (entry) => _buildFeeRow(entry.key, entry.value),
                    ),
                    const Divider(),
                    _buildFeeRow(
                      'Total Monthly Fee',
                      feeStructure.totalMonthlyFee,
                      isTotal: true,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed:
                              () => _showAddEditDialog(
                                context,
                                feeStructure: feeStructure,
                              ),
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit'),
                        ),
                        TextButton.icon(
                          onPressed: () => _deleteFeeStructure(feeStructure.id),
                          icon: const Icon(Icons.delete, color: Colors.red),
                          label: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSalaryStructureList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _dataService.salaryStructures.length,
      itemBuilder: (context, index) {
        final salaryStructure = _dataService.salaryStructures[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ExpansionTile(
            title: Text(
              salaryStructure.designation,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Basic Salary: ₹${salaryStructure.basicSalary}',
              style: TextStyle(color: Colors.green.shade700),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFeeRow('House Rent', salaryStructure.houseRent),
                    _buildFeeRow(
                      'Medical Allowance',
                      salaryStructure.medicalAllowance,
                    ),
                    _buildFeeRow(
                      'Transport Allowance',
                      salaryStructure.transportAllowance,
                    ),
                    const Divider(),
                    const Text(
                      'Other Allowances:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ...salaryStructure.otherAllowances.entries.map(
                      (entry) => _buildFeeRow(entry.key, entry.value),
                    ),
                    const Divider(),
                    const Text(
                      'Deductions:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ...salaryStructure.deductions.entries.map(
                      (entry) => _buildFeeRow(
                        entry.key,
                        entry.value,
                        isDeduction: true,
                      ),
                    ),
                    const Divider(),
                    _buildFeeRow(
                      'Net Salary',
                      salaryStructure.netSalary,
                      isTotal: true,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed:
                              () => _showAddEditDialog(
                                context,
                                salaryStructure: salaryStructure,
                              ),
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit'),
                        ),
                        TextButton.icon(
                          onPressed:
                              () => _deleteSalaryStructure(salaryStructure.id),
                          icon: const Icon(Icons.delete, color: Colors.red),
                          label: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeeRow(
    String label,
    double amount, {
    bool isTotal = false,
    bool isDeduction = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              color:
                  isDeduction
                      ? Colors.red
                      : isTotal
                      ? Colors.green.shade700
                      : Colors.black87,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddEditDialog(
    BuildContext context, {
    FeeStructure? feeStructure,
    SalaryStructure? salaryStructure,
  }) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              widget.isTeacher
                  ? (salaryStructure == null
                      ? 'Add Salary Structure'
                      : 'Edit Salary Structure')
                  : (feeStructure == null
                      ? 'Add Fee Structure'
                      : 'Edit Fee Structure'),
            ),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children:
                      widget.isTeacher
                          ? _buildSalaryStructureForm(salaryStructure)
                          : _buildFeeStructureForm(feeStructure),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // Save the form
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  List<Widget> _buildFeeStructureForm(FeeStructure? feeStructure) {
    // TODO: Implement fee structure form fields
    return [
      TextFormField(
        decoration: const InputDecoration(labelText: 'Class'),
        initialValue: feeStructure?.className,
        validator:
            (value) => value?.isEmpty ?? true ? 'Please enter class' : null,
      ),
      TextFormField(
        decoration: const InputDecoration(labelText: 'Monthly Fee'),
        initialValue: feeStructure?.monthlyFee.toString(),
        keyboardType: TextInputType.number,
        validator:
            (value) =>
                value?.isEmpty ?? true ? 'Please enter monthly fee' : null,
      ),
      // Add more fields as needed
    ];
  }

  List<Widget> _buildSalaryStructureForm(SalaryStructure? salaryStructure) {
    // TODO: Implement salary structure form fields
    return [
      TextFormField(
        decoration: const InputDecoration(labelText: 'Designation'),
        initialValue: salaryStructure?.designation,
        validator:
            (value) =>
                value?.isEmpty ?? true ? 'Please enter designation' : null,
      ),
      TextFormField(
        decoration: const InputDecoration(labelText: 'Basic Salary'),
        initialValue: salaryStructure?.basicSalary.toString(),
        keyboardType: TextInputType.number,
        validator:
            (value) =>
                value?.isEmpty ?? true ? 'Please enter basic salary' : null,
      ),
      // Add more fields as needed
    ];
  }

  void _deleteFeeStructure(String id) {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Fee Structure'),
            content: const Text(
              'Are you sure you want to delete this fee structure?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  _dataService.deleteFeeStructure(id);
                  Navigator.pop(context);
                  setState(() {});
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  void _deleteSalaryStructure(String id) {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Salary Structure'),
            content: const Text(
              'Are you sure you want to delete this salary structure?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  _dataService.deleteSalaryStructure(id);
                  Navigator.pop(context);
                  setState(() {});
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }
}
