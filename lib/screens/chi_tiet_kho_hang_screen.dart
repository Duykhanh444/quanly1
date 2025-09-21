import 'package:flutter/material.dart';
import '../models/khohang.dart';
import '../services/api_service.dart';

class ChiTietKhoHangScreen extends StatelessWidget {
  final KhoHang kho;
  const ChiTietKhoHangScreen({required this.kho, super.key});

  String _formatDate(DateTime? date) {
    if (date == null) return "—";
    return "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}";
  }

  int _tinhSoNgay(DateTime? start, DateTime? end) {
    if (start == null) return 0;
    final ngayKetThuc = end ?? DateTime.now();
    return ngayKetThuc.difference(start).inDays;
  }

  Widget _buildInfoCard(String title, String value, {Color? color}) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: color != null
              ? LinearGradient(
                  colors: [color.withOpacity(0.7), color],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color != null ? Colors.white : Colors.black,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color != null ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _xuatKho(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Xuất kho"),
        content: Text("Bạn có chắc muốn xuất kho này không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("Hủy"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text("Xuất"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final updatedKho = await ApiService.capNhatKhoHang(
        KhoHang(
          id: kho.id!,
          tenKho: kho.tenKho!,
          ghiChu: kho.ghiChu,
          ngayNhap: kho.ngayNhap,
          trangThai: "Đã xuất",
          ngayXuat: DateTime.now(),
        ),
      );

      if (updatedKho != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Xuất kho thành công!")));
        Navigator.pop(context, updatedKho);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Xuất kho thất bại.")));
      }
    }
  }

  Future<void> _hoanTac(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Hoàn tác"),
        content: Text(
          "Bạn có chắc muốn hoàn tác kho này về trạng thái hoạt động không?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("Hủy"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text("Hoàn tác"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final updatedKho = await ApiService.capNhatKhoHang(
        KhoHang(
          id: kho.id!,
          tenKho: kho.tenKho!,
          ghiChu: kho.ghiChu,
          ngayNhap: kho.ngayNhap,
          trangThai: "Hoạt động",
          ngayXuat: null,
        ),
      );

      if (updatedKho != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Hoàn tác thành công!")));
        Navigator.pop(context, updatedKho);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Hoàn tác thất bại.")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final soNgay = _tinhSoNgay(kho.ngayNhap, kho.ngayXuat);

    return Scaffold(
      appBar: AppBar(title: Text("Chi tiết kho")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _buildInfoCard("Tên kho", kho.tenKho ?? ""),
            _buildInfoCard("Ghi chú", kho.ghiChu ?? ""),
            _buildInfoCard("Ngày nhập", _formatDate(kho.ngayNhap)),
            _buildInfoCard("Ngày xuất", _formatDate(kho.ngayXuat)),
            _buildInfoCard(
              "Trạng thái",
              kho.trangThai ?? "",
              color: kho.trangThai == "Đã xuất" ? Colors.grey : Colors.green,
            ),
            if (kho.ngayNhap != null)
              _buildInfoCard(
                "Số ngày trong kho",
                "$soNgay ngày",
                color: Colors.blue,
              ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            if (kho.trangThai != "Đã xuất")
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _xuatKho(context),
                  child: Text("Xuất kho"),
                ),
              ),
            if (kho.trangThai == "Đã xuất") ...[
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _hoanTac(context),
                  child: Text("Hoàn tác"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
