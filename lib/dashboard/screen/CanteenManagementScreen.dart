import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../sidebar.dart';

class CanteenManagementScreen extends StatefulWidget {
  const CanteenManagementScreen({Key? key}) : super(key: key);

  @override
  State<CanteenManagementScreen> createState() => _CanteenManagementScreenState();
}

class _CanteenManagementScreenState extends State<CanteenManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  List<Map<String, dynamic>> _foodItems = [];
  String _selectedCategory = 'Tất cả';
  String _searchQuery = '';
  bool _isLoading = true;

  // Monthly revenue data
  Map<String, double> _monthlyRevenue = {
    'Tháng 1': 30500000,
    'Tháng 2': 38200000,
    'Tháng 3': 45000000,
  };

  // Today's revenue and monthly revenue
  double _todayRevenue = 2500000;
  double _monthRevenue = 45000000;

  // Top selling items
  List<Map<String, dynamic>> _topSellingItems = [
    {'name': 'Trà sữa', 'sales': 250, 'percentage': 0.9},
    {'name': 'Cơm gà', 'sales': 180, 'percentage': 0.7},
    {'name': 'Bánh mì', 'sales': 120, 'percentage': 0.5},
  ];

  @override
  void initState() {
    super.initState();
    _fetchFoodItems();
    _fetchAnalytics();
  }

  // Fetch food items from Firestore
  Future<void> _fetchFoodItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fix: Correct Firestore path by using a single collection name
      QuerySnapshot dishesSnapshot = await _firestore.collection('dishes').get();
      List<Map<String, dynamic>> items = [];

      for (var doc in dishesSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Fetch category name
        String categoryId = data['ma_danh_muc'] ?? '';
        String categoryName = '';
        if (categoryId.isNotEmpty) {
          // Fix: Correct Firestore path for categories
          DocumentSnapshot categoryDoc = await _firestore.collection('categories').doc(categoryId).get();
          if (categoryDoc.exists) {
            categoryName = (categoryDoc.data() as Map<String, dynamic>)['ten_danh_muc'] ?? '';
          }
        }

        items.add({
          'id': doc.id,
          'name': data['ten_san_pham'] ?? '',
          'price': data['gia_ban'] ?? 0,
          'inStock': data['so_luong_ton_kho'] ?? 0,
          'imageUrl': data['hinh_mon_an'] ?? '',
          'category': categoryName,
          'categoryId': categoryId,
        });
      }

      setState(() {
        _foodItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Lỗi khi tải dữ liệu: $e');
    }
  }

  // Fetch analytics data
  Future<void> _fetchAnalytics() async {
    try {
      // Fix: Correct Firestore path for invoices
      QuerySnapshot invoicesSnapshot = await _firestore.collection('invoices').get();
      // Implement actual calculation logic here if needed
    } catch (e) {
      _showErrorDialog('Lỗi khi tải dữ liệu phân tích: $e');
    }
  }

  // Filter food items based on category and search query
  List<Map<String, dynamic>> _getFilteredFoodItems() {
    return _foodItems.where((item) {
      bool categoryMatch = _selectedCategory == 'Tất cả' || item['category'] == _selectedCategory;
      bool searchMatch = _searchQuery.isEmpty ||
          item['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      return categoryMatch && searchMatch;
    }).toList();
  }

  // Show dialog for adding/editing food item
  Future<void> _showFoodItemDialog({Map<String, dynamic>? existingItem}) async {
    final TextEditingController nameController = TextEditingController(text: existingItem?['name'] ?? '');
    final TextEditingController priceController = TextEditingController(
        text: existingItem != null ? existingItem['price'].toString() : '');
    final TextEditingController stockController = TextEditingController(
        text: existingItem != null ? existingItem['inStock'].toString() : '');

    String categoryId = existingItem?['categoryId'] ?? '';
    String imagePath = existingItem?['imageUrl'] ?? ''; // Now a local file path
    File? imageFile;

    // Fetch all categories
    List<Map<String, dynamic>> categories = [];
    try {
      QuerySnapshot categoriesSnapshot = await _firestore.collection('categories').get();
      for (var doc in categoriesSnapshot.docs) {
        categories.add({
          'id': doc.id,
          'name': (doc.data() as Map<String, dynamic>)['ten_danh_muc'] ?? '',
        });
      }
      if (categoryId.isEmpty && categories.isNotEmpty) {
        categoryId = categories[0]['id'];
      }
    } catch (e) {
      _showErrorDialog('Lỗi khi tải danh mục: $e');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(existingItem == null ? 'Thêm món ăn mới' : 'Chỉnh sửa món ăn'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: () async {
                        final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                        if (pickedFile != null) {
                          setState(() {
                            imageFile = File(pickedFile.path);
                          });
                        }
                      },
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                          image: imageFile != null
                              ? DecorationImage(image: FileImage(imageFile!), fit: BoxFit.cover)
                              : (imagePath.isNotEmpty
                              ? DecorationImage(image: FileImage(File(imagePath)), fit: BoxFit.cover)
                              : null),
                        ),
                        child: imageFile == null && imagePath.isEmpty
                            ? const Icon(Icons.add_a_photo, size: 40, color: Colors.grey)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên món ăn',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: priceController,
                    decoration: const InputDecoration(
                      labelText: 'Giá (VND)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: stockController,
                    decoration: const InputDecoration(
                      labelText: 'Số lượng tồn kho',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: categoryId,
                    decoration: const InputDecoration(
                      labelText: 'Danh mục',
                      border: OutlineInputBorder(),
                    ),
                    items: categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category['id'],
                        child: Text(category['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        categoryId = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.trim().isEmpty) {
                    _showErrorDialog('Vui lòng nhập tên món ăn');
                    return;
                  }

                  int? price = int.tryParse(priceController.text);
                  if (price == null || price <= 0) {
                    _showErrorDialog('Vui lòng nhập giá hợp lệ');
                    return;
                  }

                  int? stock = int.tryParse(stockController.text);
                  if (stock == null || stock < 0) {
                    _showErrorDialog('Vui lòng nhập số lượng tồn kho hợp lệ');
                    return;
                  }

                  if (categoryId.isEmpty) {
                    _showErrorDialog('Vui lòng chọn danh mục');
                    return;
                  }

                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(child: CircularProgressIndicator()),
                  );

                  try {
                    String finalImagePath = imagePath;
                    if (imageFile != null) {
                      // Save the image locally using path_provider
                      final directory = await getApplicationDocumentsDirectory();
                      final imageDir = Directory('${directory.path}/dish_images');
                      if (!await imageDir.exists()) {
                        await imageDir.create(recursive: true);
                      }
                      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${nameController.text}.jpg';
                      final imagePath = '${imageDir.path}/$fileName';
                      await imageFile!.copy(imagePath);
                      finalImagePath = imagePath;
                    }

                    Map<String, dynamic> dishData = {
                      'ten_san_pham': nameController.text.trim(),
                      'gia_ban': price,
                      'so_luong_ton_kho': stock,
                      'ma_danh_muc': categoryId,
                      'hinh_mon_an': finalImagePath, // Store local path instead of URL
                    };

                    if (existingItem == null) {
                      await _firestore.collection('dishes').add(dishData);
                    } else {
                      await _firestore.collection('dishes').doc(existingItem['id']).update(dishData);
                    }

                    await _fetchFoodItems();

                    Navigator.pop(context); // Close loading dialog
                    Navigator.pop(context); // Close edit/add dialog

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(existingItem == null ? 'Thêm món ăn thành công' : 'Cập nhật món ăn thành công'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    Navigator.pop(context);
                    _showErrorDialog('Lỗi: $e');
                  }
                },
                child: Text(existingItem == null ? 'Thêm' : 'Cập nhật'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Show dialog for adding new category
  Future<void> _showAddCategoryDialog() async {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm danh mục mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Tên danh mục',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                _showErrorDialog('Vui lòng nhập tên danh mục');
                return;
              }

              try {
                String newCategoryId = 'C${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                await _firestore.collection('categories').doc(newCategoryId).set({
                  'ten_danh_muc': nameController.text.trim(),
                });

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Thêm danh mục thành công'),
                    backgroundColor: Colors.green,
                  ),
                );

                await _fetchFoodItems();
              } catch (e) {
                _showErrorDialog('Lỗi: $e');
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  // Show confirmation dialog for deleting a food item
  Future<void> _showDeleteConfirmationDialog(Map<String, dynamic> item) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa món "${item['name']}" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await _firestore.collection('dishes').doc(item['id']).delete();
                Navigator.pop(context);
                await _fetchFoodItems();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Xóa món ăn thành công'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                _showErrorDialog('Lỗi: $e');
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Show update stock dialog
  Future<void> _showUpdateStockDialog(Map<String, dynamic> item) async {
    final TextEditingController stockController = TextEditingController(
        text: item['inStock'].toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cập nhật tồn kho'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Món: ${item['name']}'),
            const SizedBox(height: 15),
            TextField(
              controller: stockController,
              decoration: const InputDecoration(
                labelText: 'Số lượng tồn kho',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              int? stock = int.tryParse(stockController.text);
              if (stock == null || stock < 0) {
                _showErrorDialog('Vui lòng nhập số lượng tồn kho hợp lệ');
                return;
              }

              try {
                await _firestore.collection('dishes').doc(item['id']).update({
                  'so_luong_ton_kho': stock,
                });
                Navigator.pop(context);
                await _fetchFoodItems();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cập nhật tồn kho thành công'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                _showErrorDialog('Lỗi: $e');
              }
            },
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    );
  }

  // Show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lỗi'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredFoodItems = _getFilteredFoodItems();

    return Scaffold(
      body: Row(
        children: [
          // const Sidebar(),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Danh sách món ăn',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: _showAddCategoryDialog,
                                        icon: const Icon(Icons.category),
                                        label: const Text('Thêm danh mục'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      ElevatedButton.icon(
                                        onPressed: () => _showFoodItemDialog(),
                                        icon: const Icon(Icons.add),
                                        label: const Text('Thêm món'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              FutureBuilder<QuerySnapshot>(
                                future: _firestore.collection('categories').get(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const SizedBox(
                                      height: 40,
                                      child: Center(child: LinearProgressIndicator()),
                                    );
                                  }

                                  List<Widget> categoryChips = [
                                    _buildCategoryChip('Tất cả', _selectedCategory == 'Tất cả', (category) {
                                      setState(() {
                                        _selectedCategory = category;
                                      });
                                    }),
                                  ];

                                  if (snapshot.hasData) {
                                    for (var doc in snapshot.data!.docs) {
                                      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                                      String categoryName = data['ten_danh_muc'] ?? '';
                                      categoryChips.add(
                                        _buildCategoryChip(
                                          categoryName,
                                          _selectedCategory == categoryName,
                                              (category) {
                                            setState(() {
                                              _selectedCategory = category;
                                            });
                                          },
                                        ),
                                      );
                                    }
                                  }

                                  return SizedBox(
                                    height: 40,
                                    child: ListView(
                                      scrollDirection: Axis.horizontal,
                                      children: categoryChips,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 15),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      onChanged: (value) {
                                        setState(() {
                                          _searchQuery = value;
                                        });
                                      },
                                      decoration: InputDecoration(
                                        hintText: 'Tìm kiếm món ăn...',
                                        prefixIcon: const Icon(Icons.search),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide.none,
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey.shade100,
                                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.filter_list),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
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
                                  child: _isLoading
                                      ? const Center(child: CircularProgressIndicator())
                                      : filteredFoodItems.isEmpty
                                      ? const Center(child: Text('Không tìm thấy món ăn nào'))
                                      : ListView.separated(
                                    padding: const EdgeInsets.all(10),
                                    itemCount: filteredFoodItems.length,
                                    separatorBuilder: (context, index) => const Divider(),
                                    itemBuilder: (context, index) {
                                      final item = filteredFoodItems[index];
                                      return ListTile(
                                        leading: Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: item['imageUrl'].isNotEmpty
                                                ? null
                                                : Colors.orange.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                            image: item['imageUrl'].isNotEmpty
                                                ? DecorationImage(
                                              image: FileImage(File(item['imageUrl'])),
                                              fit: BoxFit.cover,
                                            )
                                                : null,
                                          ),
                                          child: item['imageUrl'].isEmpty
                                              ? const Icon(Icons.fastfood, color: Colors.orange)
                                              : null,
                                        ),
                                        title: Text(item['name']),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item['category'],
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              '${item['price']} VND',
                                              style: const TextStyle(
                                                color: Colors.red,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                              decoration: BoxDecoration(
                                                color: item['inStock'] > 0
                                                    ? Colors.green.withOpacity(0.1)
                                                    : Colors.red.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                'Tồn kho: ${item['inStock']}',
                                                style: TextStyle(
                                                  color: item['inStock'] > 0 ? Colors.green : Colors.red,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            PopupMenuButton(
                                              icon: const Icon(Icons.more_vert),
                                              onSelected: (value) {
                                                if (value == 'edit') {
                                                  _showFoodItemDialog(existingItem: item);
                                                } else if (value == 'stock') {
                                                  _showUpdateStockDialog(item);
                                                } else if (value == 'delete') {
                                                  _showDeleteConfirmationDialog(item);
                                                }
                                              },
                                              itemBuilder: (context) => [
                                                const PopupMenuItem(
                                                  value: 'edit',
                                                  child: Text('Chỉnh sửa'),
                                                ),
                                                const PopupMenuItem(
                                                  value: 'stock',
                                                  child: Text('Cập nhật tồn kho'),
                                                ),
                                                const PopupMenuItem(
                                                  value: 'delete',
                                                  child: Text('Xóa'),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      'Doanh thu hôm nay',
                                      '${_todayRevenue.toStringAsFixed(0)} VND',
                                      Icons.payments,
                                      Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      'Doanh thu tháng',
                                      '${_monthRevenue.toStringAsFixed(0)} VND',
                                      Icons.calendar_month,
                                      Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
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
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Doanh thu theo tháng',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          DropdownButton<String>(
                                            value: 'Năm 2025',
                                            items: const [
                                              DropdownMenuItem<String>(
                                                value: 'Năm 2025',
                                                child: Text('Năm 2025'),
                                              ),
                                              DropdownMenuItem<String>(
                                                value: 'Năm 2024',
                                                child: Text('Năm 2024'),
                                              ),
                                            ],
                                            onChanged: (value) {},
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 15),
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: _monthlyRevenue.entries.map((entry) {
                                            return _buildRevenueBar(
                                              entry.key,
                                              entry.value / 50000000,
                                              '${(entry.value / 1000000).toStringAsFixed(1)}M',
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Container(
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
                                      'Món ăn bán chạy',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                    ..._topSellingItems.map((item) => Column(
                                      children: [
                                        _buildTopItem(
                                          item['name'],
                                          '${item['sales']} đơn',
                                          item['percentage'],
                                        ),
                                        if (_topSellingItems.last != item) const SizedBox(height: 10),
                                      ],
                                    )),
                                  ],
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

  Widget _buildCategoryChip(String label, bool isSelected, Function(String) onTap) {
    return GestureDetector(
      onTap: () => onTap(label),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        child: Chip(
          label: Text(label),
          backgroundColor: isSelected ? Colors.blue : Colors.grey.shade100,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueBar(String month, double value, String amount) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            month,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              FractionallySizedBox(
                widthFactor: value,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          amount,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildTopItem(String name, String sales, double value) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.fastfood, color: Colors.orange),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                sales,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 5),
              Stack(
                children: [
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: value,
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildTopBar() {
    return Row(
      children: [
        const Text(
          'Quản Lý Căn Tin',
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
            ),
          ),
        ),
      ],
    );
  }
}