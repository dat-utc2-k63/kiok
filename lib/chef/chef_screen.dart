import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class ChefScreen extends StatefulWidget {
  const ChefScreen({Key? key}) : super(key: key);

  @override
  _ChefScreenState createState() => _ChefScreenState();
}

class _ChefScreenState extends State<ChefScreen> {
  final DatabaseReference _invoicesRef = FirebaseDatabase.instance.ref('invoices');
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'VND', decimalDigits: 0);

  // Biến để lưu trữ dữ liệu chỉnh sửa tồn kho món ăn
  Map<String, TextEditingController> _stockControllers = {};

  @override
  void dispose() {
    // Giải phóng các controller khi màn hình bị hủy
    _stockControllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  // Hàm hỗ trợ để hiển thị một dòng thông tin trong hóa đơn
  Widget _buildInvoiceRow(String label, String value, {TextStyle? valueStyle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(value, style: valueStyle ?? const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  // Hàm hiển thị dialog hóa đơn
  void _showInvoiceDialog(BuildContext context, String invoiceId, int totalAmount, String date) async {
    // Lấy thông tin hóa đơn từ Firestore
    DocumentSnapshot invoiceDoc =
    await FirebaseFirestore.instance.collection('invoices_canteen').doc(invoiceId).get();
    if (!invoiceDoc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy hóa đơn')),
      );
      return;
    }

    final invoiceData = invoiceDoc.data() as Map<String, dynamic>;
    final paymentMethod = invoiceData['phuong_thuc_thanh_toan'] ?? 'Không xác định';
    final items = invoiceData['items'] as List<dynamic>;
    final kioskId = invoiceData['ma_kiosk'] ?? 'K001';

    // Lấy thông tin ki-ốt từ Firestore
    DocumentSnapshot kioskDoc =
    await FirebaseFirestore.instance.collection('kiosks').doc(kioskId).get();
    String kioskInfo = kioskDoc.exists
        ? '${kioskDoc['ten_kiosk']}, ${kioskDoc['dia_diem']}'
        : 'Ki-ốt không xác định';

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Center(
            child: Text(
              'HÓA ĐƠN THANH TOÁN',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ),
          content: SingleChildScrollView(
            child: Container(
              width: 400,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(thickness: 2, color: Colors.grey),
                  _buildInvoiceRow('Mã đơn hàng:', invoiceId),
                  _buildInvoiceRow(
                      'Ngày giờ:', DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.parse(date))),
                  _buildInvoiceRow('Phương thức thanh toán:', paymentMethod),
                  _buildInvoiceRow('Ki-ốt:', kioskInfo),
                  const SizedBox(height: 10),
                  const Text(
                    'Danh sách sản phẩm:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              flex: 2,
                              child: Text('Sản phẩm', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            const Expanded(
                              flex: 1,
                              child: Text('Đơn giá', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            const Expanded(
                              flex: 1,
                              child: Text('Số lượng',
                                  style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                            ),
                            const Expanded(
                              flex: 1,
                              child: Text('Thành tiền',
                                  style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                            ),
                          ],
                        ),
                        const Divider(),
                        ...items.map((item) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(flex: 2, child: Text(item['ten_san_pham'] ?? 'Không tên')),
                                Expanded(flex: 1, child: Text('${item['gia_ban']}đ')),
                                Expanded(
                                    flex: 1, child: Text('x ${item['so_luong']}', textAlign: TextAlign.center)),
                                Expanded(
                                    flex: 1,
                                    child: Text('${item['gia_ban'] * item['so_luong']}đ',
                                        textAlign: TextAlign.right)),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Divider(thickness: 1, color: Colors.grey),
                  _buildInvoiceRow(
                    'Tổng cộng:',
                    '$totalAmountđ',
                    valueStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  const SizedBox(height: 10),
                  const Center(
                    child: Text(
                      'Cảm ơn quý khách!',
                      style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giao Diện Chef'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quản Lý Tồn Kho và Hóa Đơn',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Phần chỉnh sửa tồn kho món ăn (từ Firestore)
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
                            'Chỉnh Sửa Tồn Kho Món Ăn',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Expanded(
                            child: StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance.collection('dishes').snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.hasError) {
                                  return const Center(child: Text('Lỗi tải dữ liệu'));
                                }
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                }

                                final dishes = snapshot.data!.docs;
                                if (dishes.isEmpty) {
                                  return const Center(child: Text('Không có món ăn nào'));
                                }

                                return ListView.builder(
                                  itemCount: dishes.length,
                                  itemBuilder: (context, index) {
                                    final dishDoc = dishes[index];
                                    final dishData = dishDoc.data() as Map<String, dynamic>;
                                    final dishId = dishDoc.id;
                                    final dishName = dishData['ten_san_pham'] ?? 'Không tên';
                                    final stockQuantity = (dishData['so_luong_ton_kho'] ?? 0) as int;
                                    final imagePath = dishData['hinh_mon_an'] ?? '';

                                    // Tạo controller cho từng món ăn
                                    if (!_stockControllers.containsKey(dishId)) {
                                      _stockControllers[dishId] =
                                          TextEditingController(text: stockQuantity.toString());
                                    }

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 5),
                                      child: Row(
                                        children: [
                                          // Hiển thị hình ảnh món ăn
                                          Container(
                                            width: 50,
                                            height: 50,
                                            child: imagePath.isNotEmpty
                                                ? Image.file(
                                              File(imagePath),
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return const Icon(Icons.fastfood, size: 40);
                                              },
                                            )
                                                : const Icon(Icons.fastfood, size: 40),
                                          ),
                                          const SizedBox(width: 10),
                                          // Tên món ăn
                                          Expanded(
                                            child: Text(
                                              dishName,
                                              style: const TextStyle(fontSize: 16),
                                            ),
                                          ),
                                          // Số lượng tồn kho
                                          SizedBox(
                                            width: 100,
                                            child: TextField(
                                              controller: _stockControllers[dishId],
                                              keyboardType: TextInputType.number,
                                              decoration: const InputDecoration(
                                                border: OutlineInputBorder(),
                                                labelText: 'Tồn kho',
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          // Nút cập nhật
                                          ElevatedButton(
                                            onPressed: () async {
                                              final newQuantity =
                                              int.tryParse(_stockControllers[dishId]!.text);
                                              if (newQuantity != null) {
                                                await FirebaseFirestore.instance
                                                    .collection('dishes')
                                                    .doc(dishId)
                                                    .update({'so_luong_ton_kho': newQuantity});
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                      content: Text('Cập nhật tồn kho thành công')),
                                                );
                                              } else {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                      content: Text('Vui lòng nhập số nguyên hợp lệ')),
                                                );
                                              }
                                            },
                                            child: const Text('Cập nhật'),
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
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Phần hiển thị hóa đơn
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
                            'Hóa Đơn Mới',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Expanded(
                            child: StreamBuilder(
                              stream: _invoicesRef.onValue,
                              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                                if (!snapshot.hasData) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                if (snapshot.hasError) {
                                  return const Center(child: Text('Lỗi tải dữ liệu'));
                                }

                                final invoices = Map<String, dynamic>.from(
                                    snapshot.data!.snapshot.value as Map? ?? {});
                                if (invoices.isEmpty) {
                                  return const Center(child: Text('Không có hóa đơn nào'));
                                }

                                final invoiceList = invoices.entries.toList()
                                  ..sort((a, b) => DateTime.parse(b.value['date'])
                                      .compareTo(DateTime.parse(a.value['date'])));

                                return ListView.builder(
                                  itemCount: invoiceList.length,
                                  itemBuilder: (context, index) {
                                    final invoice = invoiceList[index].value;
                                    final invoiceId = invoice['id'];
                                    final total = invoice['total'] as int;
                                    final date = invoice['date'] as String;

                                    return ListTile(
                                      title: Text('Hóa Đơn: $invoiceId'),
                                      subtitle: Text(
                                        'Tổng: ${_currencyFormat.format(total)} • '
                                            'Ngày: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(date))}',
                                      ),
                                      trailing: ElevatedButton(
                                        onPressed: () {
                                          _showInvoiceDialog(context, invoiceId, total, date);
                                        },
                                        child: const Text('Xem Chi Tiết'),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
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
    );
  }
}