import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart'; // Thêm package path_provider
import 'package:uuid/uuid.dart';

class DocumentManagementScreen extends StatefulWidget {
  const DocumentManagementScreen({Key? key}) : super(key: key);

  @override
  State<DocumentManagementScreen> createState() => _DocumentManagementScreenState();
}

class _DocumentManagementScreenState extends State<DocumentManagementScreen> {
  String _searchQuery = '';
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  int _selectedIndex = 0;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = Uuid();

  Future<void> _uploadDocument() async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx', 'txt'],
      );

      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không có tệp nào được chọn')),
        );
        setState(() {
          _isUploading = false;
        });
        return;
      }

      String fileName = result.files.single.name;
      String fileExtension = path.extension(fileName).toLowerCase().replaceAll('.', '');
      int fileSize;

      // Tạo tên file duy nhất để tránh ghi đè
      String uniqueFileName = 'doc_${_uuid.v4().substring(0, 8)}_$fileName';

      // Lấy thư mục lưu trữ cục bộ (thư mục tài liệu của ứng dụng)
      final directory = await getApplicationDocumentsDirectory();
      final filePath = path.join(directory.path, uniqueFileName);
      File localFile = File(filePath);

      if (result.files.single.bytes != null) {
        fileSize = result.files.single.bytes!.length;
        await localFile.writeAsBytes(result.files.single.bytes!);
      } else {
        File file = File(result.files.single.path!);
        if (!file.existsSync()) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tệp không tồn tại hoặc không thể truy cập')),
          );
          setState(() {
            _isUploading = false;
          });
          return;
        }
        fileSize = file.lengthSync();
        await file.copy(filePath); // Sao chép file vào thư mục cục bộ
      }

      final docDetails = await _showDocumentDetailsDialog(fileName, fileExtension);

      if (docDetails == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã hủy tải lên tài liệu')),
        );
        setState(() {
          _isUploading = false;
        });
        return;
      }

      // Giả lập tiến trình tải lên (vì không dùng Firebase Storage)
      setState(() {
        _uploadProgress = 1.0;
      });

      String docId = 'PD${_uuid.v4().substring(0, 8)}';

      // Lưu thông tin tài liệu vào Firestore, chỉ lưu tên file
      await _firestore.collection('printing').doc(docId).set({
        'loai_tai_lieu': docDetails['loaiTaiLieu'],
        'so_luong_trang': docDetails['soTrang'],
        'file_name': uniqueFileName, // Chỉ lưu tên file
        'file_extension': fileExtension,
        'file_size': fileSize,
        'ngay_tao': FieldValue.serverTimestamp(),
        'ngay_cap_nhat': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tài liệu đã được tải lên thành công')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi không xác định khi tải lên tài liệu: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
    }
  }

  Future<Map<String, dynamic>?> _showDocumentDetailsDialog(String fileName, String fileType) async {
    TextEditingController titleController = TextEditingController(text: fileName);
    TextEditingController pagesController = TextEditingController();

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thông tin tài liệu'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Loại tài liệu',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pagesController,
                decoration: const InputDecoration(
                  labelText: 'Số trang',
                ),
                keyboardType: TextInputType.number,
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
            onPressed: () {
              if (titleController.text.isEmpty || pagesController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin')),
                );
                return;
              }

              int? pages = int.tryParse(pagesController.text);
              if (pages == null || pages <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Số trang không hợp lệ')),
                );
                return;
              }

              Navigator.pop(context, {
                'loaiTaiLieu': titleController.text,
                'soTrang': pages,
              });
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
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
                                    'Danh sách tài liệu',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: _isUploading ? null : _uploadDocument,
                                    icon: _isUploading
                                        ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        value: _uploadProgress > 0 ? _uploadProgress : null,
                                      ),
                                    )
                                        : const Icon(Icons.add),
                                    label: Text(_isUploading ? 'Đang tải lên...' : 'Thêm tài liệu'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      decoration: InputDecoration(
                                        hintText: 'Tìm kiếm tài liệu...',
                                        prefixIcon: const Icon(Icons.search),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide.none,
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey.shade100,
                                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          _searchQuery = value;
                                        });
                                      },
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
                                  child: StreamBuilder<List<DocumentSnapshot>>(
                                    stream: _getDocumentsStream(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return const Center(child: CircularProgressIndicator());
                                      }
                                      if (snapshot.hasError) {
                                        return Center(child: Text('Lỗi: ${snapshot.error}'));
                                      }
                                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                        return const Center(child: Text('Không có tài liệu'));
                                      }
                                      List<DocumentSnapshot> docs = snapshot.data!;
                                      return ListView.separated(
                                        padding: const EdgeInsets.all(10),
                                        itemCount: docs.length,
                                        separatorBuilder: (context, index) => const Divider(),
                                        itemBuilder: (context, index) {
                                          DocumentSnapshot doc = docs[index];
                                          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                                          String documentType = data['file_extension']?.toUpperCase() ?? 'PDF';
                                          String documentName = data['loai_tai_lieu'] ?? 'Tài liệu không tên';
                                          int pages = data['so_luong_trang'] ?? 0;
                                          Timestamp? updatedAt = data['ngay_cap_nhat'] as Timestamp?;
                                          String formattedDate = updatedAt != null
                                              ? '${updatedAt.toDate().day}/${updatedAt.toDate().month}/${updatedAt.toDate().year}'
                                              : 'Không xác định';
                                          Color documentColor = _getDocumentColor(documentType);
                                          return ListTile(
                                            leading: Container(
                                              width: 50,
                                              height: 50,
                                              decoration: BoxDecoration(
                                                color: documentColor.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  documentType,
                                                  style: TextStyle(
                                                    color: documentColor,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            title: Text(documentName),
                                            subtitle: Text(
                                              '$pages trang • Cập nhật: $formattedDate',
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                            trailing: PopupMenuButton(
                                              icon: const Icon(Icons.more_vert),
                                              itemBuilder: (context) => [
                                                const PopupMenuItem(
                                                  value: 'edit',
                                                  child: Text('Chỉnh sửa'),
                                                ),
                                                const PopupMenuItem(
                                                  value: 'download',
                                                  child: Text('Tải xuống'),
                                                ),
                                                const PopupMenuItem(
                                                  value: 'delete',
                                                  child: Text('Xóa'),
                                                ),
                                              ],
                                              onSelected: (value) {
                                                if (value == 'edit') {
                                                  _editDocument(doc.id, data);
                                                } else if (value == 'download') {
                                                  _downloadDocument(data);
                                                } else if (value == 'delete') {
                                                  _deleteDocument(doc.id, data);
                                                }
                                              },
                                            ),
                                          );
                                        },
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
                              StreamBuilder<QuerySnapshot>(
                                stream: _firestore.collection('printing')
                                    .where('ngay_tao', isGreaterThanOrEqualTo: Timestamp.fromDate(
                                    DateTime.now().subtract(const Duration(days: 1))))
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  int todayUploads = 0;
                                  if (snapshot.hasData) {
                                    todayUploads = snapshot.data!.docs.length;
                                  }
                                  return Row(
                                    children: [
                                      Expanded(
                                        child: _buildStatCard(
                                          'Tổng tài liệu tải lên hôm nay',
                                          '$todayUploads',
                                          Icons.upload,
                                          Colors.blue,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 10),
                              StreamBuilder<QuerySnapshot>(
                                stream: _firestore.collection('printing')
                                    .where('ngay_tao', isGreaterThanOrEqualTo: Timestamp.fromDate(
                                    DateTime.now().subtract(const Duration(days: 30))))
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  int monthlyUploads = 0;
                                  if (snapshot.hasData) {
                                    monthlyUploads = snapshot.data!.docs.length;
                                  }
                                  return Row(
                                    children: [
                                      Expanded(
                                        child: _buildStatCard(
                                          'Tổng tài liệu tải lên tháng này',
                                          '$monthlyUploads',
                                          Icons.file_copy,
                                          Colors.green,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 20),
                              Expanded(
                                flex: 2,
                                child: _buildUploadStatsContainer(),
                              ),
                              const SizedBox(height: 20),
                              Expanded(
                                flex: 2,
                                child: _buildRecentUploadsContainer(),
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

  Widget buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Quản lý tài liệu',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: Badge(
                label: const Text('3'),
                child: const Icon(Icons.notifications_outlined),
              ),
              onPressed: () {},
            ),
            const SizedBox(width: 10),
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.blue.shade100,
              child: const Text('NT'),
            ),
          ],
        ),
      ],
    );
  }

  Color _getDocumentColor(String documentType) {
    switch (documentType) {
      case 'PDF':
        return Colors.red;
      case 'DOC':
      case 'DOCX':
        return Colors.blue;
      case 'PPT':
      case 'PPTX':
        return Colors.orange;
      case 'XLS':
      case 'XLSX':
        return Colors.green;
      case 'TXT':
        return Colors.grey;
      default:
        return Colors.purple;
    }
  }

  Stream<List<DocumentSnapshot>> _getDocumentsStream() {
    Query<Map<String, dynamic>> query = _firestore.collection('printing');

    if (_searchQuery.isNotEmpty) {
      String searchQueryLower = _searchQuery.toLowerCase();
      String searchQueryEnd = '$searchQueryLower\uf8ff';
      query = query
          .orderBy('loai_tai_lieu')
          .startAt([searchQueryLower])
          .endAt([searchQueryEnd]);
    } else {
      query = query.orderBy('ngay_cap_nhat', descending: true);
    }

    return query.snapshots().map((snapshot) => snapshot.docs);
  }

  void _editDocument(String docId, Map<String, dynamic> data) async {
    TextEditingController titleController = TextEditingController(text: data['loai_tai_lieu']);
    TextEditingController pagesController = TextEditingController(text: data['so_luong_trang'].toString());

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chỉnh sửa tài liệu'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Loại tài liệu',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pagesController,
                decoration: const InputDecoration(
                  labelText: 'Số trang',
                ),
                keyboardType: TextInputType.number,
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
            onPressed: () {
              if (titleController.text.isEmpty || pagesController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin')),
                );
                return;
              }
              int? pages = int.tryParse(pagesController.text);
              if (pages == null || pages <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Số trang không hợp lệ')),
                );
                return;
              }
              Navigator.pop(context, {
                'loaiTaiLieu': titleController.text,
                'soTrang': pages,
              });
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        await _firestore.collection('printing').doc(docId).update({
          'loai_tai_lieu': result['loaiTaiLieu'],
          'so_luong_trang': result['soTrang'],
          'ngay_cap_nhat': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật tài liệu thành công')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi cập nhật tài liệu: $e')),
        );
      }
    }
  }

  void _downloadDocument(Map<String, dynamic> data) async {
    try {
      String fileName = data['file_name'];
      if (fileName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không có file để tải xuống')),
        );
        return;
      }

      // Lấy đường dẫn thư mục cục bộ
      final directory = await getApplicationDocumentsDirectory();
      final filePath = path.join(directory.path, fileName);
      File localFile = File(filePath);

      if (!await localFile.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File không tồn tại trên thiết bị')),
        );
        return;
      }

      // Thông báo tải xuống (ở đây chỉ là thông báo, bạn có thể mở file nếu cần)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File đã được tìm thấy tại: $filePath')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải xuống tài liệu: $e')),
      );
    }
  }

  void _deleteDocument(String docId, Map<String, dynamic> data) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa tài liệu "${data['loai_tai_lieu']}" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Xóa file cục bộ
        String fileName = data['file_name'];
        if (fileName.isNotEmpty) {
          final directory = await getApplicationDocumentsDirectory();
          final filePath = path.join(directory.path, fileName);
          File localFile = File(filePath);
          if (await localFile.exists()) {
            await localFile.delete();
          }
        }

        // Xóa tài liệu khỏi Firestore
        await _firestore.collection('printing').doc(docId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa tài liệu thành công')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi xóa tài liệu: $e')),
        );
      }
    }
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadStatsContainer() {
    final now = DateTime.now();
    final thisMonth = '${now.month}/${now.year}';

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Thống kê tải lên',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              DropdownButton<String>(
                value: thisMonth,
                items: [
                  DropdownMenuItem<String>(
                    value: thisMonth,
                    child: Text('Tháng ${now.month}'),
                  ),
                  DropdownMenuItem<String>(
                    value: '${now.month - 1}/${now.year}',
                    child: Text('Tháng ${now.month - 1}'),
                  ),
                  DropdownMenuItem<String>(
                    value: '${now.month - 2}/${now.year}',
                    child: Text('Tháng ${now.month - 2}'),
                  ),
                ],
                onChanged: (String? value) {},
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getMonthlyUploadStatsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                }
                Map<int, int> dailyUploads = {};
                if (snapshot.hasData) {
                  for (var doc in snapshot.data!.docs) {
                    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                    Timestamp? timestamp = data['ngay_tao'] as Timestamp?;
                    if (timestamp != null) {
                      DateTime date = timestamp.toDate();
                      int day = date.day;
                      dailyUploads[day] = (dailyUploads[day] ?? 0) + 1;
                    }
                  }
                }
                List<BarChartGroupData> barGroups = [];
                for (int i = 1; i <= 31; i += 5) {
                  barGroups.add(
                    BarChartGroupData(
                      x: i ~/ 5,
                      barRods: [
                        BarChartRodData(
                          toY: (dailyUploads[i] ?? 0).toDouble(),
                          color: Colors.blue,
                          width: 15,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(5),
                            topRight: Radius.circular(5),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 100,
                    barTouchData: BarTouchData(
                      enabled: false,
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            final days = ['01', '05', '10', '15', '20', '25', '30'];
                            if (value.toInt() >= 0 && value.toInt() < days.length) {
                              return Text(days[value.toInt()]);
                            }
                            return const Text('');
                          },
                          reservedSize: 30,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            if (value == 0) {
                              return const Text('0');
                            }
                            if (value == 50) {
                              return const Text('50');
                            }
                            if (value == 100) {
                              return const Text('100');
                            }
                            return const Text('');
                          },
                          reservedSize: 30,
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      horizontalInterval: 25,
                      checkToShowHorizontalLine: (value) => value % 25 == 0,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey.withOpacity(0.3),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    borderData: FlBorderData(
                      show: false,
                    ),
                    barGroups: barGroups.isEmpty
                        ? [_generateEmptyBarGroup(0), _generateEmptyBarGroup(1), _generateEmptyBarGroup(2)]
                        : barGroups,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _generateEmptyBarGroup(int x) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: 0,
          color: Colors.grey.withOpacity(0.3),
          width: 15,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(5),
            topRight: Radius.circular(5),
          ),
        ),
      ],
    );
  }

  Stream<QuerySnapshot> _getMonthlyUploadStatsStream() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    return _firestore.collection('printing')
        .where('ngay_tao', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('ngay_tao', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .snapshots();
  }

  Widget _buildRecentUploadsContainer() {
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
          const Text(
            'Tài liệu tải lên gần đây',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('printing')
                  .orderBy('ngay_tao', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Không có tài liệu gần đây'));
                }
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot doc = snapshot.data!.docs[index];
                    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                    String documentName = data['loai_tai_lieu'] ?? 'Tài liệu không xác định';
                    int pages = data['so_luong_trang'] ?? 0;
                    Timestamp? timestamp = data['ngay_tao'] as Timestamp?;
                    String time = timestamp != null
                        ? '${timestamp.toDate().hour.toString().padLeft(2, '0')}:${timestamp.toDate().minute.toString().padLeft(2, '0')}'
                        : 'Không xác định';
                    final users = ['Nguyễn Văn A', 'Trần Thị B', 'Lê Văn C', 'Phạm Thị D', 'Hoàng Văn E'];
                    String user = users[index % users.length];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.person,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  documentName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                time,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                '$pages trang',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
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
    );
  }
}