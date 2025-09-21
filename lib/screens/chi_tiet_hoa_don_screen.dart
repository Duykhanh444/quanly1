import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/hoadon.dart';
import '../models/hoadon_item.dart';
import '../services/api_service.dart';

class ChiTietHoaDonScreen extends StatefulWidget {
  final HoaDon hd;
  const ChiTietHoaDonScreen({Key? key, required this.hd}) : super(key: key);

  @override
  State<ChiTietHoaDonScreen> createState() => _ChiTietHoaDonScreenState();
}

class _ChiTietHoaDonScreenState extends State<ChiTietHoaDonScreen> {
  late HoaDon hd;

  @override
  void initState() {
    super.initState();
    hd = widget.hd;
    hd.ngayLap ??= DateTime.now();
    hd.trangThai ??= "Chưa thanh toán";
    hd.tinhTongTien();
  }

  String formatNumber(int number) =>
      NumberFormat("#,###", "vi_VN").format(number);

  int parseNumber(String text) {
    final digits = text.replaceAll(RegExp(r'[^\d]'), '');
    return int.tryParse(digits) ?? 0;
  }

  // -------------------- LƯU HÓA ĐƠN --------------------
  Future<void> _luuHoaDonVaThoat() async {
    if (hd.loaiHoaDon == null || hd.loaiHoaDon!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng chọn loại hóa đơn")),
      );
      return;
    }

    hd.tinhTongTien();
    final saved = await ApiService.themHoacSuaHoaDon(hd);
    if (saved != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Đã lưu hóa đơn")));
      Navigator.pop(context, true); // trả về true để màn hình danh sách reload
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Lưu hóa đơn thất bại")));
    }
  }

  // -------------------- THANH TOÁN --------------------
  Future<void> _thanhToan() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận thanh toán"),
        content: const Text(
          "Bạn có chắc chắn muốn thanh toán hóa đơn này không?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Xác nhận"),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => hd.trangThai = "Đã thanh toán");
      await _luuHoaDonVaThoat();
    }
  }

  // -------------------- XÓA HÓA ĐƠN --------------------
  Future<void> _xoaHoaDon() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xóa hóa đơn"),
        content: const Text("Bạn có chắc chắn muốn xóa hóa đơn này không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Xóa"),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ApiService.xoaHoaDon(hd.id);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Đã xóa hóa đơn")));
      Navigator.pop(context, true);
    }
  }

  // -------------------- THÊM MẶT HÀNG --------------------
  void _themMatHang() async {
    final tenController = TextEditingController();
    final soLuongController = TextEditingController(text: "1");
    final giaController = TextEditingController(text: "0");

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Thêm mặt hàng"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tenController,
              decoration: const InputDecoration(labelText: "Tên hàng"),
            ),
            TextField(
              controller: soLuongController,
              decoration: const InputDecoration(labelText: "Số lượng"),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            TextField(
              controller: giaController,
              decoration: const InputDecoration(labelText: "Giá tiền (VND)"),
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsFormatter()],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () {
              if (tenController.text.trim().isEmpty) return;
              Navigator.pop(ctx, {
                "ten": tenController.text.trim(),
                "soLuong": int.tryParse(soLuongController.text) ?? 1,
                "gia": parseNumber(giaController.text),
              });
            },
            child: const Text("Thêm"),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        hd.items.add(
          HoaDonItem(
            id: 0,
            tenHang: result["ten"],
            soLuong: result["soLuong"],
            giaTien: result["gia"],
          ),
        );
        hd.tinhTongTien();
      });
    }
  }

  // -------------------- CẬP NHẬT MẶT HÀNG --------------------
  void _capNhatMatHang(int index) async {
    final mh = hd.items[index];
    final tenController = TextEditingController(text: mh.tenHang);
    final soLuongController = TextEditingController(
      text: mh.soLuong.toString(),
    );
    final giaController = TextEditingController(text: formatNumber(mh.giaTien));

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Cập nhật ${mh.tenHang}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tenController,
              decoration: const InputDecoration(labelText: "Tên hàng"),
            ),
            TextField(
              controller: soLuongController,
              decoration: const InputDecoration(labelText: "Số lượng"),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            TextField(
              controller: giaController,
              decoration: const InputDecoration(labelText: "Giá tiền (VND)"),
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsFormatter()],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () {
              if (tenController.text.trim().isEmpty) return;
              Navigator.pop(ctx, {
                "ten": tenController.text.trim(),
                "soLuong": int.tryParse(soLuongController.text) ?? 1,
                "gia": parseNumber(giaController.text),
              });
            },
            child: const Text("Cập nhật"),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        mh.tenHang = result["ten"];
        mh.soLuong = result["soLuong"];
        mh.giaTien = result["gia"];
        hd.tinhTongTien();
      });
    }
  }

  // -------------------- XÓA MẶT HÀNG --------------------
  void _xoaMatHang(int index) {
    setState(() {
      hd.items.removeAt(index);
      hd.tinhTongTien();
    });
  }

  @override
  Widget build(BuildContext context) {
    final daThanhToan = hd.trangThai == "Đã thanh toán";
    final trangThaiColor = daThanhToan ? Colors.green : Colors.orange;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chi tiết hóa đơn"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _xoaHoaDon,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildInfoCard("Mã hóa đơn", hd.maHoaDon),
                  _buildInfoCard(
                    "Ngày lập",
                    DateFormat(
                      'dd-MM-yyyy',
                    ).format(hd.ngayLap ?? DateTime.now()),
                  ),
                  _buildDropdownCard(
                    "Loại hóa đơn",
                    hd.loaiHoaDon,
                    ["Xuất", "Nhập"],
                    (val) => setState(() => hd.loaiHoaDon = val),
                  ),
                  _buildStatusCard("Trạng thái", hd.trangThai!, trangThaiColor),
                  _buildStatusCard(
                    "Tổng tiền",
                    "${formatNumber(hd.tongTien)} VND",
                    Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  ...hd.items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final mh = entry.value;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(mh.tenHang),
                        subtitle: Text(
                          "SL: ${mh.soLuong} x ${formatNumber(mh.giaTien)} = ${formatNumber(mh.thanhTien())} VND",
                        ),
                        trailing: daThanhToan
                            ? null
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.orange,
                                    ),
                                    onPressed: () => _capNhatMatHang(index),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _xoaMatHang(index),
                                  ),
                                ],
                              ),
                      ),
                    );
                  }),
                  if (!daThanhToan)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton(
                          onPressed: _themMatHang,
                          style: _buttonStyle(
                            Colors.purple.shade100,
                            Colors.black87,
                          ),
                          child: const Text("Thêm mặt hàng"),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _luuHoaDonVaThoat,
                          style: _buttonStyle(Colors.blue, Colors.white),
                          child: const Text("Lưu"),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _thanhToan,
                          style: _buttonStyle(Colors.green, Colors.white),
                          child: const Text("Thanh toán"),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  ButtonStyle _buttonStyle(Color bg, Color fg) => ElevatedButton.styleFrom(
    backgroundColor: bg,
    foregroundColor: fg,
    minimumSize: const Size(double.infinity, 50),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );

  Widget _buildInfoCard(String label, String value) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  );

  Widget _buildStatusCard(String label, String value, Color color) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [color.withOpacity(0.7), color]),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );

  Widget _buildDropdownCard(
    String label,
    String? currentValue,
    List<String> options,
    ValueChanged<String> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          SizedBox(
            width: 150,
            child: DropdownButton<String>(
              isExpanded: true,
              value: currentValue.isEmptyOrNull ? null : currentValue,
              hint: const Text("Chưa chọn"),
              underline: const SizedBox(),
              items: options
                  .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
                  .toList(),
              onChanged: (val) {
                if (val != null) onChanged(val);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Formatter số tiền có dấu phẩy
class ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return newValue.copyWith(text: '');
    final formatted = NumberFormat("#,###", "vi_VN").format(int.parse(digits));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// Extension kiểm tra null hoặc empty
extension StringExtension on String? {
  bool get isEmptyOrNull => this == null || this!.isEmpty;
}
