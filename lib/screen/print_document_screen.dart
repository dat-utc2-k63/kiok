import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class PrintDocumentScreen extends StatefulWidget {
  const PrintDocumentScreen({Key? key}) : super(key: key);

  @override
  _PrintDocumentScreenState createState() => _PrintDocumentScreenState();
}

class _PrintDocumentScreenState extends State<PrintDocumentScreen> {
  // Document selection state
  bool _isDocumentSelected = false;
  bool _isPaymentComplete = false;
  int _copies = 1;
  String _fileName = '';
  double _totalCost = 0;
  final double _pricePerPage = 2000; // 2,000 VND per page
  int _pageCount = 0;
  String _documentId = '';
  bool _isLoading = true;
  List<DocumentModel> _availableDocuments = [];
  bool _isDuplexPrinting = true; // Default to double-sided printing

  @override
  void initState() {
    super.initState();
    _loadAvailableDocuments();
  }

  // Fetch available documents from Firestore (updated to use /printing)
  Future<void> _loadAvailableDocuments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final QuerySnapshot documentSnapshot =
      await FirebaseFirestore.instance.collection('printing').get();

      final List<DocumentModel> docs = [];
      for (var doc in documentSnapshot.docs) {
        final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        docs.add(
          DocumentModel(
            id: doc.id,
            name: data['file_name'] ?? 'Tài liệu ${doc.id}',
            pages: data['so_luong_trang'] ?? 1,
            type: data['loai_tai_lieu'] ?? 'Đen trắng, Một mặt',
            categoryId: data['ma_danh_muc'] ?? '',
          ),
        );
      }

      setState(() {
        _availableDocuments = docs;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading documents: $e');
      setState(() {
        _isLoading = false;
        _availableDocuments = [];
      });
    }
  }

  IconData _getIconForFileName(String fileName) {
    final lowerCaseName = fileName.toLowerCase();
    if (lowerCaseName.endsWith('.pdf')) {
      return Icons.picture_as_pdf;
    } else if (lowerCaseName.endsWith('.doc') || lowerCaseName.endsWith('.docx')) {
      return Icons.article;
    } else if (lowerCaseName.endsWith('.jpg') ||
        lowerCaseName.endsWith('.jpeg') ||
        lowerCaseName.endsWith('.png')) {
      return Icons.image;
    }
    return Icons.description;
  }

  void _updateTotalCost() {
    setState(() {
      _totalCost = _pageCount * _pricePerPage * _copies;
    });
  }

  void _selectDocument(DocumentModel document) {
    setState(() {
      _isDocumentSelected = true;
      _fileName = document.name;
      _pageCount = document.pages;
      _documentId = document.id;
      _updateTotalCost();
    });
  }

  void _confirmPayment() {
    setState(() {
      _isPaymentComplete = true;
    });
  }

  Future<void> _savePrintInvoice() async {
    try {
      // Generate a unique invoice ID
      final String invoiceId = 'PI${DateTime.now().millisecondsSinceEpoch}';

      await FirebaseFirestore.instance
          .collection('printing')
          .doc(_documentId)
          .collection('print_invoices')
          .doc(invoiceId)
          .set({
        'ma_tai_lieu': _documentId,
        'phi_in': _pricePerPage.toInt(),
        'so_luong_ban_in': _copies,
        'tong_phi': _totalCost.toInt(),
        'phuong_thuc_thanh_toan': 'Online',
        'ngay_in': FieldValue.serverTimestamp(),
        'ma_kiosk': 'K001',
      });

      print('Invoice saved with ID: $invoiceId under document $_documentId');
    } catch (e) {
      print('Error saving invoice: $e');
    }
  }

  void _printDocument(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Đang In Tài Liệu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            LinearProgressIndicator(),
            SizedBox(height: 16),
            Text('Vui lòng đợi trong giây lát...'),
          ],
        ),
      ),
    );

    // Save invoice to Firestore before showing print completion
    _savePrintInvoice().then((_) {
      // Simulate printing process
      Future.delayed(const Duration(seconds: 3), () {
        Navigator.pop(context);
        _showPrintComplete(context);
      });
    });
  }

  void _showPrintComplete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('In Thành Công'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
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
              // Reset state for next print
              setState(() {
                _isDocumentSelected = false;
                _isPaymentComplete = false;
                _copies = 1;
                _fileName = '';
                _totalCost = 0;
                _pageCount = 0;
                _documentId = '';
              });
            },
            child: const Text('Hoàn Tất'),
          ),
        ],
      ),
    );
  }

  void _showQRCodeScreen() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quét mã QR'),
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
              child: const Center(
                child: Icon(Icons.qr_code, size: 160),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Quét mã QR này bằng điện thoại để chọn và gửi file',
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9E6), // Màu nền vàng nhạt
      appBar: AppBar(
        title: const Text('Dịch Vụ In Tài Liệu', style: TextStyle(fontSize: 22)),
        backgroundColor: Colors.amber[200],
        centerTitle: true,
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Instructions section
              _buildInstructionsSection(),
              const SizedBox(height: 24),

              // Step 1: Document selection
              _buildStepContainer(
                '1',
                'Chọn Tài Liệu',
                _isDocumentSelected
                    ? _buildSelectedFileInfo()
                    : _buildDocumentSelectionArea(),
                _isDocumentSelected,
              ),
              const SizedBox(height: 24),

              // Step 2: Payment
              _buildStepContainer(
                '2',
                'Thanh Toán',
                _isDocumentSelected
                    ? _buildPaymentArea()
                    : const Center(
                    child: Text('Vui lòng chọn tài liệu trước',
                        style: TextStyle(fontSize: 16, color: Colors.grey))),
                _isPaymentComplete,
                isEnabled: _isDocumentSelected,
              ),
              const SizedBox(height: 24),

              // Step 3: Print
              _buildStepContainer(
                '3',
                'In Tài Liệu',
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.print, size: 28),
                    label: const Text('In Tài Liệu', style: TextStyle(fontSize: 20)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                      minimumSize: const Size(double.infinity, 60),
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

  Widget _buildInstructionsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        children: [
          Text(
            'Hướng Dẫn In Tài Liệu',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            '1. Chọn tài liệu có sẵn\n'
                '2. Thanh toán qua mã QR\n'
                '3. Nhấn nút In để hoàn tất',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContainer(
      String stepNumber,
      String title,
      Widget content,
      bool isCompleted, {
        bool isEnabled = true,
      }) {
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
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isEnabled ? Colors.blue : Colors.grey,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, color: Colors.green, size: 20)
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
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
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
        const Text(
          'Chọn tài liệu có sẵn:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          height: 250,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _availableDocuments.isEmpty
              ? const Center(child: Text('Không có tài liệu nào khả dụng'))
              : ListView.builder(
            itemCount: _availableDocuments.length,
            itemBuilder: (context, index) {
              final doc = _availableDocuments[index];
              return ListTile(
                leading: Icon(_getIconForFileName(doc.name), color: Colors.blue),
                title: Text(doc.name),
                subtitle: Text('${doc.pages} trang - ${doc.type}'),
                trailing: OutlinedButton(
                  child: const Text('Chọn'),
                  onPressed: () => _selectDocument(doc),
                ),
                onTap: () => _selectDocument(doc),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Quét QR để chọn file từ điện thoại'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(_getIconForFileName(_fileName), size: 48, color: Colors.blue),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_fileName,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('$_pageCount trang', style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  setState(() {
                    _isDocumentSelected = false;
                  });
                },
                tooltip: 'Thay đổi tài liệu',
              ),
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Số bản sao:', style: TextStyle(fontSize: 16)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: _copies > 1
                        ? () {
                      setState(() {
                        _copies--;
                        _updateTotalCost();
                      });
                    }
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$_copies',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
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
          const SizedBox(height: 8),
          CheckboxListTile(
            title: const Text('In hai mặt', style: TextStyle(fontSize: 16)),
            value: _isDuplexPrinting,
            onChanged: (value) {
              setState(() {
                _isDuplexPrinting = value ?? true;
              });
            },
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Chi phí một trang:', style: TextStyle(fontSize: 16)),
                  Text('${_pricePerPage.toInt()} VNĐ',
                      style: const TextStyle(fontSize: 16)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Số trang:', style: TextStyle(fontSize: 16)),
                  Text('$_pageCount', style: const TextStyle(fontSize: 16)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Số bản sao:', style: TextStyle(fontSize: 16)),
                  Text('$_copies', style: const TextStyle(fontSize: 16)),
                ],
              ),
              const Divider(thickness: 1),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tổng chi phí:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('${_totalCost.toInt()} VNĐ',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('Quét mã QR để thanh toán:', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Icon(Icons.qr_code, size: 160),
          ),
        ),
        const SizedBox(height: 16),
        _isPaymentComplete
            ? Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Đã thanh toán thành công',
                style: TextStyle(fontSize: 16, color: Colors.green)),
          ],
        )
            : ElevatedButton(
          onPressed: _confirmPayment,
          child: const Text('Xác nhận đã thanh toán',
              style: TextStyle(fontSize: 16)),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          ),
        ),
      ],
    );
  }
}

// Model class for document
class DocumentModel {
  final String id;
  final String name;
  final int pages;
  final String type;
  final String categoryId;

  DocumentModel({
    required this.id,
    required this.name,
    required this.pages,
    required this.type,
    required this.categoryId,
  });
}