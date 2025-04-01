import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../sidebar.dart';

class TuitionFeeManagement extends StatefulWidget {
  const TuitionFeeManagement({Key? key}) : super(key: key);

  @override
  _TuitionFeeManagementState createState() => _TuitionFeeManagementState();
}

class _TuitionFeeManagementState extends State<TuitionFeeManagement> {
  final List<TuitionRecord> _tuitionRecords = [];
  bool _isAddingRecord = false;
  final TextEditingController _mssvController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isPaid = false;
  String _searchQuery = '';

  final NumberFormat _currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'VND',
      decimalDigits: 0
  );

  @override
  void initState() {
    super.initState();
    _loadSampleData();
  }

  void _loadSampleData() {
    final sampleRecords = [
      TuitionRecord(
        id: 1,
        mssv: '20205123',
        name: 'Nguyễn Văn An',
        amount: 9850000,
        paymentDate: DateTime(2025, 3, 10),
        isPaid: true,
      ),
      TuitionRecord(
        id: 2,
        mssv: '20205124',
        name: 'Trần Thị Bình',
        amount: 9850000,
        paymentDate: DateTime(2025, 3, 12),
        isPaid: true,
      ),
      TuitionRecord(
        id: 3,
        mssv: '20205125',
        name: 'Lê Văn Cường',
        amount: 10450000,
        paymentDate: DateTime(2025, 3, 15),
        isPaid: true,
      ),
      TuitionRecord(
        id: 4,
        mssv: '20205126',
        name: 'Phạm Thị Dung',
        amount: 9850000,
        paymentDate: null,
        isPaid: false,
      ),
      TuitionRecord(
        id: 5,
        mssv: '20205127',
        name: 'Hoàng Văn Đạt',
        amount: 10450000,
        paymentDate: DateTime(2025, 3, 18),
        isPaid: true,
      ),
      TuitionRecord(
        id: 6,
        mssv: '20205128',
        name: 'Đỗ Thị Giang',
        amount: 9850000,
        paymentDate: null,
        isPaid: false,
      ),
      TuitionRecord(
        id: 7,
        mssv: '20205129',
        name: 'Vũ Văn Hùng',
        amount: 10450000,
        paymentDate: DateTime(2025, 3, 5),
        isPaid: true,
      ),
      TuitionRecord(
        id: 8,
        mssv: '20205130',
        name: 'Ngô Thị Lan',
        amount: 9850000,
        paymentDate: DateTime(2025, 3, 20),
        isPaid: true,
      ),
    ];

    setState(() {
      _tuitionRecords.addAll(sampleRecords);
    });
  }

  List<TuitionRecord> get _filteredRecords {
    if (_searchQuery.isEmpty) {
      return _tuitionRecords;
    }

    return _tuitionRecords.where((record) {
      return record.mssv.contains(_searchQuery) ||
          record.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _addNewRecord() {
    if (_mssvController.text.isEmpty ||
        _nameController.text.isEmpty ||
        _amountController.text.isEmpty) {
      _showErrorSnackBar('Vui lòng điền đầy đủ thông tin');
      return;
    }

    try {
      final amount = double.parse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), ''));

      final newRecord = TuitionRecord(
        id: _tuitionRecords.length + 1,
        mssv: _mssvController.text,
        name: _nameController.text,
        amount: amount,
        paymentDate: _isPaid ? _selectedDate : null,
        isPaid: _isPaid,
      );

      setState(() {
        _tuitionRecords.add(newRecord);
        _isAddingRecord = false;
        _mssvController.clear();
        _nameController.clear();
        _amountController.clear();
        _isPaid = false;
        _selectedDate = DateTime.now();
      });

      _showSuccessSnackBar('Thêm bản ghi thành công');
    } catch (e) {
      _showErrorSnackBar('Số tiền không hợp lệ');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _updatePaymentStatus(int index, bool newStatus) {
    setState(() {
      final record = _filteredRecords[index];
      if (newStatus) {
        record.paymentDate = DateTime.now();
      } else {
        record.paymentDate = null;
      }
      record.isPaid = newStatus;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2026),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [

          // Main content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildTopBar(),

                  const SizedBox(height: 20),

                  // Tuition Fee Management content
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left side - Tuition Records Table
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header and add button
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Danh sách đóng học phí',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _isAddingRecord = !_isAddingRecord;
                                      });
                                    },
                                    icon: Icon(_isAddingRecord ? Icons.close : Icons.add),
                                    label: Text(_isAddingRecord ? 'Hủy' : 'Thêm bản ghi'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _isAddingRecord ? Colors.grey : Colors.blue,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 15),

                              // Search field
                              TextField(
                                decoration: InputDecoration(
                                  hintText: 'Tìm kiếm theo MSSV hoặc tên...',
                                  prefixIcon: const Icon(Icons.search),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _searchQuery = value;
                                  });
                                },
                              ),

                              const SizedBox(height: 15),

                              // Add new record form
                              if (_isAddingRecord)
                                Container(
                                  padding: const EdgeInsets.all(15),
                                  margin: const EdgeInsets.only(bottom: 15),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Thêm bản ghi mới',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 15),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: _mssvController,
                                              decoration: const InputDecoration(
                                                labelText: 'MSSV',
                                                border: OutlineInputBorder(),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 15),
                                          Expanded(
                                            flex: 2,
                                            child: TextField(
                                              controller: _nameController,
                                              decoration: const InputDecoration(
                                                labelText: 'Họ và tên',
                                                border: OutlineInputBorder(),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 15),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: _amountController,
                                              decoration: const InputDecoration(
                                                labelText: 'Số tiền học phí (VND)',
                                                border: OutlineInputBorder(),
                                              ),
                                              keyboardType: TextInputType.number,
                                            ),
                                          ),
                                          const SizedBox(width: 15),
                                          Expanded(
                                            child: InkWell(
                                              onTap: () => _selectDate(context),
                                              child: InputDecorator(
                                                decoration: const InputDecoration(
                                                  labelText: 'Ngày đóng',
                                                  border: OutlineInputBorder(),
                                                ),
                                                child: Text(
                                                  DateFormat('dd/MM/yyyy').format(_selectedDate),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 15),
                                      Row(
                                        children: [
                                          Checkbox(
                                            value: _isPaid,
                                            onChanged: (value) {
                                              setState(() {
                                                _isPaid = value ?? false;
                                              });
                                            },
                                          ),
                                          const Text('Đã đóng học phí'),
                                          const Spacer(),
                                          ElevatedButton(
                                            onPressed: _addNewRecord,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
                                            ),
                                            child: const Text('Lưu bản ghi'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                              // Tuition Records Table
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.1),
                                        spreadRadius: 1,
                                        blurRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: SingleChildScrollView(
                                    child: DataTable(
                                      columnSpacing: 40,
                                      columns: const [
                                        DataColumn(label: Text('STT')),
                                        DataColumn(label: Text('MSSV')),
                                        DataColumn(label: Text('Họ và tên')),
                                        DataColumn(label: Text('Học phí')),
                                        DataColumn(label: Text('Ngày đóng')),
                                        DataColumn(label: Text('Trạng thái')),
                                        DataColumn(label: Text('Thao tác')),
                                      ],
                                      rows: List.generate(
                                        _filteredRecords.length,
                                            (index) => DataRow(
                                          cells: [
                                            DataCell(Text('${index + 1}')),
                                            DataCell(Text(_filteredRecords[index].mssv)),
                                            DataCell(Text(_filteredRecords[index].name)),
                                            DataCell(Text(_currencyFormat.format(_filteredRecords[index].amount))),
                                            DataCell(
                                              _filteredRecords[index].paymentDate != null
                                                  ? Text(DateFormat('dd/MM/yyyy').format(_filteredRecords[index].paymentDate!))
                                                  : const Text('-'),
                                            ),
                                            DataCell(
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: _filteredRecords[index].isPaid ? Colors.green.shade100 : Colors.red.shade100,
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  _filteredRecords[index].isPaid ? 'Đã đóng' : 'Chưa đóng',
                                                  style: TextStyle(
                                                    color: _filteredRecords[index].isPaid ? Colors.green.shade800 : Colors.red.shade800,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Switch(
                                                    value: _filteredRecords[index].isPaid,
                                                    onChanged: (bool value) {
                                                      _updatePaymentStatus(index, value);
                                                    },
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.delete, color: Colors.red),
                                                    onPressed: () {
                                                      setState(() {
                                                        _tuitionRecords.remove(_filteredRecords[index]);
                                                      });
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 20),

                        // Right side - Statistics
                        Expanded(
                          child: Column(
                            children: [
                              // Summary stats
                              _buildStatCard(
                                'Tổng số sinh viên',
                                '${_tuitionRecords.length}',
                                Icons.people,
                                Colors.blue,
                              ),

                              const SizedBox(height: 15),

                              _buildStatCard(
                                'Đã đóng học phí',
                                '${_tuitionRecords.where((record) => record.isPaid).length}',
                                Icons.check_circle,
                                Colors.green,
                              ),

                              const SizedBox(height: 15),

                              _buildStatCard(
                                'Chưa đóng học phí',
                                '${_tuitionRecords.where((record) => !record.isPaid).length}',
                                Icons.warning,
                                Colors.orange,
                              ),

                              const SizedBox(height: 15),

                              _buildStatCard(
                                'Tổng học phí đã thu',
                                _currencyFormat.format(_tuitionRecords
                                    .where((record) => record.isPaid)
                                    .fold(0.0, (sum, record) => sum + record.amount)), // Khởi tạo sum là 0.0
                                Icons.attach_money,
                                Colors.green,
                              ),

                              const SizedBox(height: 20),

                              // Charts
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.1),
                                        spreadRadius: 1,
                                        blurRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Thống kê tình trạng đóng học phí',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 15),
                                      Expanded(
                                        child: Stack(
                                          children: [
                                            Center(
                                              child: _buildPieChart(),
                                            ),
                                            const Center(
                                              child: Text(
                                                'Học phí',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          _buildLegendItem('Đã đóng', Colors.green),
                                          const SizedBox(width: 20),
                                          _buildLegendItem('Chưa đóng', Colors.red),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Quản lý đóng học phí',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {},
            ),
            const SizedBox(width: 10),
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.blue.shade100,
              child: const Text('NT'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    final paidCount = _tuitionRecords.where((record) => record.isPaid).length;
    final unpaidCount = _tuitionRecords.where((record) => !record.isPaid).length;

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: [
          PieChartSectionData(
            value: paidCount.toDouble(),
            title: '${(paidCount / _tuitionRecords.length * 100).toStringAsFixed(0)}%',
            color: Colors.green,
            radius: 80,
            titleStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          PieChartSectionData(
            value: unpaidCount.toDouble(),
            title: '${(unpaidCount / _tuitionRecords.length * 100).toStringAsFixed(0)}%',
            color: Colors.red,
            radius: 80,
            titleStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          color: color,
        ),
        const SizedBox(width: 5),
        Text(title),
      ],
    );
  }
}

// Tuition Record model
class TuitionRecord {
  final int id;
  final String mssv;
  final String name;
  final double amount;
  DateTime? paymentDate;
  bool isPaid;

  TuitionRecord({
    required this.id,
    required this.mssv,
    required this.name,
    required this.amount,
    this.paymentDate,
    required this.isPaid,
  });
}