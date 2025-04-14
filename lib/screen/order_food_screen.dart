import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart'; // Thêm Firebase Realtime Database
import 'package:intl/intl.dart';
import 'dart:io';

class OrderFoodScreen extends StatefulWidget {
  @override
  _OrderFoodScreenState createState() => _OrderFoodScreenState();
}

class _OrderFoodScreenState extends State<OrderFoodScreen> {
  String selectedCategory = 'Tất cả';
  Map<MenuItem, int> cartItems = {};
  Map<String, String> _categoryMap = {}; // Cache for category names

  // Thêm tham chiếu đến Firebase Realtime Database
  final DatabaseReference _invoicesRef = FirebaseDatabase.instance.ref('invoices');

  @override
  void initState() {
    super.initState();
    _fetchCategories(); // Fetch categories at initialization
  }

  // Fetch all categories and cache them
  Future<void> _fetchCategories() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('categories').get();
      setState(() {
        for (var doc in snapshot.docs) {
          _categoryMap[doc.id] = (doc.data() as Map<String, dynamic>)['ten_danh_muc'] ?? '';
        }
      });
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Danh mục
          Container(
            width: 150,
            color: Colors.grey[200],
            child: Column(
              children: [
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('categories').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Lỗi: ${snapshot.error}'));
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      // Thêm danh mục "Tất cả" mặc định
                      List<FoodCategory> categories = [
                        FoodCategory('Tất cả', Colors.red),
                      ];

                      // Lấy danh mục từ Firestore
                      categories.addAll(snapshot.data!.docs.map((doc) {
                        return FoodCategory.fromFirestore(doc.data() as Map<String, dynamic>);
                      }).toList());

                      return ListView.builder(
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          return _buildCategoryButton(categories[index]);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Danh sách món ăn
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('dishes').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                // Lấy danh sách món ăn từ Firestore
                List<MenuItem> menuItems = [];
                for (var doc in snapshot.data!.docs) {
                  Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                  // Look up category name from cache
                  String categoryId = data['ma_danh_muc'] ?? '';
                  String categoryName = _categoryMap[categoryId] ?? '';
                  menuItems.add(MenuItem.fromFirestore(doc.id, data, categoryName));
                }

                // Lọc món ăn theo danh mục được chọn
                var filteredItems = menuItems
                    .where((item) => selectedCategory == 'Tất cả' || item.category == selectedCategory)
                    .toList();

                return GridView.builder(
                  padding: EdgeInsets.all(10),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    return _buildMenuItem(filteredItems[index]);
                  },
                );
              },
            ),
          ),

          // Giỏ hàng
          Container(
            width: 300,
            color: Colors.white,
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setCartState) {
                return Column(
                  children: [
                    Expanded(
                      child: cartItems.isEmpty
                          ? Center(child: Text("Giỏ hàng trống"))
                          : ListView.builder(
                        itemCount: cartItems.length,
                        itemBuilder: (context, index) {
                          var item = cartItems.keys.elementAt(index);
                          return _buildCartItem(item, setCartState);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Tổng cộng:', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('${_calculateTotal()}đ', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                          SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () {
                              if (cartItems.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Giỏ hàng trống!')),
                                );
                                return;
                              }
                              _showPaymentDialog(context, setCartState);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              minimumSize: Size(double.infinity, 50),
                            ),
                            child: Text('Xác Nhận'),
                          ),
                        ],
                      ),
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

  // Dialog thanh toán
  void _showPaymentDialog(BuildContext context, StateSetter setCartState) {
    String selectedPaymentMethod = 'Tiền mặt'; // Phương thức mặc định

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Thanh toán'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Số tiền cần thanh toán: ${_calculateTotal()}đ',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  Text('Chọn phương thức thanh toán:'),
                  ListTile(
                    title: Text('Tiền mặt'),
                    leading: Radio<String>(
                      value: 'Tiền mặt',
                      groupValue: selectedPaymentMethod,
                      onChanged: (value) {
                        setDialogState(() {
                          selectedPaymentMethod = value!;
                        });
                      },
                    ),
                  ),
                  ListTile(
                    title: Text('Quét QR'),
                    leading: Radio<String>(
                      value: 'Quét QR',
                      groupValue: selectedPaymentMethod,
                      onChanged: (value) {
                        setDialogState(() {
                          selectedPaymentMethod = value!;
                        });
                      },
                    ),
                  ),
                  if (selectedPaymentMethod == 'Quét QR') ...[
                    SizedBox(height: 10),
                    Center(
                      child: Container(
                        width: 150,
                        height: 150,
                        color: Colors.grey[300],
                        child: Center(child: Text('QR Code Placeholder')),
                        // TODO: Thêm QR code thực tế nếu cần
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Lưu danh sách sản phẩm và tổng tiền tạm thời trước khi xóa giỏ hàng
                Map<MenuItem, int> tempCartItems = Map.from(cartItems);
                int totalAmount = _calculateTotal();

                try {
                  // Step 1: Check if there is enough stock for all items
                  for (var entry in tempCartItems.entries) {
                    MenuItem item = entry.key;
                    int orderedQuantity = entry.value;
                    DocumentSnapshot dishDoc = await FirebaseFirestore.instance
                        .collection('dishes')
                        .doc(item.id)
                        .get();

                    if (!dishDoc.exists) {
                      throw Exception('Món "${item.name}" không tồn tại.');
                    }

                    int currentStock = (dishDoc.data() as Map<String, dynamic>)['so_luong_ton_kho'] ?? 0;
                    if (currentStock < orderedQuantity) {
                      throw Exception(
                          'Không đủ hàng tồn kho cho món "${item.name}". Còn lại: $currentStock, cần: $orderedQuantity.');
                    }
                  }

                  // Step 2: Save the invoice to both Firestore and Realtime Database in a transaction
                  await FirebaseFirestore.instance.runTransaction((transaction) async {
                    // Save the invoice to Firestore
                    DocumentReference invoiceRef =
                    FirebaseFirestore.instance.collection('invoices_canteen').doc();
                    transaction.set(invoiceRef, {
                      'items': tempCartItems.entries.map((entry) => {
                        'ten_san_pham': entry.key.name,
                        'so_luong': entry.value,
                        'gia_ban': entry.key.price,
                      }).toList(),
                      'tong_tien': totalAmount,
                      'phuong_thuc_thanh_toan': selectedPaymentMethod,
                      'ngay_gio_thanh_toan': Timestamp.now(),
                      'ma_kiosk': 'K001',
                    });

                    // Update inventory for each item in Firestore
                    for (var entry in tempCartItems.entries) {
                      MenuItem item = entry.key;
                      int orderedQuantity = entry.value;
                      DocumentReference dishRef =
                      FirebaseFirestore.instance.collection('dishes').doc(item.id);

                      DocumentSnapshot dishDoc = await dishRef.get();
                      if (!dishDoc.exists) {
                        throw Exception('Món "${item.name}" không tồn tại.');
                      }

                      int currentStock =
                          (dishDoc.data() as Map<String, dynamic>)['so_luong_ton_kho'] ?? 0;
                      int newStock = currentStock - orderedQuantity;

                      if (newStock < 0) {
                        throw Exception(
                            'Không đủ hàng tồn kho cho món "${item.name}". Còn lại: $currentStock, cần: $orderedQuantity.');
                      }

                      transaction.update(dishRef, {'so_luong_ton_kho': newStock});
                    }

                    // Save the invoice to Realtime Database
                    String invoiceId = invoiceRef.id;
                    await _invoicesRef.child(invoiceId).set({
                      'id': invoiceId,
                      'total': totalAmount,
                      'date': DateTime.now().toIso8601String(),
                    });

                    return invoiceId;
                  }).then((orderId) {
                    // Step 3: Clear the cart
                    setCartState(() {
                      cartItems.clear();
                    });

                    // Đóng dialog thanh toán
                    Navigator.of(dialogContext).pop();

                    // Hiển thị hóa đơn
                    _showInvoiceDialog(context, orderId, selectedPaymentMethod, tempCartItems, totalAmount);
                  });
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: Text('Xác nhận thanh toán'),
            ),
          ],
        );
      },
    );
  }

  // Dialog hóa đơn
  void _showInvoiceDialog(BuildContext context, String orderId, String paymentMethod,
      Map<MenuItem, int> items, int totalAmount) async {
    // Lấy thông tin ki-ốt từ Firestore
    DocumentSnapshot kioskDoc =
    await FirebaseFirestore.instance.collection('kiosks').doc('K001').get();
    String kioskInfo = kioskDoc.exists
        ? '${kioskDoc['ten_kiosk']}, ${kioskDoc['dia_diem']}'
        : 'Ki-ốt không xác định';

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Center(
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
                  Divider(thickness: 2, color: Colors.grey),
                  _buildInvoiceRow('Mã đơn hàng:', orderId),
                  _buildInvoiceRow(
                      'Ngày giờ:', DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now())),
                  _buildInvoiceRow('Phương thức thanh toán:', paymentMethod),
                  _buildInvoiceRow('Ki-ốt:', kioskInfo),
                  SizedBox(height: 10),
                  Text(
                    'Danh sách sản phẩm:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 5),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text('Sản phẩm', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text('Đơn giá', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text('Số lượng',
                                  style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text('Thành tiền',
                                  style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                            ),
                          ],
                        ),
                        Divider(),
                        ...items.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(flex: 2, child: Text(entry.key.name)),
                                Expanded(flex: 1, child: Text('${entry.key.price}đ')),
                                Expanded(flex: 1, child: Text('x ${entry.value}', textAlign: TextAlign.center)),
                                Expanded(
                                    flex: 1,
                                    child: Text('${entry.key.price * entry.value}đ',
                                        textAlign: TextAlign.right)),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  Divider(thickness: 1, color: Colors.grey),
                  _buildInvoiceRow(
                    'Tổng cộng:',
                    '$totalAmountđ',
                    valueStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  SizedBox(height: 10),
                  Center(
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
              child: Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  // Hàm hỗ trợ để hiển thị một dòng thông tin trong hóa đơn
  Widget _buildInvoiceRow(String label, String value, {TextStyle? valueStyle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14)),
          Text(value, style: valueStyle ?? TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildCategoryButton(FoodCategory category) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            selectedCategory = category.name;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: selectedCategory == category.name ? category.color : Colors.white,
          foregroundColor: selectedCategory == category.name ? Colors.white : Colors.black,
          minimumSize: Size(double.infinity, 50),
        ),
        child: Text(category.name),
      ),
    );
  }

  Widget _buildMenuItem(MenuItem item) {
    return Card(
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: item.image.isNotEmpty
                ? Image.file(
              File(item.image),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.fastfood, size: 50);
              },
            )
                : Icon(Icons.fastfood, size: 50),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  item.name,
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 5),
                Text(
                  '${item.price}đ',
                  style: TextStyle(color: Colors.red),
                ),
                Text(
                  'Còn: ${item.quantity}',
                  style: TextStyle(color: Colors.green),
                ),
                SizedBox(height: 5),
                ElevatedButton(
                  onPressed: () {
                    // Cập nhật giỏ hàng và sử dụng setCartState để cập nhật UI
                    setState(() {
                      if (cartItems.containsKey(item)) {
                        cartItems[item] = cartItems[item]! + 1;
                      } else {
                        cartItems[item] = 1;
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Thêm vào giỏ'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(MenuItem item, StateSetter setCartState) {
    return ListTile(
      leading: item.image.isNotEmpty
          ? Image.file(
        File(item.image),
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Icon(Icons.fastfood, size: 40);
        },
      )
          : Icon(Icons.fastfood, size: 40),
      title: Text(item.name),
      subtitle: Text('${item.price}đ'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.remove_circle, color: Colors.red),
            onPressed: () {
              setCartState(() {
                if (cartItems[item]! > 1) {
                  cartItems[item] = cartItems[item]! - 1;
                } else {
                  cartItems.remove(item);
                }
              });
            },
          ),
          Text('${cartItems[item]}'),
          IconButton(
            icon: Icon(Icons.add_circle, color: Colors.green),
            onPressed: () {
              setCartState(() {
                cartItems[item] = cartItems[item]! + 1;
              });
            },
          ),
        ],
      ),
    );
  }

  int _calculateTotal() {
    return cartItems.entries.fold(0, (total, entry) => total + (entry.key.price * entry.value));
  }
}

class FoodCategory {
  final String name;
  final Color color;

  FoodCategory(this.name, this.color);

  factory FoodCategory.fromFirestore(Map<String, dynamic> data) {
    return FoodCategory(
      data['ten_danh_muc'] ?? '',
      _getColorFromName(data['ten_danh_muc'] ?? ''),
    );
  }

  static Color _getColorFromName(String name) {
    switch (name) {
      case 'Tất cả':
        return Colors.red;
      case 'Ưa thích':
        return Colors.blue;
      case 'Combo':
        return Colors.green;
      case 'Đồ ăn':
        return Colors.orange;
      case 'Đồ uống':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

class MenuItem {
  final String id; // Add ID to identify the dish in Firestore
  final String name;
  final int price;
  final String image;
  final int quantity;
  final String category;

  MenuItem(this.id, this.name, this.price, this.image, this.quantity, this.category);

  factory MenuItem.fromFirestore(String id, Map<String, dynamic> data, String categoryName) {
    return MenuItem(
      id,
      data['ten_san_pham'] ?? '',
      (data['gia_ban'] ?? 0).toInt(),
      data['hinh_mon_an'] ?? '',
      data['so_luong_ton_kho'] ?? 0,
      categoryName, // Use the fetched category name
    );
  }
}