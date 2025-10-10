import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/hoadon.dart';
import '../services/api_service.dart';
import 'chi_tiet_hoa_don_screen.dart';
import '../main.dart';
import 'quet_ma_screen.dart'; // ✅ thêm dòng này

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

  int _currentIndex = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDanhSach();

    // 🔄 Tự động reload mỗi 3 giây để cập nhật tổng số
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return false;
      _loadDanhSach();
      return true;
    });
  }

  Future<void> _loadDanhSach() async {
    try {
      final list = await ApiService.layDanhSachHoaDon();
      setState(() {
        dsHoaDon = list;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        dsHoaDon = [];
        _isLoading = false;
      });
    }
  }

  // -------------------- Search & Filter --------------------
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

  // -------------------- Xóa hóa đơn --------------------
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
    if (confirm != true) return;
    final success = await ApiService.xoaHoaDon(hd.id);
    if (success) _loadDanhSach();
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
    for (var hd in _daThanhToan) {
      await ApiService.xoaHoaDon(hd.id);
    }
    _loadDanhSach();
  }

  // -------------------- Danh sách hóa đơn --------------------
  Widget _buildList(List<HoaDon> list) {
    if (list.isEmpty) return const Center(child: Text("Không có hóa đơn"));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final hd = list[index];
        final color = hd.trangThai == "Đã thanh toán"
            ? Colors.green
            : Colors.orange;
        final ngay = hd.ngayLap != null
            ? DateFormat('dd/MM/yyyy').format(hd.ngayLap!)
            : "-";

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
          child: ListTile(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ChiTietHoaDonScreen(hd: hd)),
              );
              _loadDanhSach(); // 🔄 tự cập nhật khi quay lại
            },
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            title: Text(
              "Mã: ${hd.maHoaDon}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(
              "Loại: ${hd.loaiHoaDon ?? "Chưa chọn"}\n"
              "SL mặt hàng: ${hd.items.length}\n"
              "Ngày lập: $ngay\n"
              "Tổng tiền: ${_formatMoney(hd.tongTien)} VND\n"
              "Thanh toán: ${hd.phuongThuc ?? "Chưa chọn"}",
              style: const TextStyle(height: 1.4),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                  onPressed: () => _xoaHoaDon(hd),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    hd.trangThai ?? "",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // -------------------- Box hiển thị tổng --------------------
  Widget _buildSummaryBox(String title, int count, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "$count",
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------- Build giao diện --------------------
  @override
  Widget build(BuildContext context) {
    final today = DateFormat("dd/MM/yyyy").format(DateTime.now());

    return Scaffold(
      body: Column(
        children: [
          // 🔹 Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dòng chào
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Chào buổi sáng,",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          today,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Image.asset(
                      "assets/icon/app_icon.png",
                      width: 90,
                      height: 90,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 🔹 Hai box tổng hóa đơn
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSummaryBox(
                      "Chưa thanh toán",
                      _chuaThanhToan.length,
                      Colors.orangeAccent,
                    ),
                    _buildSummaryBox(
                      "Đã thanh toán",
                      _daThanhToan.length,
                      Colors.greenAccent,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Tiêu đề và nút
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Danh sách hóa đơn",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.qr_code_scanner,
                            color: Colors.white,
                          ),
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const QuetMaScreen(),
                              ),
                            );

                            if (result != null && result is String) {
                              // 📦 Gọi API tạo hóa đơn theo mã sản phẩm
                              final hoaDon = await ApiService.taoHoaDonTheoMa(
                                result,
                              );

                              if (hoaDon != null) {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ChiTietHoaDonScreen(hd: hoaDon),
                                  ),
                                );
                                _loadDanhSach(); // 🔄 tự reload danh sách sau khi quay lại
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "❌ Không tìm thấy sản phẩm hoặc lỗi khi tạo hóa đơn",
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            _isSearching ? Icons.close : Icons.search,
                            color: Colors.white,
                          ),
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
                          icon: const Icon(
                            Icons.delete_sweep,
                            color: Colors.white,
                          ),
                          onPressed: _xoaTatCaDaThanhToan,
                        ),
                      ],
                    ),
                  ],
                ),

                if (_isSearching)
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "Tìm kiếm theo mã hóa đơn...",
                      hintStyle: TextStyle(color: Colors.white70),
                      border: InputBorder.none,
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
              ],
            ),
          ),

          // 🔹 Tab hiển thị danh sách
          Material(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF4A00E0),
              labelColor: const Color(0xFF4A00E0),
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: "Chưa thanh toán"),
                Tab(text: "Đã thanh toán"),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
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

      // 🔹 Nút thêm hóa đơn mới
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF4A00E0),
        onPressed: () async {
          final hd = HoaDon(
            id: 0,
            maHoaDon: "HD-${DateTime.now().millisecondsSinceEpoch}",
            loaiHoaDon: null,
            items: [],
            phuongThuc: null,
            trangThai: "Chưa thanh toán",
            ngayLap: DateTime.now(),
          );

          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ChiTietHoaDonScreen(hd: hd)),
          );
          _loadDanhSach(); // 🔄 cập nhật tự động
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),

      // 🔹 Thanh điều hướng
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/danh-sach-nhan-vien');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/hoa-don');
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/kho-hang');
          } else if (index == 3) {
            Navigator.pushReplacementNamed(context, '/doanh-thu');
          } else if (index == 4) {
            Navigator.pushReplacementNamed(context, '/home');
          }
        },
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF4A00E0),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Nhân Viên"),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: "Hóa Đơn",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warehouse),
            label: "Kho Hàng",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: "Doanh Thu",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        ],
      ),
    );
  }
}
