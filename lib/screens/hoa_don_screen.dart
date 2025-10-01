// lib/screens/hoa_don_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/hoadon.dart';
import '../services/api_service.dart';
import 'chi_tiet_hoa_don_screen.dart';
import 'danh_sach_nhan_vien_screen.dart';
import 'kho_hang_screen.dart';
import '../main.dart'; // 🔹 để gọi MyApp khi quay về Trang chủ

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

  int _currentIndex = 1; // ✅ tab Hóa Đơn

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDanhSach();
  }

  Future<void> _loadDanhSach() async {
    setState(() => _isLoading = true);
    try {
      dsHoaDon = await ApiService.layDanhSachHoaDon();
    } catch (_) {
      dsHoaDon = [];
    }
    setState(() => _isLoading = false);
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

  // -------------------- Xóa hóa đơn API --------------------
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
    if (success) {
      _loadDanhSach();
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

    for (var hd in _daThanhToan) {
      await ApiService.xoaHoaDon(hd.id);
    }
    _loadDanhSach();
  }

  // -------------------- Build ListTile --------------------
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ChiTietHoaDonScreen(hd: hd)),
              );
              _loadDanhSach();
            },
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
                  tooltip: "Xóa",
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

  // -------------------- Build Scaffold --------------------
  @override
  Widget build(BuildContext context) {
    final today = DateFormat("dd/MM/yyyy").format(DateTime.now());

    return Scaffold(
      body: Column(
        children: [
          // ✅ Gradient Header
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
                // Dòng chào + ngày
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
                    Row(
                      children: const [
                        Icon(
                          Icons.warehouse,
                          color: Colors.white,
                          size: 28,
                        ), // ✅ icon kho
                        SizedBox(width: 6),
                        Text(
                          "VIETFLOW",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Tiêu đề + nút search + xóa tất cả
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
                          tooltip: "Xóa tất cả hóa đơn đã thanh toán",
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
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
              ],
            ),
          ),

          // ✅ TabBar
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

          // ✅ Nội dung
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

      // ✅ FloatingActionButton để thêm mới hóa đơn
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
          _loadDanhSach();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);

          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/danh-sach-nhan-vien');
          }
          if (index == 1) {
            Navigator.pushReplacementNamed(context, '/hoa-don');
          }
          if (index == 2) {
            Navigator.pushReplacementNamed(context, '/kho-hang');
          }
          if (index == 3) {
            Navigator.pushReplacementNamed(context, '/doanh-thu');
          }
          if (index == 4) {
            // 👉 về HomeScreen trong QuanLyXuongApp
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
