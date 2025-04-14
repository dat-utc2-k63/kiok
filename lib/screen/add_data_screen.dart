import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddTuitionDataScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Hàm thêm thông tin học phí
  Future<void> addTuitionData(BuildContext context) async {
    try {
      print('Adding tuition data...');

      // Thêm dữ liệu học phí vào Firestore
      await _firestore.collection('tuition').doc('S001').set({
        'ho_ten': 'Trần Thị B',
        'lop': 'CNTT K45',
        'khoa_hoc': '2023-2027',
        'so_tien_can_dong': 5000000,
        'phuong_thuc_thanh_toan': 'Chuyển khoản',
        'ngay_thanh_toan': Timestamp.fromDate(DateTime.now()),  // Lưu ngày thanh toán với timestamp
        'trang_thai_thanh_toan': 'Đã đóng',
        'ma_kiosk': 'K001',
      });

      await _firestore.collection('tuition').doc('S002').set({
        'ho_ten': 'Nguyễn Văn A',
        'lop': 'CNTT K46',
        'khoa_hoc': '2023-2027',
        'so_tien_can_dong': 4500000,
        'phuong_thuc_thanh_toan': 'Tiền mặt',
        'ngay_thanh_toan': Timestamp.fromDate(DateTime.now()),  // Lưu ngày thanh toán với timestamp
        'trang_thai_thanh_toan': 'Đã đóng',
        'ma_kiosk': 'K002',
      });

      await _firestore.collection('tuition').doc('S003').set({
        'ho_ten': 'Lê Thị C',
        'lop': 'CNTT K47',
        'khoa_hoc': '2023-2027',
        'so_tien_can_dong': 5500000,
        'phuong_thuc_thanh_toan': 'Chuyển khoản',
        'ngay_thanh_toan': Timestamp.fromDate(DateTime.now()),  // Lưu ngày thanh toán với timestamp
        'trang_thai_thanh_toan': 'Đã đóng',
        'ma_kiosk': 'K003',
      });

      await _firestore.collection('tuition').doc('S004').set({
        'ho_ten': 'Phạm Văn D',
        'lop': 'CNTT K48',
        'khoa_hoc': '2023-2027',
        'so_tien_can_dong': 6000000,
        'phuong_thuc_thanh_toan': 'Tiền mặt',
        'ngay_thanh_toan': Timestamp.fromDate(DateTime.now()),  // Lưu ngày thanh toán với timestamp
        'trang_thai_thanh_toan': 'Chưa đóng',
        'ma_kiosk': 'K004',
      });

      await _firestore.collection('tuition').doc('S005').set({
        'ho_ten': 'Hoàng Thị E',
        'lop': 'CNTT K49',
        'khoa_hoc': '2023-2027',
        'so_tien_can_dong': 5200000,
        'phuong_thuc_thanh_toan': 'Chuyển khoản',
        'ngay_thanh_toan': Timestamp.fromDate(DateTime.now()),  // Lưu ngày thanh toán với timestamp
        'trang_thai_thanh_toan': 'Đã đóng',
        'ma_kiosk': 'K005',
      });

      print('Tuition data added successfully');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã thêm thông tin học phí')),
      );
    } catch (e) {
      print('Error adding tuition data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thêm dữ liệu học phí'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Thêm thông tin học phí vào Firestore',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => addTuitionData(context),
                child: Text('Thêm thông tin học phí'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
