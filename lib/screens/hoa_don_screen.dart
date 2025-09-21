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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDanhSach();
  }

  // -------------------- LOAD DANH SÁCH --------------------
  Future<void> _loadDanhSach() async {
    setState(() => _isLoading = true);
    dsHoaDon = await ApiService.layDanhSachHoaDon();
    setState(() => _isLoading = false);
  }

  List<HoaDon> get _chuaThanhToan =>
      dsHoaDon.where((hd) => hd.trangThai != "Đã thanh toán").toList();

  List<HoaDon> get _daThanhToan =>
      dsHoaDon.where((hd) => hd.trangThai == "Đã thanh toán").toList();

  String _formatMoney(int value) =>
      NumberFormat("#,###", "vi_VN").format(value);

  // -------------------- BUILD LIST --------------------
  Widget _buildList(List<HoaDon> list) {
    if (list.isEmpty) {
      return const Center(child: Text("Không có hóa đơn"));
    }

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

        final tenHangList = hd.items.isNotEmpty
            ? hd.items.map((e) => e.tenHang).join("\n")
            : "Chưa có mặt hàng";

        final loaiHoaDon = hd.loaiHoaDon ?? "Chưa chọn";
        final isXuat = hd.loaiHoaDon == "Xuất";
        final loaiColor = hd.loaiHoaDon == null
            ? Colors.grey
            : (isXuat ? Colors.red : Colors.green);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ChiTietHoaDonScreen(hd: hd)),
              );
              if (result == true) _loadDanhSach();
            },
            title: Text(
              loaiHoaDon,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: loaiColor,
              ),
            ),
            subtitle: Text(
              "$tenHangList\nNgày lập: $ngay\nTổng tiền: ${_formatMoney(hd.tongTien)} VND",
              style: const TextStyle(height: 1.4),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  hd.trangThai ?? "",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // -------------------- XÓA TẤT CẢ ĐÃ THANH TOÁN --------------------
  Future<void> _xoaTatCaDaThanhToan() async {
    if (_daThanhToan.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: Text(
          "Bạn có chắc chắn muốn xóa tất cả ${_daThanhToan.length} hóa đơn đã thanh toán?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Xóa"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final results = await Future.wait(
      _daThanhToan.map((hd) => ApiService.xoaHoaDon(hd.id)),
    );

    if (results.every((r) => r == true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã xóa tất cả hóa đơn đã thanh toán.")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Có lỗi xảy ra khi xóa một số hóa đơn.")),
      );
    }

    _loadDanhSach();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Danh sách Hóa đơn"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: "Xóa tất cả đã thanh toán",
            onPressed: _daThanhToan.isEmpty ? null : _xoaTatCaDaThanhToan,
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
              children: [_buildList(_chuaThanhToan), _buildList(_daThanhToan)],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final hd = HoaDon(
            maHoaDon: "HD${DateTime.now().millisecondsSinceEpoch}",
            loaiHoaDon: null,
            items: [],
          );
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ChiTietHoaDonScreen(hd: hd)),
          );
          if (result == true) _loadDanhSach();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
