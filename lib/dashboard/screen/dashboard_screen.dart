import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../sidebar.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildTopBar(),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              const SizedBox(
                                height: 200, // Fixed height for the revenue display
                                child: RevenueChart(),
                              ),
                              const SizedBox(height: 20),
                              Expanded(
                                child: TransactionsList(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            children: [
                              ActiveKiosks(),
                              const SizedBox(height: 20),
                              Expanded(
                                child: TransactionCategoryChart(),
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
      children: [
        const Text(
          'Tổng Quan',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                // Implement search functionality if needed
              },
            ),
          ),
        ),
      ],
    );
  }
}

// RevenueChart Widget (Numerical Display with Date Filter)
class RevenueChart extends StatefulWidget {
  const RevenueChart({Key? key}) : super(key: key);

  @override
  _RevenueChartState createState() => _RevenueChartState();
}

class _RevenueChartState extends State<RevenueChart> {
  String _selectedPeriod = 'Day'; // Default filter: Day
  final NumberFormat _currencyFormat =
  NumberFormat.currency(locale: 'vi_VN', symbol: 'VND', decimalDigits: 0);

  // Fetch all transactions and group by the selected period
  Future<Map<String, double>> _fetchRevenueData() async {
    List<TransactionRecord> transactions = await _fetchAllTransactions();
    Map<String, double> revenueData = {};

    for (var transaction in transactions) {
      String key;
      if (_selectedPeriod == 'Day') {
        key = DateFormat('dd/MM/yyyy').format(transaction.date);
      } else if (_selectedPeriod == 'Week') {
        DateTime startOfWeek = transaction.date.subtract(Duration(days: transaction.date.weekday - 1));
        key = 'Tuần ${DateFormat('dd/MM/yyyy').format(startOfWeek)}';
      } else {
        key = DateFormat('MM/yyyy').format(transaction.date);
      }

      revenueData[key] = (revenueData[key] ?? 0.0) + transaction.amount;
    }

    return revenueData;
  }

  Future<List<TransactionRecord>> _fetchAllTransactions() async {
    List<TransactionRecord> transactions = [];

    // Fetch Tuition Transactions
    QuerySnapshot tuitionSnapshot = await FirebaseFirestore.instance
        .collection('tuition')
        .orderBy('ngay_thanh_toan', descending: true)
        .get();
    for (var doc in tuitionSnapshot.docs) {
      TuitionRecord record =
      TuitionRecord.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
      if (record.paymentDate != null) {
        transactions.add(TransactionRecord(
          id: record.mssv,
          name: record.name,
          amount: record.amount,
          date: record.paymentDate!,
          type: 'Tuition',
          isPaid: record.isPaid,
        ));
      }
    }

    // Fetch Printing Transactions
    QuerySnapshot printingDocs = await FirebaseFirestore.instance.collection('printing').get();
    for (var doc in printingDocs.docs) {
      QuerySnapshot invoices = await FirebaseFirestore.instance
          .collection('printing')
          .doc(doc.id)
          .collection('print_invoices')
          .get();
      for (var invoice in invoices.docs) {
        Map<String, dynamic> data = invoice.data() as Map<String, dynamic>;
        if (data['ngay_in'] != null) {
          transactions.add(TransactionRecord(
            id: data['ma_tai_lieu'],
            name: 'In tài liệu ${data['ma_tai_lieu']}',
            amount: data['tong_phi']?.toDouble() ?? 0.0,
            date: (data['ngay_in'] as Timestamp).toDate(),
            type: 'Printing',
            isPaid: true,
          ));
        }
      }
    }

    // Fetch Canteen Transactions
    QuerySnapshot canteenSnapshot =
    await FirebaseFirestore.instance.collection('invoices_canteen').get();
    for (var doc in canteenSnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      if (data['ngay_gio_thanh_toan'] != null) {
        transactions.add(TransactionRecord(
          id: doc.id,
          name: 'Mua hàng canteen',
          amount: data['tong_tien']?.toDouble() ?? 0.0,
          date: (data['ngay_gio_thanh_toan'] as Timestamp).toDate(),
          type: 'Canteen',
          isPaid: true,
        ));
      }
    }

    return transactions;
  }

  @override
  Widget build(BuildContext context) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Doanh thu theo thời gian',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              DropdownButton<String>(
                value: _selectedPeriod,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedPeriod = newValue!;
                  });
                },
                items: <String>['Day', 'Week', 'Month']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value == 'Day'
                        ? 'Ngày'
                        : value == 'Week'
                        ? 'Tuần'
                        : 'Tháng'),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Expanded(
            child: FutureBuilder<Map<String, double>>(
              future: _fetchRevenueData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Lỗi tải dữ liệu'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Không có dữ liệu doanh thu'));
                }

                final revenueData = snapshot.data!;
                final List<String> periods = revenueData.keys.toList()
                  ..sort((a, b) {
                    // Sort periods for proper ordering
                    if (_selectedPeriod == 'Day') {
                      return DateFormat('dd/MM/yyyy')
                          .parse(a)
                          .compareTo(DateFormat('dd/MM/yyyy').parse(b));
                    } else if (_selectedPeriod == 'Week') {
                      return DateFormat('dd/MM/yyyy')
                          .parse(a.split(' ')[1])
                          .compareTo(DateFormat('dd/MM/yyyy').parse(b.split(' ')[1]));
                    } else {
                      return DateFormat('MM/yyyy')
                          .parse(a)
                          .compareTo(DateFormat('MM/yyyy').parse(b));
                    }
                  });

                return ListView.builder(
                  itemCount: periods.length,
                  itemBuilder: (context, index) {
                    final period = periods[index];
                    final revenue = revenueData[period]!;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            period,
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            _currencyFormat.format(revenue),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// TransactionsList Widget
class TransactionsList extends StatefulWidget {
  TransactionsList({Key? key}) : super(key: key);

  @override
  _TransactionsListState createState() => _TransactionsListState();
}

class _TransactionsListState extends State<TransactionsList> {
  String _selectedType = 'All'; // Default filter
  final NumberFormat _currencyFormat =
  NumberFormat.currency(locale: 'vi_VN', symbol: 'VND', decimalDigits: 0);

  Future<List<TransactionRecord>> _fetchAllTransactions() async {
    List<TransactionRecord> transactions = [];

    // Fetch Tuition Transactions
    QuerySnapshot tuitionSnapshot = await FirebaseFirestore.instance
        .collection('tuition')
        .orderBy('ngay_thanh_toan', descending: true)
        .get();
    for (var doc in tuitionSnapshot.docs) {
      TuitionRecord record =
      TuitionRecord.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
      if (record.paymentDate != null) {
        transactions.add(TransactionRecord(
          id: record.mssv,
          name: record.name,
          amount: record.amount,
          date: record.paymentDate!,
          type: 'Tuition',
          isPaid: record.isPaid,
        ));
      }
    }

    // Fetch Printing Transactions
    QuerySnapshot printingDocs = await FirebaseFirestore.instance.collection('printing').get();
    for (var doc in printingDocs.docs) {
      QuerySnapshot invoices = await FirebaseFirestore.instance
          .collection('printing')
          .doc(doc.id)
          .collection('print_invoices')
          .get();
      for (var invoice in invoices.docs) {
        Map<String, dynamic> data = invoice.data() as Map<String, dynamic>;
        if (data['ngay_in'] != null) {
          transactions.add(TransactionRecord(
            id: data['ma_tai_lieu'],
            name: 'In tài liệu ${data['ma_tai_lieu']}',
            amount: data['tong_phi']?.toDouble() ?? 0.0,
            date: (data['ngay_in'] as Timestamp).toDate(),
            type: 'Printing',
            isPaid: true,
          ));
        }
      }
    }

    // Fetch Canteen Transactions
    QuerySnapshot canteenSnapshot =
    await FirebaseFirestore.instance.collection('invoices_canteen').get();
    for (var doc in canteenSnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      if (data['ngay_gio_thanh_toan'] != null) {
        transactions.add(TransactionRecord(
          id: doc.id,
          name: 'Mua hàng canteen',
          amount: data['tong_tien']?.toDouble() ?? 0.0,
          date: (data['ngay_gio_thanh_toan'] as Timestamp).toDate(),
          type: 'Canteen',
          isPaid: true,
        ));
      }
    }

    return transactions;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Giao dịch gần đây',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                DropdownButton<String>(
                  value: _selectedType,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedType = newValue!;
                    });
                  },
                  items: <String>['All', 'Tuition', 'Printing', 'Canteen']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value == 'All'
                          ? 'Tất cả'
                          : value == 'Tuition'
                          ? 'Học phí'
                          : value == 'Printing'
                          ? 'In ấn'
                          : 'Canteen'),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<TransactionRecord>>(
              future: _fetchAllTransactions(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Lỗi tải dữ liệu'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Không có giao dịch nào'));
                }

                List<TransactionRecord> transactions = snapshot.data!;
                transactions.sort((a, b) => b.date.compareTo(a.date)); // Sort by date descending
                transactions = transactions.take(5).toList(); // Limit to 5

                // Apply filter
                if (_selectedType != 'All') {
                  transactions =
                      transactions.where((t) => t.type == _selectedType).toList();
                }

                if (transactions.isEmpty) {
                  return const Center(child: Text('Không có giao dịch phù hợp'));
                }

                return ListView.builder(
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: transaction.isPaid ? Colors.green.shade100 : Colors.red.shade100,
                        child: Icon(
                          transaction.isPaid ? Icons.check_circle : Icons.warning,
                          color: transaction.isPaid ? Colors.green.shade800 : Colors.red.shade800,
                        ),
                      ),
                      title: Text(
                        transaction.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${transaction.type == 'Tuition' ? 'MSSV: ${transaction.id}' : transaction.id} • ${DateFormat('dd/MM/yyyy').format(transaction.date)} • ${transaction.type == 'Tuition' ? 'Học phí' : transaction.type == 'Printing' ? 'In ấn' : 'Canteen'}',
                      ),
                      trailing: Text(
                        _currencyFormat.format(transaction.amount),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ActiveKiosks Widget
class ActiveKiosks extends StatelessWidget {
  ActiveKiosks({Key? key}) : super(key: key);

  void _toggleKioskStatus(String kioskId, String currentStatus) {
    String newStatus = currentStatus == 'Hoạt động' ? 'Ngừng hoạt động' : 'Hoạt động';
    FirebaseFirestore.instance.collection('kiosks').doc(kioskId).update({
      'trang_thai_hoat_dong': newStatus,
    }).catchError((error) {
      // Handle error if needed
    });
  }

  @override
  Widget build(BuildContext context) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ki-ốt hoạt động',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('kiosks').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('Lỗi tải dữ liệu'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              List<KioskRecord> kiosks = snapshot.data!.docs.map((doc) {
                return KioskRecord.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
              }).toList();

              if (kiosks.isEmpty) {
                return const Center(child: Text('Không có ki-ốt nào'));
              }

              return ListView.builder(
                shrinkWrap: true,
                itemCount: kiosks.length,
                itemBuilder: (context, index) {
                  final kiosk = kiosks[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: kiosk.isActive ? Colors.green.shade100 : Colors.red.shade100,
                      child: Icon(
                        kiosk.isActive ? Icons.store : Icons.store_outlined,
                        color: kiosk.isActive ? Colors.green.shade800 : Colors.red.shade800,
                      ),
                    ),
                    title: Text(kiosk.name),
                    subtitle: Text(kiosk.location),
                    trailing: Switch(
                      value: kiosk.isActive,
                      onChanged: (value) {
                        _toggleKioskStatus(kiosk.id, kiosk.status);
                      },
                      activeColor: Colors.green,
                      inactiveThumbColor: Colors.grey,
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

// TransactionCategoryChart Widget (Pie Chart with Revenue Distribution)
class TransactionCategoryChart extends StatelessWidget {
  TransactionCategoryChart({Key? key}) : super(key: key);

  Future<List<TransactionRecord>> _fetchAllTransactions() async {
    List<TransactionRecord> transactions = [];

    // Fetch Tuition Transactions
    QuerySnapshot tuitionSnapshot = await FirebaseFirestore.instance
        .collection('tuition')
        .orderBy('ngay_thanh_toan', descending: true)
        .get();
    for (var doc in tuitionSnapshot.docs) {
      TuitionRecord record =
      TuitionRecord.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
      if (record.paymentDate != null) {
        transactions.add(TransactionRecord(
          id: record.mssv,
          name: record.name,
          amount: record.amount,
          date: record.paymentDate!,
          type: 'Tuition',
          isPaid: record.isPaid,
        ));
      }
    }

    // Fetch Printing Transactions
    QuerySnapshot printingDocs = await FirebaseFirestore.instance.collection('printing').get();
    for (var doc in printingDocs.docs) {
      QuerySnapshot invoices = await FirebaseFirestore.instance
          .collection('printing')
          .doc(doc.id)
          .collection('print_invoices')
          .get();
      for (var invoice in invoices.docs) {
        Map<String, dynamic> data = invoice.data() as Map<String, dynamic>;
        if (data['ngay_in'] != null) {
          transactions.add(TransactionRecord(
            id: data['ma_tai_lieu'],
            name: 'In tài liệu ${data['ma_tai_lieu']}',
            amount: data['tong_phi']?.toDouble() ?? 0.0,
            date: (data['ngay_in'] as Timestamp).toDate(),
            type: 'Printing',
            isPaid: true,
          ));
        }
      }
    }

    // Fetch Canteen Transactions
    QuerySnapshot canteenSnapshot =
    await FirebaseFirestore.instance.collection('invoices_canteen').get();
    for (var doc in canteenSnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      if (data['ngay_gio_thanh_toan'] != null) {
        transactions.add(TransactionRecord(
          id: doc.id,
          name: 'Mua hàng canteen',
          amount: data['tong_tien']?.toDouble() ?? 0.0,
          date: (data['ngay_gio_thanh_toan'] as Timestamp).toDate(),
          type: 'Canteen',
          isPaid: true,
        ));
      }
    }

    return transactions;
  }

  @override
  Widget build(BuildContext context) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thống kê theo danh mục',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          Expanded(
            child: FutureBuilder<List<TransactionRecord>>(
              future: _fetchAllTransactions(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Lỗi tải dữ liệu'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Không có giao dịch nào'));
                }

                List<TransactionRecord> transactions = snapshot.data!;
                // Calculate total revenue for each category
                final tuitionRevenue = transactions
                    .where((t) => t.type == 'Tuition')
                    .fold(0.0, (sum, t) => sum + t.amount);
                final printingRevenue = transactions
                    .where((t) => t.type == 'Printing')
                    .fold(0.0, (sum, t) => sum + t.amount);
                final canteenRevenue = transactions
                    .where((t) => t.type == 'Canteen')
                    .fold(0.0, (sum, t) => sum + t.amount);
                final totalRevenue = tuitionRevenue + printingRevenue + canteenRevenue;

                return Column(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          Center(
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 40,
                                sections: [
                                  if (tuitionRevenue > 0)
                                    PieChartSectionData(
                                      value: tuitionRevenue,
                                      title: totalRevenue > 0
                                          ? '${(tuitionRevenue / totalRevenue * 100).toStringAsFixed(0)}%'
                                          : '0%',
                                      color: Colors.blue,
                                      radius: 80,
                                      titleStyle: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  if (printingRevenue > 0)
                                    PieChartSectionData(
                                      value: printingRevenue,
                                      title: totalRevenue > 0
                                          ? '${(printingRevenue / totalRevenue * 100).toStringAsFixed(0)}%'
                                          : '0%',
                                      color: Colors.green,
                                      radius: 80,
                                      titleStyle: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  if (canteenRevenue > 0)
                                    PieChartSectionData(
                                      value: canteenRevenue,
                                      title: totalRevenue > 0
                                          ? '${(canteenRevenue / totalRevenue * 100).toStringAsFixed(0)}%'
                                          : '0%',
                                      color: Colors.orange,
                                      radius: 80,
                                      titleStyle: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const Center(
                            child: Text(
                              'Danh mục',
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
                        if (tuitionRevenue > 0) _buildLegendItem('Học phí', Colors.blue),
                        if (tuitionRevenue > 0) const SizedBox(width: 20),
                        if (printingRevenue > 0) _buildLegendItem('In ấn', Colors.green),
                        if (printingRevenue > 0) const SizedBox(width: 20),
                        if (canteenRevenue > 0) _buildLegendItem('Canteen', Colors.orange),
                      ],
                    ),
                  ],
                );
              },
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

// TuitionRecord Model
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

// KioskRecord Model
class KioskRecord {
  final String id;
  final String name;
  final String location;
  final String status;
  bool get isActive => status == 'Hoạt động';

  KioskRecord({
    required this.id,
    required this.name,
    required this.location,
    required this.status,
  });

  factory KioskRecord.fromFirestore(String id, Map<String, dynamic> data) {
    return KioskRecord(
      id: id,
      name: data['ten_kiosk'] ?? '',
      location: data['dia_diem'] ?? '',
      status: data['trang_thai_hoat_dong'] ?? 'Hoạt động',
    );
  }
}

// TransactionRecord Model
class TransactionRecord {
  final String id;
  final String name;
  final double amount;
  final DateTime date;
  final String type; // "Tuition", "Printing", or "Canteen"
  final bool isPaid;

  TransactionRecord({
    required this.id,
    required this.name,
    required this.amount,
    required this.date,
    required this.type,
    required this.isPaid,
  });
}