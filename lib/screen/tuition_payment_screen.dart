import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TuitionPaymentScreen extends StatefulWidget {
  @override
  _TuitionPaymentScreenState createState() => _TuitionPaymentScreenState();
}

class _TuitionPaymentScreenState extends State<TuitionPaymentScreen> {
  final TextEditingController _studentIdController = TextEditingController();
  bool _isStudentFound = false;
  bool _isPaymentComplete = false;
  bool _isLoading = false;
  String _selectedPaymentMethod = 'Chuyển khoản';
  TuitionRecord? _studentData;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final NumberFormat _currencyFormat =
  NumberFormat.currency(locale: 'vi_VN', symbol: 'VND', decimalDigits: 0);

  @override
  void dispose() {
    _studentIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đóng Học Phí', style: TextStyle(fontSize: 20)),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Icon(Icons.school, size: 48, color: Colors.blue[700]),
                    const SizedBox(height: 10),
                    Text(
                      'Thanh Toán Học Phí',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Vui lòng nhập mã số sinh viên để tiếp tục',
                      style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Form nhập mã số sinh viên
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mã số sinh viên:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _studentIdController,
                            decoration: const InputDecoration(
                              hintText: 'Nhập mã số sinh viên',
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(),
                              fillColor: Colors.white,
                              filled: true,
                            ),
                            keyboardType: TextInputType.text,
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _lookupStudent,
                          icon: _isLoading
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Icon(Icons.search),
                          label: Text(_isLoading ? 'Đang tìm...' : 'Tra Cứu'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Hiển thị thông tin sinh viên
              if (_isStudentFound && _studentData != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _studentData!.isPaid ? Colors.green.shade50 : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _studentData!.isPaid ? Colors.green.shade300 : Colors.blue.shade300,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.blue[700],
                            radius: 24,
                            child: const Icon(Icons.person, color: Colors.white, size: 30),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _studentData!.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'MSSV: ${_studentData!.mssv}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      _buildInfoRow('Lớp:', _studentData!.className),
                      const SizedBox(height: 8),
                      _buildInfoRow('Khóa:', _studentData!.course),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        'Trạng thái:',
                        _studentData!.isPaid ? 'Đã đóng' : 'Chưa đóng',
                        isStatusHighlighted: true,
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        'Học phí:',
                        _currencyFormat.format(_studentData!.amount),
                        isHighlighted: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Phần thanh toán - chỉ hiển thị nếu chưa thanh toán
                if (!_studentData!.isPaid) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber[300]!),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Thanh Toán Qua Mã QR',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(3),
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
                            child: const Center(
                              child: Icon(Icons.qr_code, size: 160),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Mã QR có hiệu lực trong vòng 15 phút',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButton<String>(
                          value: _selectedPaymentMethod,
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedPaymentMethod = newValue!;
                            });
                          },
                          items: <String>['Tiền mặt', 'Chuyển khoản', 'Quét QR']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        _isPaymentComplete
                            ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(
                              'Thanh toán thành công',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.green[800],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                            : ElevatedButton.icon(
                          icon: const Icon(Icons.payment),
                          label: const Text('Xác Nhận Đã Thanh Toán'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 24,
                            ),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          onPressed: _isLoading ? null : _confirmPayment,
                        ),
                        const SizedBox(height: 8),
                        if (!_isPaymentComplete)
                          TextButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: const Text('Tạo Mã QR Mới'),
                            onPressed: _refreshQRCode,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Lưu ý: Sau khi thanh toán, hệ thống sẽ cập nhật trong vòng 24 giờ.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  // Hiển thị thông tin thanh toán nếu đã thanh toán
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green[300]!),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 40),
                            const SizedBox(width: 12),
                            Text(
                              'Học phí đã được thanh toán',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow('Phương thức:', _studentData!.paymentMethod ?? 'N/A'),
                        const SizedBox(height: 8),
                        _buildInfoRow('Ngày thanh toán:', _formatDate(_studentData!.paymentDate)),
                        const SizedBox(height: 8),
                        _buildInfoRow('Mã kiosk:', _studentData!.kioskId),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.receipt_long),
                          label: const Text('Xem biên lai'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 24,
                            ),
                          ),
                          onPressed: _viewReceipt,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlighted = false, bool isStatusHighlighted = false}) {
    Color valueColor = Colors.black;
    FontWeight valueFontWeight = FontWeight.normal;

    if (isHighlighted) {
      valueColor = Colors.red;
      valueFontWeight = FontWeight.bold;
    }

    if (isStatusHighlighted) {
      valueColor = value == 'Đã đóng' ? Colors.green.shade800 : Colors.red.shade800;
      valueFontWeight = FontWeight.bold;
    }

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
            fontWeight: valueFontWeight,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Future<void> _lookupStudent() async {
    String studentId = _studentIdController.text.trim();

    if (studentId.isEmpty) {
      _showErrorDialog('Vui lòng nhập mã số sinh viên');
      return;
    }

    setState(() {
      _isLoading = true;
      _isStudentFound = false;
      _studentData = null;
    });

    try {
      // Truy vấn Firestore để lấy dữ liệu sinh viên dựa trên mssv
      QuerySnapshot querySnapshot = await _firestore
          .collection('tuition')
          .where('mssv', isEqualTo: studentId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot studentDoc = querySnapshot.docs.first;
        setState(() {
          _isStudentFound = true;
          _studentData = TuitionRecord.fromFirestore(studentDoc.id, studentDoc.data() as Map<String, dynamic>);
          _isPaymentComplete = _studentData!.isPaid;
        });
      } else {
        _showErrorDialog('Không tìm thấy thông tin sinh viên với mã số $studentId');
      }
    } catch (e) {
      _showErrorDialog('Đã xảy ra lỗi: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmPayment() async {
    if (_studentData == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Cập nhật trạng thái thanh toán trong Firestore
      await _firestore.collection('tuition').doc(_studentData!.id).update({
        'trang_thai_thanh_toan': 'Đã đóng',
        'ngay_thanh_toan': Timestamp.now(),
        'phuong_thuc_thanh_toan': _selectedPaymentMethod,
        'ma_kiosk': 'K001',
      });

      // Cập nhật trạng thái hiển thị
      setState(() {
        _isPaymentComplete = true;
        _studentData = TuitionRecord(
          id: _studentData!.id,
          mssv: _studentData!.mssv,
          name: _studentData!.name,
          className: _studentData!.className,
          course: _studentData!.course,
          amount: _studentData!.amount,
          paymentDate: DateTime.now(),
          isPaid: true,
          paymentMethod: _selectedPaymentMethod,
          kioskId: 'K001',
        );
      });

      // Hiển thị thông báo thành công
      _showSuccessDialog();
    } catch (e) {
      _showErrorDialog('Không thể cập nhật trạng thái thanh toán: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _refreshQRCode() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã tạo mã QR mới'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _viewReceipt() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Center(
            child: Text(
              'BIÊN LAI THANH TOÁN',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue[800]),
            ),
          ),
          content: SingleChildScrollView(
            child: Container(
              width: 400,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(thickness: 2, color: Colors.grey),
                  _buildReceiptRow('Mã giao dịch:',
                      'TXN${DateTime.now().millisecondsSinceEpoch.toString().substring(5, 13)}'),
                  _buildReceiptRow('MSSV:', _studentData!.mssv),
                  _buildReceiptRow('Họ và tên:', _studentData!.name),
                  _buildReceiptRow('Lớp:', _studentData!.className),
                  _buildReceiptRow('Khóa học:', _studentData!.course),
                  _buildReceiptRow('Học phí:', _currencyFormat.format(_studentData!.amount)),
                  _buildReceiptRow('Phương thức:', _studentData!.paymentMethod ?? 'N/A'),
                  _buildReceiptRow('Ngày thanh toán:', _formatDate(_studentData!.paymentDate)),
                  _buildReceiptRow('Mã kiosk:', _studentData!.kioskId),
                  const SizedBox(height: 10),
                  const Divider(thickness: 1, color: Colors.grey),
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
                foregroundColor: Colors.white,
              ),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Lỗi'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Đóng'),
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
          title: const Text('Thanh Toán Thành Công'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Học phí đã được thanh toán thành công!',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
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
                _viewReceipt();
              },
              child: const Text('Xem Biên Lai'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }
}

// Tuition Record model (copied from TuitionFeeManagement for consistency)
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