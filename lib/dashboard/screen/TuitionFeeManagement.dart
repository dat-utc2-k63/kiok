import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class TuitionFeeManagement extends StatefulWidget {
  const TuitionFeeManagement({Key? key}) : super(key: key);

  @override
  _TuitionFeeManagementState createState() => _TuitionFeeManagementState();
}

class _TuitionFeeManagementState extends State<TuitionFeeManagement> {
  bool _isAddingRecord = false;
  final TextEditingController _mssvController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _classController = TextEditingController();
  final TextEditingController _courseController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isPaid = false;
  String _selectedPaymentMethod = 'Tiền mặt';
  String _searchQuery = '';

  final NumberFormat _currencyFormat =
  NumberFormat.currency(locale: 'vi_VN', symbol: 'VND', decimalDigits: 0);

  @override
  void dispose() {
    _mssvController.dispose();
    _nameController.dispose();
    _classController.dispose();
    _courseController.dispose();
    _amountController.dispose();
    super.dispose();
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

  void _addNewRecord() {
    if (_mssvController.text.isEmpty ||
        _nameController.text.isEmpty ||
        _classController.text.isEmpty ||
        _courseController.text.isEmpty ||
        _amountController.text.isEmpty) {
      _showErrorSnackBar('Vui lòng điền đầy đủ thông tin');
      return;
    }

    try {
      final amount = double.parse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), ''));

      FirebaseFirestore.instance.collection('tuition').add({
        'mssv': _mssvController.text,
        'ho_ten': _nameController.text,
        'lop': _classController.text,
        'khoa_hoc': _courseController.text,
        'so_tien.can_dong': amount,
        'phuong_thuc_thanh_toan': _isPaid ? _selectedPaymentMethod : null,
        'ngay_thanh_toan': _isPaid ? Timestamp.fromDate(_selectedDate) : null,
        'trang_thai_thanh_toan': _isPaid ? 'Đã đóng' : 'Chưa đóng',
        'ma_kiosk': 'K001',
      }).then((_) {
        setState(() {
          _isAddingRecord = false;
          _mssvController.clear();
          _nameController.clear();
          _classController.clear();
          _courseController.clear();
          _amountController.clear();
          _isPaid = false;
          _selectedDate = DateTime.now();
          _selectedPaymentMethod = 'Tiền mặt';
        });
        _showSuccessSnackBar('Thêm bản ghi thành công');
      }).catchError((error) {
        _showErrorSnackBar('Lỗi khi thêm bản ghi: $error');
      });
    } catch (e) {
      _showErrorSnackBar('Số tiền không hợp lệ');
    }
  }

  void _updatePaymentStatus(TuitionRecord record, bool newStatus) {
    FirebaseFirestore.instance.collection('tuition').doc(record.id).update({
      'trang_thai_thanh_toan': newStatus ? 'Đã đóng' : 'Chưa đóng',
      'ngay_thanh_toan': newStatus ? Timestamp.now() : null,
      'phuong_thuc_thanh_toan': newStatus ? 'Tiền mặt' : null,
    }).then((_) {
      _showSuccessSnackBar('Cập nhật trạng thái thành công');
    }).catchError((error) {
      _showErrorSnackBar('Lỗi khi cập nhật trạng thái: $error');
    });
  }

  void _deleteRecord(TuitionRecord record) {
    FirebaseFirestore.instance.collection('tuition').doc(record.id).delete().then((_) {
      _showSuccessSnackBar('Xóa bản ghi thành công');
    }).catchError((error) {
      _showErrorSnackBar('Lỗi khi xóa bản ghi: $error');
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
                                              controller: _classController,
                                              decoration: const InputDecoration(
                                                labelText: 'Lớp',
                                                border: OutlineInputBorder(),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 15),
                                          Expanded(
                                            child: TextField(
                                              controller: _courseController,
                                              decoration: const InputDecoration(
                                                labelText: 'Khóa học (VD: 2023-2027)',
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
                                          if (_isPaid) ...[
                                            const SizedBox(width: 15),
                                            DropdownButton<String>(
                                              value: _selectedPaymentMethod,
                                              onChanged: (String? newValue) {
                                                setState(() {
                                                  _selectedPaymentMethod = newValue!;
                                                });
                                              },
                                              items: <String>['Tiền mặt', 'Chuyển khoản', 'Quét QR']
                                                  .map<DropdownMenuItem<String>>((String value) {
                                                return DropdownMenuItem<String>(
                                                  value: value,
                                                  child: Text(value),
                                                );
                                              }).toList(),
                                            ),
                                          ],
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
                                    scrollDirection: Axis.horizontal, // Allow horizontal scrolling
                                    child: StreamBuilder<QuerySnapshot>(
                                      stream: FirebaseFirestore.instance.collection('tuition').snapshots(),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasError) {
                                          return Center(child: Text('Lỗi: ${snapshot.error}'));
                                        }
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return const Center(child: CircularProgressIndicator());
                                        }

                                        // Map Firestore documents to TuitionRecord objects
                                        List<TuitionRecord> tuitionRecords =
                                        snapshot.data!.docs.map((doc) {
                                          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                                          return TuitionRecord.fromFirestore(doc.id, data);
                                        }).toList();

                                        // Filter records based on search query
                                        List<TuitionRecord> filteredRecords = tuitionRecords.where((record) {
                                          return record.mssv.contains(_searchQuery) ||
                                              record.name.toLowerCase().contains(_searchQuery.toLowerCase());
                                        }).toList();

                                        return DataTable(
                                          columnSpacing: 20, // Reduced spacing to fit more content
                                          columns: const [
                                            DataColumn(
                                              label: Text(
                                                'STT',
                                                style: TextStyle(fontSize: 14),
                                              ),
                                            ),
                                            DataColumn(
                                              label: Text(
                                                'MSSV',
                                                style: TextStyle(fontSize: 14),
                                              ),
                                            ),
                                            DataColumn(
                                              label: Text(
                                                'Họ và tên',
                                                style: TextStyle(fontSize: 14),
                                              ),
                                            ),
                                            DataColumn(
                                              label: Text(
                                                'Lớp',
                                                style: TextStyle(fontSize: 14),
                                              ),
                                            ),
                                            DataColumn(
                                              label: Text(
                                                'Khóa học',
                                                style: TextStyle(fontSize: 14),
                                              ),
                                            ),
                                            DataColumn(
                                              label: Text(
                                                'Học phí',
                                                style: TextStyle(fontSize: 14),
                                              ),
                                            ),
                                            DataColumn(
                                              label: Text(
                                                'Ngày đóng',
                                                style: TextStyle(fontSize: 14),
                                              ),
                                            ),
                                            DataColumn(
                                              label: Text(
                                                'Trạng thái',
                                                style: TextStyle(fontSize: 14),
                                              ),
                                            ),
                                            DataColumn(
                                              label: Text(
                                                'Thao tác',
                                                style: TextStyle(fontSize: 14),
                                              ),
                                            ),
                                          ],
                                          rows: List.generate(
                                            filteredRecords.length,
                                                (index) => DataRow(
                                              cells: [
                                                DataCell(
                                                  Text(
                                                    '${index + 1}',
                                                    style: const TextStyle(fontSize: 12),
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    filteredRecords[index].mssv,
                                                    style: const TextStyle(fontSize: 12),
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    filteredRecords[index].name,
                                                    style: const TextStyle(fontSize: 12),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    filteredRecords[index].className,
                                                    style: const TextStyle(fontSize: 12),
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    filteredRecords[index].course,
                                                    style: const TextStyle(fontSize: 12),
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    _currencyFormat.format(filteredRecords[index].amount),
                                                    style: const TextStyle(fontSize: 12),
                                                  ),
                                                ),
                                                DataCell(
                                                  filteredRecords[index].paymentDate != null
                                                      ? Text(
                                                    DateFormat('dd/MM/yyyy')
                                                        .format(filteredRecords[index].paymentDate!),
                                                    style: const TextStyle(fontSize: 12),
                                                  )
                                                      : const Text(
                                                    '-',
                                                    style: TextStyle(fontSize: 12),
                                                  ),
                                                ),
                                                DataCell(
                                                  Container(
                                                    padding:
                                                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: filteredRecords[index].isPaid
                                                          ? Colors.green.shade100
                                                          : Colors.red.shade100,
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Text(
                                                      filteredRecords[index].isPaid ? 'Đã đóng' : 'Chưa đóng',
                                                      style: TextStyle(
                                                        color: filteredRecords[index].isPaid
                                                            ? Colors.green.shade800
                                                            : Colors.red.shade800,
                                                        fontSize: 10,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                DataCell(
                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Switch(
                                                        value: filteredRecords[index].isPaid,
                                                        onChanged: (bool value) {
                                                          _updatePaymentStatus(filteredRecords[index], value);
                                                        },
                                                        activeColor: Colors.green,
                                                        inactiveThumbColor: Colors.grey,
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons.delete,
                                                          color: Colors.red,
                                                          size: 20,
                                                        ),
                                                        onPressed: () {
                                                          _deleteRecord(filteredRecords[index]);
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
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
                          child: SingleChildScrollView(
                            child: StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance.collection('tuition').snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.hasError) {
                                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                                }
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                }

                                // Map Firestore documents to TuitionRecord objects for statistics
                                List<TuitionRecord> tuitionRecords = snapshot.data!.docs.map((doc) {
                                  Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                                  return TuitionRecord.fromFirestore(doc.id, data);
                                }).toList();

                                return Column(
                                  children: [
                                    // Summary stats
                                    _buildStatCard(
                                      'Tổng số sinh viên',
                                      '${tuitionRecords.length}',
                                      Icons.people,
                                      Colors.blue,
                                    ),
                                    const SizedBox(height: 15),
                                    _buildStatCard(
                                      'Đã đóng học phí',
                                      '${tuitionRecords.where((record) => record.isPaid).length}',
                                      Icons.check_circle,
                                      Colors.green,
                                    ),
                                    const SizedBox(height: 15),
                                    _buildStatCard(
                                      'Chưa đóng học phí',
                                      '${tuitionRecords.where((record) => !record.isPaid).length}',
                                      Icons.warning,
                                      Colors.orange,
                                    ),
                                    const SizedBox(height: 15),
                                    _buildStatCard(
                                      'Tổng học phí đã thu',
                                      _currencyFormat.format(tuitionRecords
                                          .where((record) => record.isPaid)
                                          .fold(0.0, (sum, record) => sum + record.amount)),
                                      Icons.attach_money,
                                      Colors.green,
                                    ),
                                    const SizedBox(height: 20),
                                    // Charts
                                    Container(
                                      height: 300, // Fixed height for the chart to prevent overflow
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
                                                  child: _buildPieChart(tuitionRecords),
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
                                  ],
                                );
                              },
                            ),
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

  Widget _buildPieChart(List<TuitionRecord> records) {
    final paidCount = records.where((record) => record.isPaid).length;
    final unpaidCount = records.where((record) => !record.isPaid).length;

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: [
          PieChartSectionData(
            value: paidCount.toDouble(),
            title: records.isNotEmpty
                ? '${(paidCount / records.length * 100).toStringAsFixed(0)}%'
                : '0%',
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
            title: records.isNotEmpty
                ? '${(unpaidCount / records.length * 100).toStringAsFixed(0)}%'
                : '0%',
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
  final String id;
  final String mssv;
  final String name;
  final String className;
  final String course;
  final double amount;
  DateTime? paymentDate;
  bool isPaid;
  final String? paymentMethod;
  final String kioskId;

  TuitionRecord({
    required this.id,
    required this.mssv,
    required this.name,
    required this.className,
    required this.course,
    required this.amount,
    this.paymentDate,
    required this.isPaid,
    this.paymentMethod,
    required this.kioskId,
  });

  factory TuitionRecord.fromFirestore(String id, Map<String, dynamic> data) {
    return TuitionRecord(
      id: id,
      mssv: data['mssv'] ?? '',
      name: data['ho_ten'] ?? '',
      className: data['lop'] ?? '',
      course: data['khoa_hoc'] ?? '',
      amount: (data['so_tien.can_dong'] ?? 0).toDouble(),
      paymentDate: data['ngay_thanh_toan'] != null
          ? (data['ngay_thanh_toan'] as Timestamp).toDate()
          : null,
      isPaid: data['trang_thai_thanh_toan'] == 'Đã đóng',
      paymentMethod: data['phuong_thuc_thanh_toan'],
      kioskId: data['ma_kiosk'] ?? 'K001',
    );
  }
}