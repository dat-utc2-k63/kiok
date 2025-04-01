import 'package:flutter/material.dart';

class TuitionPaymentScreen extends StatefulWidget {
  @override
  _TuitionPaymentScreenState createState() => _TuitionPaymentScreenState();
}

class _TuitionPaymentScreenState extends State<TuitionPaymentScreen> {
  final TextEditingController _studentIdController = TextEditingController();
  bool _isStudentFound = false;
  bool _isPaymentComplete = false;

  // Dữ liệu sinh viên mẫu
  Map<String, dynamic> _studentData = {
    'name': '',
    'class': '',
    'course': '',
    'tuitionAmount': 0,
    'dueDate': '',
  };

  @override
  void dispose() {
    _studentIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Đóng Học Phí', style: TextStyle(fontSize: 20)),
        backgroundColor: Colors.amber[200],
        centerTitle: true,
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Icon(Icons.school, size: 48, color: Colors.blue[700]),
                    SizedBox(height: 10),
                    Text(
                      'Thanh Toán Học Phí',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Vui lòng nhập mã số sinh viên để tiếp tục',
                      style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Form nhập mã số sinh viên
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mã số sinh viên:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _studentIdController,
                            decoration: InputDecoration(
                              hintText: 'Nhập mã số sinh viên',
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(),
                              fillColor: Colors.white,
                              filled: true,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: _lookupStudent,
                          icon: Icon(Icons.search),
                          label: Text('Tra Cứu'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Hiển thị thông tin sinh viên
              if (_isStudentFound) ...[
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.blue[700],
                            radius: 24,
                            child: Icon(Icons.person, color: Colors.white, size: 30),
                          ),
                          SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _studentData['name'],
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'MSSV: ${_studentIdController.text}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Divider(),
                      SizedBox(height: 8),
                      _buildInfoRow('Lớp:', _studentData['class']),
                      SizedBox(height: 8),
                      _buildInfoRow('Khóa:', _studentData['course']),
                      SizedBox(height: 8),
                      _buildInfoRow('Ngày đóng:', _studentData['dueDate']),
                      SizedBox(height: 8),
                      _buildInfoRow(
                        'Học phí:',
                        '${_formatCurrency(_studentData['tuitionAmount'])} VNĐ',
                        isHighlighted: true,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),

                // Phần thanh toán
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber[300]!),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Thanh Toán Qua Mã QR',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Center(
                            child: Icon(Icons.qr_code, size: 160),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Mã QR có hiệu lực trong vòng 15 phút',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 16),
                      _isPaymentComplete
                          ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'Thanh toán thành công',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                          : ElevatedButton.icon(
                        icon: Icon(Icons.payment),
                        label: Text('Xác Nhận Đã Thanh Toán'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 24,
                          ),
                          minimumSize: Size(double.infinity, 50),
                        ),
                        onPressed: _confirmPayment,
                      ),
                      SizedBox(height: 8),
                      if (!_isPaymentComplete)
                        TextButton.icon(
                          icon: Icon(Icons.refresh),
                          label: Text('Tạo Mã QR Mới'),
                          onPressed: _refreshQRCode,
                        ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Lưu ý: Sau khi thanh toán, hệ thống sẽ cập nhật trong vòng 24 giờ.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            color: isHighlighted ? Colors.red : Colors.black,
          ),
        ),
      ],
    );
  }

  void _lookupStudent() {
    // Trong thực tế, đây sẽ là cuộc gọi API để lấy dữ liệu sinh viên
    String studentId = _studentIdController.text.trim();

    if (studentId.isEmpty) {
      _showErrorDialog('Vui lòng nhập mã số sinh viên');
      return;
    }

    // Giả lập dữ liệu sinh viên
    setState(() {
      _isStudentFound = true;
      _studentData = {
        'name': 'Nguyễn Văn A',
        'class': 'CNTT2023A',
        'course': 'K25 - Khóa 2023-2027',
        'tuitionAmount': 8500000,
        'dueDate': '30/04/2025',
      };
    });
  }

  void _confirmPayment() {
    // Giả lập xác nhận thanh toán
    setState(() {
      _isPaymentComplete = true;
    });

    // Hiển thị thông báo thành công
    _showSuccessDialog();
  }

  void _refreshQRCode() {
    // Giả lập tạo mã QR mới
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã tạo mã QR mới'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Lỗi'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Thanh Toán Thành Công'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 64),
              SizedBox(height: 16),
              Text(
                'Học phí đã được thanh toán thành công!',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Mã giao dịch: TXN${DateTime.now().millisecondsSinceEpoch.toString().substring(5, 13)}',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Xem Biên Lai'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  String _formatCurrency(int amount) {
    String amountStr = amount.toString();
    String result = '';
    int count = 0;

    for (int i = amountStr.length - 1; i >= 0; i--) {
      count++;
      result = amountStr[i] + result;
      if (count % 3 == 0 && i > 0) {
        result = '.$result';
      }
    }

    return result;
  }
}