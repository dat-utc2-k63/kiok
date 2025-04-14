import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _kioskIdController = TextEditingController();
  final TextEditingController _categoryIdController = TextEditingController();

  // Biến để lưu kết quả tra cứu
  Map<String, dynamic>? kioskData;
  Map<String, dynamic>? categoryData;

  // Hàm tra cứu thông tin ki-ốt
  Future<void> fetchKiosk(String kioskId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('kiosks').doc(kioskId).get();
      if (doc.exists) {
        setState(() {
          kioskData = doc.data() as Map<String, dynamic>;
        });
      } else {
        setState(() {
          kioskData = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không tìm thấy ki-ốt với mã $kioskId')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  // Hàm tra cứu danh mục món ăn
  Future<void> fetchCategory(String categoryId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('canteen')
          .doc('categories')
          .collection('categories')
          .doc(categoryId)
          .get();
      if (doc.exists) {
        setState(() {
          categoryData = doc.data() as Map<String, dynamic>;
        });
      } else {
        setState(() {
          categoryData = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không tìm thấy danh mục với mã $categoryId')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tra cứu thông tin'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tra cứu ki-ốt
              Text(
                'Tra cứu ki-ốt',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: _kioskIdController,
                decoration: InputDecoration(
                  labelText: 'Nhập mã ki-ốt (VD: K001)',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  if (_kioskIdController.text.isNotEmpty) {
                    fetchKiosk(_kioskIdController.text);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Vui lòng nhập mã ki-ốt')),
                    );
                  }
                },
                child: Text('Tra cứu'),
              ),
              SizedBox(height: 20),
              if (kioskData != null) ...[
                Text('Kết quả tra cứu ki-ốt:', style: TextStyle(fontSize: 18)),
                Text('Tên ki-ốt: ${kioskData!['ten_kiosk']}'),
                Text('Địa điểm: ${kioskData!['dia_diem']}'),
                Text('Trạng thái: ${kioskData!['trang_thai_hoat_dong']}'),
              ] else if (kioskData == null && _kioskIdController.text.isNotEmpty) ...[
                Text('Không tìm thấy ki-ốt.'),
              ],

              SizedBox(height: 30),

              // Tra cứu danh mục món ăn
              Text(
                'Tra cứu danh mục món ăn',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: _categoryIdController,
                decoration: InputDecoration(
                  labelText: 'Nhập mã danh mục (VD: C001)',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  if (_categoryIdController.text.isNotEmpty) {
                    fetchCategory(_categoryIdController.text);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Vui lòng nhập mã danh mục')),
                    );
                  }
                },
                child: Text('Tra cứu'),
              ),
              SizedBox(height: 20),
              if (categoryData != null) ...[
                Text('Kết quả tra cứu danh mục:', style: TextStyle(fontSize: 18)),
                Text('Tên danh mục: ${categoryData!['ten_danh_muc']}'),
                Text('Mã ki-ốt: ${categoryData!['ma_kiosk']}'),
              ] else if (categoryData == null && _categoryIdController.text.isNotEmpty) ...[
                Text('Không tìm thấy danh mục.'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}