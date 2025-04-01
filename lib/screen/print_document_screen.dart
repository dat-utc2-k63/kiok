import 'package:flutter/material.dart';

class PrintDocumentScreen extends StatefulWidget {
  @override
  _PrintDocumentScreenState createState() => _PrintDocumentScreenState();
}

class _PrintDocumentScreenState extends State<PrintDocumentScreen> {
  bool _isDocumentSelected = false;
  bool _isPaymentComplete = false;
  int _copies = 1;
  String _fileName = '';
  double _totalCost = 0;
  final double _pricePerPage = 2000; // 2.000 VND per page
  int _pageCount = 0;

  // Danh sách tài liệu có sẵn
  final List<Map<String, dynamic>> _availableDocuments = [
    {'name': 'Mẫu đơn xin việc.pdf', 'pages': 2, 'icon': Icons.description},
    {'name': 'Mẫu đơn xin nghỉ phép.pdf', 'pages': 1, 'icon': Icons.description},
    {'name': 'Đơn đăng ký tạm trú.pdf', 'pages': 3, 'icon': Icons.article},
    {'name': 'Mẫu CV tiếng Việt.docx', 'pages': 2, 'icon': Icons.article},
    {'name': 'Mẫu CV tiếng Anh.docx', 'pages': 2, 'icon': Icons.article},
    {'name': 'Đơn khiếu nại.pdf', 'pages': 1, 'icon': Icons.description},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dịch Vụ In Tài Liệu', style: TextStyle(fontSize: 22)),
        backgroundColor: Colors.amber[200],
        centerTitle: true,
      ),
      body: Container(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Phần hướng dẫn
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      'Hướng Dẫn In Tài Liệu',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text(
                      '1. Chọn tài liệu có sẵn hoặc tải lên từ thiết bị\n'
                          '2. Thanh toán qua mã QR\n'
                          '3. Nhấn nút In để hoàn tất',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Bước 1: Chọn tài liệu
              _buildStepContainer(
                '1',
                'Chọn Tài Liệu',
                _isDocumentSelected ? _buildSelectedFileInfo() : _buildDocumentSelectionArea(),
                _isDocumentSelected,
              ),
              SizedBox(height: 24),

              // Bước 2: Chọn số lượng và thanh toán
              _buildStepContainer(
                '2',
                'Thanh Toán',
                _isDocumentSelected
                    ? _buildPaymentArea()
                    : Center(child: Text('Vui lòng chọn tài liệu trước', style: TextStyle(fontSize: 16, color: Colors.grey))),
                _isPaymentComplete,
                isEnabled: _isDocumentSelected,
              ),
              SizedBox(height: 24),

              // Bước 3: In tài liệu
              _buildStepContainer(
                '3',
                'In Tài Liệu',
                Center(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.print, size: 28),
                    label: Text('In Tài Liệu', style: TextStyle(fontSize: 20)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                      minimumSize: Size(double.infinity, 60),
                    ),
                    onPressed: (_isDocumentSelected && _isPaymentComplete)
                        ? () => _printDocument(context)
                        : null,
                  ),
                ),
                false,
                isEnabled: _isDocumentSelected && _isPaymentComplete,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContainer(String stepNumber, String title, Widget content, bool isCompleted, {bool isEnabled = true}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isEnabled ? Colors.blue : Colors.grey,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
        color: isEnabled ? Colors.white : Colors.grey[100],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isEnabled ? Colors.blue : Colors.grey,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                SizedBox(width: 16),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: Center(
                    child: isCompleted
                        ? Icon(Icons.check, color: Colors.green, size: 20)
                        : Text(
                      stepNumber,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isEnabled ? Colors.blue : Colors.grey,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentSelectionArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Chọn tài liệu có sẵn:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        Container(
          height: 250,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.builder(
            itemCount: _availableDocuments.length,
            itemBuilder: (context, index) {
              final doc = _availableDocuments[index];
              return ListTile(
                leading: Icon(doc['icon'], color: Colors.blue),
                title: Text(doc['name']),
                subtitle: Text('${doc['pages']} trang'),
                trailing: OutlinedButton(
                  child: Text('Chọn'),
                  onPressed: () => _selectDocument(doc),
                ),
                onTap: () => _selectDocument(doc),
              );
            },
          ),
        ),
        SizedBox(height: 16),
        Text(
          'HOẶC',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        Container(
          height: 120,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey, width: 1, style: BorderStyle.solid),
            borderRadius: BorderRadius.circular(8),
          ),
          child: InkWell(
            onTap: _uploadFile,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.upload_file, size: 40, color: Colors.blue),
                SizedBox(height: 12),
                Text(
                  'Tải lên từ thiết bị',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Hỗ trợ: PDF, DOC, DOCX, JPG',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: Icon(Icons.qr_code_scanner),
                label: Text('Quét QR để chọn file từ điện thoại'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _showQRCodeScreen,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSelectedFileInfo() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.description, size: 48, color: Colors.blue),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_fileName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('$_pageCount trang', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () {
                  setState(() {
                    _isDocumentSelected = false;
                  });
                },
                tooltip: 'Thay đổi tài liệu',
              ),
            ],
          ),
          Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Số bản sao:', style: TextStyle(fontSize: 16)),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.remove_circle_outline),
                    onPressed: _copies > 1 ? () {
                      setState(() {
                        _copies--;
                        _updateTotalCost();
                      });
                    } : null,
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$_copies',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add_circle_outline),
                    onPressed: () {
                      setState(() {
                        _copies++;
                        _updateTotalCost();
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 8),
          CheckboxListTile(
            title: Text('In hai mặt', style: TextStyle(fontSize: 16)),
            value: true,
            onChanged: (value) {},
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentArea() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Chi phí một trang:', style: TextStyle(fontSize: 16)),
                  Text('${_pricePerPage.toInt()} VNĐ', style: TextStyle(fontSize: 16)),
                ],
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Số trang:', style: TextStyle(fontSize: 16)),
                  Text('$_pageCount', style: TextStyle(fontSize: 16)),
                ],
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Số bản sao:', style: TextStyle(fontSize: 16)),
                  Text('$_copies', style: TextStyle(fontSize: 16)),
                ],
              ),
              Divider(thickness: 1),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tổng chi phí:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('${_totalCost.toInt()} VNĐ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        Text('Quét mã QR để thanh toán:', style: TextStyle(fontSize: 16)),
        SizedBox(height: 8),
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Icon(Icons.qr_code, size: 160),
          ),
        ),
        SizedBox(height: 16),
        _isPaymentComplete
            ? Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Đã thanh toán thành công', style: TextStyle(fontSize: 16, color: Colors.green)),
          ],
        )
            : ElevatedButton(
          onPressed: _confirmPayment,
          child: Text('Xác nhận đã thanh toán', style: TextStyle(fontSize: 16)),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          ),
        ),
      ],
    );
  }

  void _selectDocument(Map<String, dynamic> document) {
    setState(() {
      _isDocumentSelected = true;
      _fileName = document['name'];
      _pageCount = document['pages'];
      _updateTotalCost();
    });
  }

  void _uploadFile() {
    // Giả lập chọn file
    setState(() {
      _isDocumentSelected = true;
      _fileName = 'Báo cáo tháng 3.pdf';
      _pageCount = 5;
      _updateTotalCost();
    });
  }

  void _showQRCodeScreen() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Quét mã QR'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(Icons.qr_code, size: 160),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Quét mã QR này bằng điện thoại để chọn và gửi file',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Giả lập đã nhận được file từ điện thoại
              setState(() {
                _isDocumentSelected = true;
                _fileName = 'Tài liệu từ điện thoại.pdf';
                _pageCount = 3;
                _updateTotalCost();
              });
            },
            child: Text('Giả lập nhận file'),
          ),
        ],
      ),
    );
  }

  void _updateTotalCost() {
    setState(() {
      _totalCost = _pageCount * _pricePerPage * _copies;
    });
  }

  void _confirmPayment() {
    // Giả lập xác nhận thanh toán
    setState(() {
      _isPaymentComplete = true;
    });
  }

  void _printDocument(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Đang In Tài Liệu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(),
            SizedBox(height: 16),
            Text('Vui lòng đợi trong giây lát...'),
          ],
        ),
      ),
    );

    // Giả lập quá trình in
    Future.delayed(Duration(seconds: 3), () {
      Navigator.pop(context);
      _showPrintComplete(context);
    });
  }

  void _showPrintComplete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('In Thành Công'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 64),
            SizedBox(height: 16),
            Text('Tài liệu của bạn đã được in thành công!'),
            SizedBox(height: 8),
            Text('Vui lòng nhận tài liệu ở khay giấy.'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Reset trạng thái để sẵn sàng cho lần in tiếp theo
              setState(() {
                _isDocumentSelected = false;
                _isPaymentComplete = false;
                _copies = 1;
                _fileName = '';
                _totalCost = 0;
                _pageCount = 0;
              });
            },
            child: Text('Hoàn Tất'),
          ),
        ],
      ),
    );
  }
}