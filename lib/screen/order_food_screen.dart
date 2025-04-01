import 'package:flutter/material.dart';

class OrderFoodScreen extends StatefulWidget {
  @override
  _OrderFoodScreenState createState() => _OrderFoodScreenState();
}

class _OrderFoodScreenState extends State<OrderFoodScreen> {
  final List<FoodCategory> categories = [
    FoodCategory('Tất cả', Colors.red),
    FoodCategory('Ưa thích', Colors.blue),
    FoodCategory('Combo', Colors.green),
    FoodCategory('Đồ ăn', Colors.orange),
    FoodCategory('Đồ uống', Colors.purple),
  ];

  final List<MenuItem> menuItems = [
    MenuItem('Cơm chiên', 35000, 'assets/com_chien.jpg', 20, 'Đồ ăn'),
    MenuItem('Phở bò', 45000, 'assets/pho_bo.jpg', 15, 'Đồ ăn'),
    MenuItem('Gà rán', 40000, 'assets/ga_ran.jpg', 25, 'Đồ ăn'),
    MenuItem('Trà sữa', 25000, 'assets/tra_sua.jpg', 30, 'Đồ uống'),
    MenuItem('Cà phê', 20000, 'assets/ca_phe.jpg', 40, 'Đồ uống'),
    MenuItem('Nước cam', 22000, 'assets/nuoc_cam.jpg', 35, 'Đồ uống'),
  ];

  String selectedCategory = 'Tất cả';
  Map<MenuItem, int> cartItems = {}; // Lưu sản phẩm + số lượng

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
                  child: ListView.builder(
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      return _buildCategoryButton(categories[index]);
                    },
                  ),
                ),
              ],
            ),
          ),

          // Danh sách món ăn
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(10),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.7,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: menuItems
                  .where((item) =>
              selectedCategory == 'Tất cả' ||
                  item.category == selectedCategory)
                  .length,
              itemBuilder: (context, index) {
                var filteredItems = menuItems
                    .where((item) =>
                selectedCategory == 'Tất cả' ||
                    item.category == selectedCategory)
                    .toList();
                return _buildMenuItem(filteredItems[index]);
              },
            ),
          ),

          // Giỏ hàng
          Container(
            width: 300,
            color: Colors.white,
            child: Column(
              children: [
                Expanded(
                  child: cartItems.isEmpty
                      ? Center(child: Text("Giỏ hàng trống"))
                      : ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      var item = cartItems.keys.elementAt(index);
                      return _buildCartItem(item);
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
                          Text('Tổng cộng:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('${_calculateTotal()}đ',
                              style: TextStyle(color: Colors.red)),
                        ],
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          // TODO: Xác nhận đơn hàng
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          minimumSize: Size(double.infinity, 50),
                        ),
                        child: Text('Xác Nhận'),
                      )
                    ],
                  ),
                )
              ],
            ),
          )
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
          backgroundColor: selectedCategory == category.name
              ? category.color
              : Colors.white,
          foregroundColor:
          selectedCategory == category.name ? Colors.white : Colors.black,
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
            child: Image.asset(
              item.image,
              fit: BoxFit.cover,
            ),
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

  Widget _buildCartItem(MenuItem item) {
    return ListTile(
      title: Text(item.name),
      subtitle: Text('${item.price}đ'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.remove_circle, color: Colors.red),
            onPressed: () {
              setState(() {
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
              setState(() {
                cartItems[item] = cartItems[item]! + 1;
              });
            },
          ),
        ],
      ),
    );
  }

  int _calculateTotal() {
    return cartItems.entries.fold(
        0, (total, entry) => total + (entry.key.price * entry.value));
  }
}

class FoodCategory {
  final String name;
  final Color color;

  FoodCategory(this.name, this.color);
}

class MenuItem {
  final String name;
  final int price;
  final String image;
  final int quantity;
  final String category;

  MenuItem(this.name, this.price, this.image, this.quantity, this.category);
}
