import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/khohang.dart';
import '../services/api_service.dart';
import 'chi_tiet_kho_hang_screen.dart';
import 'them_kho_hang_screen.dart';
import 'danh_sach_nhan_vien_screen.dart';
import 'hoa_don_screen.dart';
import '../main.dart';

class KhoHangScreen extends StatefulWidget {
  @override
  _KhoHangScreenState createState() => _KhoHangScreenState();
}

class _KhoHangScreenState extends State<KhoHangScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<KhoHang> _danhSachKho = [];
  List<KhoHang> _filteredKho = [];
  bool _isLoading = true;
  int _currentIndex = 2; // ✅ Tab Kho Hàng
  String _searchText = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDanhSach();
  }

  Future<void> _loadDanhSach() async {
    setState(() => _isLoading = true);
    final ds = await ApiService.layDanhSachKhoHang();
    setState(() {
      _danhSachKho = ds;
      _applySearch();
      _isLoading = false;
    });
  }

  void _applySearch() {
    if (_searchText.isEmpty) {
      _filteredKho = _danhSachKho;
    } else {
      _filteredKho = _danhSachKho
          .where(
            (k) => (k.tenKho ?? "").toLowerCase().contains(
              _searchText.toLowerCase(),
            ),
          )
          .toList();
    }
  }

  Future<void> _xoaKhoHang(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Xóa kho hàng"),
        content: Text("Bạn có chắc muốn xóa kho này không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("Hủy"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ApiService.xoaKhoHang(id);
      _loadDanhSach();
    }
  }

  Future<void> _xoaTatCaLichSu() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Xóa tất cả lịch sử"),
        content: Text("Bạn có chắc muốn xóa toàn bộ kho đã xuất không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("Hủy"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      for (var kho in _danhSachKho.where((k) => k.trangThai == "Đã xuất")) {
        await ApiService.xoaKhoHang(kho.id);
      }
      _loadDanhSach();
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat("dd/MM/yyyy").format(date);
  }

  // ✅ format tiền VND
  String _formatCurrency(num? value) {
    if (value == null) return "0 đ";
    final formatter = NumberFormat("#,###", "vi_VN");
    return "${formatter.format(value)} đ";
  }

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
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Bên trái
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Danh sách kho hàng",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          today,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    // Logo app
                    Row(
                      children: const [
                        Icon(Icons.warehouse, color: Colors.white, size: 28),
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
                // ✅ Search bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Tìm kiếm kho hàng...",
                      border: InputBorder.none,
                      icon: Icon(Icons.search, color: Colors.grey),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchText = value;
                        _applySearch();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // ✅ TabBar (thêm nút xóa ở tab Lịch sử)
          Material(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF4A00E0),
              labelColor: const Color(0xFF4A00E0),
              unselectedLabelColor: Colors.grey,
              tabs: [
                Tab(text: "Đang hoạt động"),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Đã Xuất Kho"),
                      const SizedBox(width: 4),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        icon: Icon(
                          Icons.delete_forever,
                          color: Colors.red,
                          size: 20,
                        ),
                        onPressed: _xoaTatCaLichSu,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ✅ Nội dung
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [_buildList("Hoạt động"), _buildList("Đã xuất")],
                  ),
          ),
        ],
      ),

      // ✅ FloatingActionButton thêm kho
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF4A00E0),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ThemKhoHangScreen()),
          );
          if (result == true) _loadDanhSach();
        },
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

  // ✅ Danh sách kho
  Widget _buildList(String trangThai) {
    final ds = _filteredKho.where((k) => k.trangThai == trangThai).toList();
    ds.sort(
      (a, b) => (a.ngayNhap ?? DateTime.now()).compareTo(
        b.ngayNhap ?? DateTime.now(),
      ),
    );

    if (ds.isEmpty) return Center(child: Text("Không có dữ liệu"));

    return ListView.builder(
      itemCount: ds.length,
      itemBuilder: (context, index) {
        final kho = ds[index];
        DateTime start = kho.ngayNhap ?? DateTime.now();
        DateTime end = kho.ngayXuat ?? DateTime.now();
        int soNgay = end.difference(start).inDays;

        Color statusColor = kho.trangThai == "Hoạt động"
            ? Colors.green
            : Colors.grey;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            child: InkWell(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChiTietKhoHangScreen(kho: kho),
                  ),
                );
                if (result != null) _loadDanhSach();
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: statusColor,
                      child: Text(
                        kho.tenKho!.substring(0, 1).toUpperCase(),
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tên kho
                          Text(
                            kho.tenKho ?? "",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          // ✅ Ghi chú
                          if (kho.ghiChu != null && kho.ghiChu!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                kho.ghiChu!,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),

                          SizedBox(height: 4),

                          // Ngày nhập - xuất
                          Text(
                            "Ngày nhập: ${_formatDate(start)}"
                            "${kho.ngayXuat != null ? " | Ngày xuất: ${_formatDate(end)}" : ""}",
                            style: TextStyle(color: Colors.grey[700]),
                          ),

                          // Số ngày tồn kho
                          if (soNgay > 0)
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "$soNgay ngày trong kho",
                                style: TextStyle(
                                  color: Colors.blue[800],
                                  fontSize: 12,
                                ),
                              ),
                            ),

                          // Giá trị
                          if (kho.giaTri != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                "Giá trị: ${_formatCurrency(kho.giaTri)}",
                                style: TextStyle(
                                  color: Colors.deepPurple,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.orange),
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ThemKhoHangScreen(kho: kho),
                              ),
                            );
                            if (result == true) _loadDanhSach();
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _xoaKhoHang(kho.id),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
