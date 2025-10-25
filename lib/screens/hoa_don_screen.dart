// lib/screens/hoa_don_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/hoadon.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'chi_tiet_hoa_don_screen.dart';
import 'quet_ma_screen.dart';

class HoaDonScreen extends StatefulWidget {
  const HoaDonScreen({super.key});

  @override
  State<HoaDonScreen> createState() => _HoaDonScreenState();
}

class _HoaDonScreenState extends State<HoaDonScreen>
    with SingleTickerProviderStateMixin {
  List<HoaDon> dsHoaDon = [];
  bool _isLoading = true;
  late TabController _tabController;

  bool _isSearching = false;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  final int _currentIndex = 1;

  // ✨ MÀU SẮC: Giữ nguyên màu gốc của bạn
  final Color _primaryColor = const Color(0xFF4A00E0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDanhSach();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // =======================================================================
  // ✨ KHÔNG THAY ĐỔI LOGIC - Các hàm xử lý dữ liệu được giữ nguyên
  // =======================================================================

  Future<void> _loadDanhSach() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    await Future.wait([
      ApiService.layDanhSachHoaDon()
          .then((list) {
            if (mounted) {
              setState(() {
                dsHoaDon = list;
              });
            }
          })
          .catchError((_) {
            if (mounted) {
              setState(() {
                dsHoaDon = [];
              });
            }
          }),
      Provider.of<NotificationService>(
        context,
        listen: false,
      ).loadNotifications(),
    ]);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<HoaDon> get _chuaThanhToan =>
      _applySearch(dsHoaDon.where((hd) => hd.trangThai != "Đã thanh toán"));

  List<HoaDon> get _daThanhToan =>
      _applySearch(dsHoaDon.where((hd) => hd.trangThai == "Đã thanh toán"));

  List<HoaDon> _applySearch(Iterable<HoaDon> list) {
    if (_searchQuery.isEmpty) return list.toList();
    return list
        .where(
          (hd) =>
              hd.maHoaDon.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  String _formatMoney(int value) =>
      NumberFormat("#,###", "vi_VN").format(value);

  Future<void> _xoaHoaDon(HoaDon hd) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: Text("Bạn có chắc chắn muốn xóa hóa đơn ${hd.maHoaDon}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Xóa"),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final success = await ApiService.xoaHoaDon(hd.id);
    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Đã xóa hóa đơn")));
      await _loadDanhSach();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Xóa hóa đơn thất bại")));
    }
  }

  Future<void> _xoaTatCaDaThanhToan() async {
    if (_daThanhToan.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: Text(
          "Bạn có chắc chắn muốn xóa tất cả ${_daThanhToan.length} hóa đơn đã thanh toán?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Xóa tất cả"),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Đang xóa ${_daThanhToan.length} hóa đơn...")),
    );

    for (var hd in _daThanhToan) {
      await ApiService.xoaHoaDon(hd.id);
    }

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Đã xóa xong")));
    }
    await _loadDanhSach();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Chào buổi sáng';
    }
    if (hour < 18) {
      return 'Chào buổi chiều';
    }
    return 'Chào buổi tối';
  }

  // =======================================================================
  // ✨ BẮT ĐẦU PHẦN GIAO DIỆN (UI) ĐÃ CẬP NHẬT
  // =======================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _loadDanhSach,
        color: _primaryColor,
        child: Column(
          children: [
            // Phần Header (Chào, Tóm tắt)
            Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGreeting(),
                  _buildSummarySection(), // ✨ Sửa: Chứa 2 ô tóm tắt
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Thanh điều khiển danh sách (Tiêu đề, icon)
            _buildListActions(),

            // Thanh tìm kiếm
            _buildSearchBar(),

            // Thanh Tab
            Material(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                indicatorColor: _primaryColor,
                labelColor: _primaryColor,
                unselectedLabelColor: Colors.grey.shade600,
                tabs: const [
                  Tab(text: "Chưa thanh toán"),
                  Tab(text: "Đã thanh toán"),
                ],
              ),
            ),

            // Danh sách
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: _primaryColor),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildList(_chuaThanhToan),
                        _buildList(_daThanhToan),
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  /// AppBar
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _primaryColor, // ✨ Đã dùng màu gốc
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Image.asset(
        "assets/icon/app_icon.png",
        height: 60,
        width: 120,
        fit: BoxFit.contain,
        alignment: Alignment.centerLeft,
      ),
      actions: [
        // Nút thông báo
        Consumer<NotificationService>(
          builder: (context, service, child) {
            return Stack(
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/notifications');
                  },
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                  tooltip: 'Thông báo',
                ),
                if (service.unreadCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${service.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  /// Phần chào và ngày tháng
  Widget _buildGreeting() {
    final String greeting = _getGreeting();
    final String today = DateFormat("dd/MM/yyyy").format(DateTime.now());

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            today,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// ✨ SỬA: Phần tóm tắt dạng Card, thêm InkWell
  Widget _buildSummarySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            // ✨ SỬA: Thêm InkWell để bấm
            child: InkWell(
              onTap: () {
                _tabController.animateTo(0); // Chuyển đến tab "Chưa thanh toán"
              },
              borderRadius: BorderRadius.circular(16),
              child: _buildSummaryBox(
                "Chưa thanh toán",
                _chuaThanhToan.length,
                Colors.orangeAccent, // ✨ SỬA: Đổi màu text
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            // ✨ SỬA: Thêm InkWell để bấm
            child: InkWell(
              onTap: () {
                _tabController.animateTo(1); // Chuyển đến tab "Đã thanh toán"
              },
              borderRadius: BorderRadius.circular(16),
              child: _buildSummaryBox(
                "Đã thanh toán",
                _daThanhToan.length,
                Colors.greenAccent, // ✨ SỬA: Đổi màu text
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ✨ SỬA: Widget `_buildSummaryBox` - Đã xóa Icon
  Widget _buildSummaryBox(String title, int count, Color textColor) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      // ✨ SỬA: Bỏ màu nền nhẹ
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 26.5,
        ), // Tăng padding dọc
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center, // Căn giữa
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const SizedBox(height: 8), // Tăng khoảng cách
            Text(
              "$count",
              style: TextStyle(
                color: textColor, // ✨ SỬA: Dùng màu text được truyền vào
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget chứa Tiêu đề "Danh sách..." và các nút
  Widget _buildListActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Danh sách hóa đơn",
            style: TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.qr_code_scanner, color: _primaryColor),
                tooltip: "Quét mã tạo hóa đơn",
                onPressed: _handleScanQRCode,
              ),
              IconButton(
                icon: Icon(
                  _isSearching ? Icons.close : Icons.search,
                  color: _primaryColor,
                ),
                tooltip: "Tìm kiếm",
                onPressed: () {
                  setState(() {
                    if (_isSearching) {
                      _isSearching = false;
                      _searchQuery = "";
                      _searchController.clear();
                    } else {
                      _isSearching = true;
                    }
                  });
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_sweep_outlined,
                  color: Colors.red.shade600,
                ),
                tooltip: "Xóa tất cả hóa đơn đã thanh toán",
                onPressed: _xoaTatCaDaThanhToan,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Tách logic quét QR ra cho gọn
  void _handleScanQRCode() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QuetMaScreen()),
    );

    if (result != null && result is String) {
      final hoaDon = await ApiService.taoHoaDonTheoMa(result);
      if (!mounted) return;

      if (hoaDon != null) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChiTietHoaDonScreen(hd: hoaDon)),
        );
        await _loadDanhSach();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ Không tìm thấy sản phẩm hoặc lỗi khi tạo hóa đơn"),
          ),
        );
      }
    }
  }

  /// Widget thanh tìm kiếm
  Widget _buildSearchBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _isSearching ? 60 : 0,
      child: _isSearching
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  hintText: "Tìm kiếm theo mã hóa đơn...",
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  contentPadding: const EdgeInsets.all(10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  /// Widget `_buildList` (Giữ nguyên thiết kế thẻ)
  Widget _buildList(List<HoaDon> list) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            _isSearching ? "Không tìm thấy kết quả" : "Chưa có hóa đơn nào",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), // Thêm padding dưới
      itemCount: list.length,
      itemBuilder: (context, index) {
        final hd = list[index];
        final isPaid = hd.trangThai == "Đã thanh toán";
        // ✨ SỬA: Đổi màu tag trạng thái cho nhất quán
        final color = isPaid ? Colors.green : Colors.orange.shade700;
        final ngay = hd.ngayLap != null
            ? DateFormat('dd/MM/yyyy').format(hd.ngayLap!)
            : "-";

        IconData loaiIcon = Icons.receipt_long_outlined;
        if (hd.loaiHoaDon == "Xuất") {
          loaiIcon = Icons.arrow_upward_rounded;
        } else if (hd.loaiHoaDon == "Nhập") {
          loaiIcon = Icons.arrow_downward_rounded;
        }

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ChiTietHoaDonScreen(hd: hd)),
              );
              await _loadDanhSach();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Icon đầu
                  CircleAvatar(
                    backgroundColor: _primaryColor.withOpacity(0.1),
                    child: Icon(loaiIcon, color: _primaryColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  // Thông tin chính
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Mã: ${hd.maHoaDon}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Ngày: $ngay • ${hd.items.length} mặt hàng",
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${_formatMoney(hd.tongTien)} VND",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Trạng thái và nút xóa
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatusTag(hd.trangThai ?? "", color),
                      if (!isPaid)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: Colors.red,
                          ),
                          onPressed: () => _xoaHoaDon(hd),
                        )
                      else
                        const SizedBox(
                          height: 40,
                        ), // Giữ-chỗ-để-cân-bằng-layout
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Widget cho cái tag trạng thái
  Widget _buildStatusTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  /// Nút FAB
  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      backgroundColor: _primaryColor, // ✨ Đã dùng màu gốc
      onPressed: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChiTietHoaDonScreen()),
        );
        if (result != null) {
          await _loadDanhSach();
        }
      },
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  /// Bottom Nav Bar
  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        if (_currentIndex == index) return;
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, '/danh-sach-nhan-vien');
            break;
          case 1:
            // Đã ở đây
            break;
          case 2:
            Navigator.pushReplacementNamed(context, '/kho-hang');
            break;
          case 3:
            Navigator.pushReplacementNamed(context, '/doanh-thu');
            break;
          case 4:
            Navigator.pushReplacementNamed(context, '/home');
            break;
        }
      },
      backgroundColor: Colors.white,
      selectedItemColor: _primaryColor, // ✨ Đã dùng màu gốc
      unselectedItemColor: Colors.grey.shade600,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.people), label: "Nhân Viên"),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long),
          label: "Hóa Đơn",
        ),
        BottomNavigationBarItem(icon: Icon(Icons.warehouse), label: "Kho Hàng"),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart),
          label: "Doanh Thu",
        ),
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
      ],
    );
  }
}
