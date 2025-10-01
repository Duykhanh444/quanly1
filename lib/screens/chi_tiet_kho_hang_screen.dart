import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/khohang.dart';
import '../models/hoadon.dart';
import '../models/hoadon_item.dart';
import '../services/api_service.dart';
import 'bill_screen.dart';

class ChiTietKhoHangScreen extends StatelessWidget {
  final KhoHang kho;
  const ChiTietKhoHangScreen({required this.kho, super.key});

  // Format ngày dd-MM-yyyy
  String _formatDate(DateTime? date) {
    if (date == null) return "—";
    return DateFormat("dd-MM-yyyy").format(date);
  }

  // Tính số ngày giữa nhập & xuất
  int _tinhSoNgay(DateTime? start, DateTime? end) {
    if (start == null) return 0;
    final ngayKetThuc = end ?? DateTime.now();
    return ngayKetThuc.difference(start).inDays;
  }

  // Format giá trị VNĐ
  String _formatCurrency(double? value) {
    if (value == null) return "0 đ";
    final formatter = NumberFormat.currency(
      locale: "vi_VN",
      symbol: "đ",
      decimalDigits: 0,
    );
    return formatter.format(value);
  }

  // Thẻ hiển thị thông tin
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

  // Thanh toán & xuất kho
  Future<void> _xuatKho(BuildContext context, String phuongThuc) async {
    final hoaDon = HoaDon(
      id: 0,
      maHoaDon: "HD${DateTime.now().millisecondsSinceEpoch}",
      ngayLap: DateTime.now(),
      tongTien: kho.giaTri?.toInt() ?? 0,
      trangThai: "Đã thanh toán",
      items: [
        HoaDonItem(
          tenHang: kho.tenKho ?? "Kho hàng",
          soLuong: 1,
          giaTien: kho.giaTri?.toInt() ?? 0,
        ),
      ],
    );

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BillScreen(
          hoaDon: hoaDon,
          phuongThuc: phuongThuc,
          onConfirmPayment: () async {
            final updatedKho = await ApiService.capNhatKhoHang(
              KhoHang(
                id: kho.id,
                tenKho: kho.tenKho,
                ghiChu: kho.ghiChu,
                giaTri: kho.giaTri,
                ngayNhap: kho.ngayNhap,
                ngayXuat: DateTime.now(),
                trangThai: "Đã xuất",
              ),
            );

            if (updatedKho != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Xuất kho & thanh toán thành công!"),
                ),
              );
              Navigator.pop(context, updatedKho);
            }
          },
        ),
      ),
    );
  }

  // Hỏi chọn phương thức thanh toán
  Future<void> _chonPhuongThucThanhToan(BuildContext context) async {
    final phuongThuc = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Chọn phương thức thanh toán"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.money, color: Colors.green),
              title: const Text("Tiền mặt"),
              onTap: () => Navigator.pop(ctx, "Tiền mặt"),
            ),
            ListTile(
              leading: const Icon(Icons.qr_code, color: Colors.blue),
              title: const Text("Chuyển khoản"),
              onTap: () => Navigator.pop(ctx, "Chuyển khoản"),
            ),
          ],
        ),
      ),
    );

    if (phuongThuc != null) {
      _xuatKho(context, phuongThuc);
    }
  }

  // Hoàn tác xuất kho
  Future<void> _hoanTac(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hoàn tác"),
        content: const Text(
          "Bạn có chắc muốn hoàn tác kho này về trạng thái hoạt động không?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Hoàn tác"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final updatedKho = await ApiService.capNhatKhoHang(
        KhoHang(
          id: kho.id,
          tenKho: kho.tenKho,
          ghiChu: kho.ghiChu,
          giaTri: kho.giaTri,
          ngayNhap: kho.ngayNhap,
          trangThai: "Hoạt động",
          ngayXuat: null,
        ),
      );

      if (updatedKho != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Hoàn tác thành công!")));
        Navigator.pop(context, updatedKho);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Hoàn tác thất bại.")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final soNgay = _tinhSoNgay(kho.ngayNhap, kho.ngayXuat);

    return Scaffold(
      appBar: AppBar(title: const Text("Chi tiết kho")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _buildInfoCard("Tên kho", kho.tenKho ?? ""),
            _buildInfoCard("Ghi chú", kho.ghiChu ?? ""),
            _buildInfoCard("Giá trị", _formatCurrency(kho.giaTri)),
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
                  onPressed: () => _chonPhuongThucThanhToan(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "🚚 Xuất & Thanh toán",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            if (kho.trangThai == "Đã xuất")
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _hoanTac(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "↩️ Hoàn tác",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
