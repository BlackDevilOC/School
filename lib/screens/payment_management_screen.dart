import 'package:flutter/material.dart';
import '../models/payment_record.dart';
import '../services/data_service.dart';

class PaymentManagementScreen extends StatefulWidget {
  final bool isTeacher;

  const PaymentManagementScreen({super.key, required this.isTeacher});

  @override
  _PaymentManagementScreenState createState() =>
      _PaymentManagementScreenState();
}

class _PaymentManagementScreenState extends State<PaymentManagementScreen> {
  final DataService _dataService = DataService();
  String _selectedMonth = 'January';
  int _selectedYear = DateTime.now().year;
  String _searchQuery = '';
  String _filterStatus = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isTeacher ? 'Salary Management' : 'Fee Management'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [_buildFilters(), Expanded(child: _buildPaymentList())],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPaymentDialog(),
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText:
                        'Search by ${widget.isTeacher ? 'teacher' : 'student'} name',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: _filterStatus,
                items:
                    ['All', 'Paid', 'Pending', 'Partial']
                        .map(
                          (status) => DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  setState(() {
                    _filterStatus = value!;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedMonth,
                  isExpanded: true,
                  items:
                      [
                            'January',
                            'February',
                            'March',
                            'April',
                            'May',
                            'June',
                            'July',
                            'August',
                            'September',
                            'October',
                            'November',
                            'December',
                          ]
                          .map(
                            (month) => DropdownMenuItem(
                              value: month,
                              child: Text(month),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedMonth = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButton<int>(
                  value: _selectedYear,
                  isExpanded: true,
                  items:
                      List.generate(
                            5,
                            (index) => DateTime.now().year - 2 + index,
                          )
                          .map(
                            (year) => DropdownMenuItem(
                              value: year,
                              child: Text(year.toString()),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedYear = value!;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentList() {
    final payments =
        widget.isTeacher
            ? _dataService.getSalaryPaymentsByMonth(
              _selectedMonth,
              _selectedYear,
            )
            : _dataService.getFeePaymentsByMonth(_selectedMonth, _selectedYear);

    return ListView.builder(
      itemCount: payments.length,
      itemBuilder: (context, index) {
        final payment = payments[index];
        return widget.isTeacher
            ? _buildSalaryPaymentCard(payment as SalaryPaymentRecord)
            : _buildFeePaymentCard(payment as FeePaymentRecord);
      },
    );
  }

  Widget _buildFeePaymentCard(FeePaymentRecord payment) {
    final paymentStatus =
        payment.isFullyPaid
            ? 'Paid'
            : payment.paidAmount > 0
            ? 'Partial'
            : 'Pending';
    final statusColor =
        payment.isFullyPaid
            ? Colors.green
            : payment.paidAmount > 0
            ? Colors.orange
            : Colors.red;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        title: Text(payment.studentName),
        subtitle: Text('Class: ${payment.className}'),
        trailing: Chip(
          label: Text(paymentStatus),
          backgroundColor: statusColor.withOpacity(0.1),
          labelStyle: TextStyle(color: statusColor),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Total Fee', '₹${payment.totalFee}'),
                _buildInfoRow('Paid Amount', '₹${payment.paidAmount}'),
                _buildInfoRow('Remaining', '₹${payment.remainingAmount}'),
                _buildInfoRow('Payment Date', _formatDate(payment.paymentDate)),
                _buildInfoRow('Receipt Number', payment.receiptNumber),
                _buildInfoRow('Payment Mode', payment.paymentMode),
                if (payment.remarks.isNotEmpty)
                  _buildInfoRow('Remarks', payment.remarks),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed:
                          () => _showAddPaymentDialog(existingPayment: payment),
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                    TextButton.icon(
                      onPressed:
                          () => _showPaymentHistoryDialog(payment.studentId),
                      icon: const Icon(Icons.history),
                      label: const Text('History'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalaryPaymentCard(SalaryPaymentRecord payment) {
    final paymentStatus =
        payment.isFullyPaid
            ? 'Paid'
            : payment.paidAmount > 0
            ? 'Partial'
            : 'Pending';
    final statusColor =
        payment.isFullyPaid
            ? Colors.green
            : payment.paidAmount > 0
            ? Colors.orange
            : Colors.red;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        title: Text(payment.teacherName),
        subtitle: Text(payment.designation),
        trailing: Chip(
          label: Text(paymentStatus),
          backgroundColor: statusColor.withOpacity(0.1),
          labelStyle: TextStyle(color: statusColor),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Total Salary', '₹${payment.totalSalary}'),
                _buildInfoRow(
                  'Total Deductions',
                  '₹${payment.totalDeductions}',
                ),
                _buildInfoRow('Net Salary', '₹${payment.netSalary}'),
                _buildInfoRow('Paid Amount', '₹${payment.paidAmount}'),
                _buildInfoRow('Remaining', '₹${payment.remainingAmount}'),
                _buildInfoRow('Payment Date', _formatDate(payment.paymentDate)),
                _buildInfoRow('Transaction ID', payment.transactionId),
                _buildInfoRow('Payment Mode', payment.paymentMode),
                if (payment.remarks.isNotEmpty)
                  _buildInfoRow('Remarks', payment.remarks),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed:
                          () => _showAddPaymentDialog(
                            existingSalaryPayment: payment,
                          ),
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                    TextButton.icon(
                      onPressed:
                          () => _showPaymentHistoryDialog(
                            payment.teacherId,
                            isTeacher: true,
                          ),
                      icon: const Icon(Icons.history),
                      label: const Text('History'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showAddPaymentDialog({
    FeePaymentRecord? existingPayment,
    SalaryPaymentRecord? existingSalaryPayment,
  }) {
    // TODO: Implement add/edit payment dialog
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              existingPayment != null || existingSalaryPayment != null
                  ? 'Edit Payment'
                  : 'Add Payment',
            ),
            content: const Text('Payment form will be implemented here'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  // TODO: Implement save logic
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void _showPaymentHistoryDialog(String id, {bool isTeacher = false}) {
    final payments =
        isTeacher
            ? _dataService.getSalaryPaymentsByTeacher(id)
            : _dataService.getFeePaymentsByStudent(id);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Payment History'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: payments.length,
                itemBuilder: (context, index) {
                  final payment = payments[index];
                  return ListTile(
                    title: Text(
                      '${payment.month} ${payment.year}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      isTeacher
                          ? 'Paid: ₹${(payment as SalaryPaymentRecord).paidAmount}'
                          : 'Paid: ₹${(payment as FeePaymentRecord).paidAmount}',
                    ),
                    trailing: Text(
                      _formatDate(payment.paymentDate),
                      style: const TextStyle(color: Colors.black54),
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }
}
