import 'package:flutter/material.dart';
import '../models/khohang.dart';
import '../services/api_service.dart';
import 'chi_tiet_kho_hang_screen.dart';
import 'them_kho_hang_screen.dart';

class KhoHangScreen extends StatefulWidget {
  @override
  _KhoHangScreenState createState() => _KhoHangScreenState();
}

class _KhoHangScreenState extends State<KhoHangScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<KhoHang> _danhSachKho = [];
  bool _isLoading = true;

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
      _isLoading = false;
    });
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
            child: Text("Xóa"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ApiService.xoaKhoHang(id);
      _loadDanhSach();
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Kho Hàng"),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: "Đang Hoạt Động"),
            Tab(text: "Lịch Sử"),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [_buildList("Hoạt động"), _buildList("Đã xuất")],
            ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ThemKhoHangScreen()),
          );
          if (result == true) _loadDanhSach();
        },
      ),
    );
  }

  Widget _buildList(String trangThai) {
    final ds = _danhSachKho.where((k) => k.trangThai == trangThai).toList();
    ds.sort(
      (a, b) => (a.ngayNhap ?? DateTime.now()).compareTo(
        b.ngayNhap ?? DateTime.now(),
      ),
    ); // sắp xếp theo ngày nhập

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
                          Text(
                            kho.tenKho ?? "",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Ngày nhập: ${_formatDate(start)}"
                            "${kho.ngayXuat != null ? " | Ngày xuất: ${_formatDate(end)}" : ""}",
                            style: TextStyle(color: Colors.grey[700]),
                          ),
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
                                "$soNgay ngày tồn kho",
                                style: TextStyle(
                                  color: Colors.blue[800],
                                  fontSize: 12,
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
