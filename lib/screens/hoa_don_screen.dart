// lib/screens/hoa_don_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/hoadon.dart';
import '../services/api_service.dart';
import 'chi_tiet_hoa_don_screen.dart';

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
            child: const Text("Xóa"),
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

              // Sau khi trở về, reload danh sách từ API
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: "Nhập mã hóa đơn...",
                    border: InputBorder.none,
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                )
              : const Text("Danh sách Hóa đơn"),
          actions: [
            if (!_isSearching)
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  setState(() {
                    _isSearching = true;
                    _searchQuery = "";
                    _searchController.clear();
                  });
                },
              )
            else
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _isSearching = false;
                    _searchQuery = "";
                  });
                },
              ),
            IconButton(
              icon: const Icon(Icons.delete_forever),
              onPressed: _daThanhToan.isEmpty ? null : _xoaTatCaDaThanhToan,
              tooltip: "Xóa tất cả đã thanh toán",
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: "Chưa thanh toán"),
              Tab(text: "Đã thanh toán"),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildList(_chuaThanhToan),
                  _buildList(_daThanhToan),
                ],
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final hd = HoaDon(
              id: 0,
              maHoaDon: "HD-${DateTime.now().millisecondsSinceEpoch}",
              loaiHoaDon: null,
              items: [],
              phuongThuc: null, // chưa chọn
              trangThai: "Chưa thanh toán",
              ngayLap: DateTime.now(),
            );

            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ChiTietHoaDonScreen(hd: hd)),
            );

            _loadDanhSach();
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
