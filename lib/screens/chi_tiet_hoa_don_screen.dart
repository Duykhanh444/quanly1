// lib/screens/chi_tiet_hoa_don_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/hoadon.dart';
import '../models/hoadon_item.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'bill_screen.dart';

class ChiTietHoaDonScreen extends StatefulWidget {
  // ✨ SỬA 1: Cho phép 'hd' có thể là null (khi tạo mới)
  final HoaDon? hd;
  final VoidCallback? onDaThanhToan;

  const ChiTietHoaDonScreen({Key? key, this.hd, this.onDaThanhToan})
    : super(key: key);

  @override
  State<ChiTietHoaDonScreen> createState() => _ChiTietHoaDonScreenState();
}

class _ChiTietHoaDonScreenState extends State<ChiTietHoaDonScreen> {
  late HoaDon hd;
  bool _isLoading = true;
  bool _isCreatingNew =
      false; // Biến để xác định là đang tạo mới hay xem chi tiết

  @override
  void initState() {
    super.initState();
    // ✨ SỬA 2: KIỂM TRA XEM ĐÂY LÀ TRƯỜNG HỢP TẠO MỚI HAY XEM CHI TIẾT
    if (widget.hd == null) {
      // ---- TRƯỜNG HỢP TẠO MỚI ----
      setState(() {
        _isCreatingNew = true;
        // Tạo một hóa đơn rỗng với thông tin mặc định
        hd = HoaDon(
          id: 0,
          maHoaDon:
              "HD-${DateTime.now().millisecondsSinceEpoch}", // Tạo mã ngẫu nhiên
          ngayLap: DateTime.now(),
          tongTien: 0,
          trangThai: "Chưa thanh toán",
          items: [],
        );
        _isLoading = false; // Không cần tải gì cả, sẵn sàng để nhập liệu
      });
    } else {
      // ---- TRƯỜNG HỢP XEM CHI TIẾT ----
      _isCreatingNew = false;
      hd = widget.hd!;
      _fetchHoaDonDetails(); // Tải chi tiết như cũ
    }
  }

  // Hàm này giờ chỉ chạy khi xem chi tiết hóa đơn có sẵn
  Future<void> _fetchHoaDonDetails() async {
    // Nếu đang tạo mới thì không chạy hàm này
    if (_isCreatingNew) return;

    try {
      final hoaDonChiTiet = await ApiService.layChiTietHoaDon(widget.hd!.id);
      if (mounted) {
        if (hoaDonChiTiet != null) {
          setState(() {
            hd = hoaDonChiTiet;
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Không thể tải chi tiết hóa đơn")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Lỗi tải dữ liệu: $e")));
      }
    }
  }

  // ==========================================================
  //     CÁC HÀM CÒN LẠI GIỮ NGUYÊN HOẶC CẬP NHẬT NHỎ
  // ==========================================================

  String formatNumber(int number) =>
      NumberFormat("#,###", "vi_VN").format(number);

  int parseNumber(String text) {
    final digits = text.replaceAll(RegExp(r'[^\d]'), '');
    return int.tryParse(digits) ?? 0;
  }

  bool get _daThanhToan => hd.trangThai == "Đã thanh toán";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // ✨ SỬA 3: Tiêu đề động
        title: Text(_isCreatingNew ? "Tạo Hóa Đơn Mới" : "Chi tiết hóa đơn"),
        actions: [
          // Chỉ hiện nút xóa khi đang xem hóa đơn cũ và chưa thanh toán
          if (!_isLoading && !_isCreatingNew && !_daThanhToan)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _xoaHoaDon,
            ),
          if (!_isLoading && _daThanhToan) ...[
            IconButton(
              icon: const Icon(Icons.print_outlined),
              onPressed: _inHoaDonPdf,
            ),
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: _shareHoaDonPdf,
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildHeaderCard(),
                      const SizedBox(height: 16),
                      _buildSummaryCard(),
                      const SizedBox(height: 16),
                      _buildItemList(),
                    ],
                  ),
                ),
                // Chỉ hiện nút "Lưu" và "Thanh toán" khi chưa thanh toán
                if (!_daThanhToan) _buildActionButtons(),
              ],
            ),
    );
  }

  // ... (Các hàm build UI như _buildHeaderCard, _buildSummaryCard, ... giữ nguyên)
  Widget _buildHeaderCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.qr_code_scanner,
            label: "Mã hóa đơn",
            value: hd.maHoaDon,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildInfoRow(
            icon: Icons.calendar_today_outlined,
            label: "Ngày lập",
            value: DateFormat('dd/MM/yyyy').format(hd.ngayLap!),
            onTap: _daThanhToan ? null : _chonNgayLap,
            trailing: _daThanhToan
                ? null
                : const Icon(
                    Icons.edit_calendar_outlined,
                    size: 20,
                    color: Colors.blue,
                  ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildDropdownRow(
            icon: Icons.receipt_long_outlined,
            label: "Loại hóa đơn",
            value: hd.loaiHoaDon,
            options: ["Nhập", "Xuất"],
            onChanged: (val) => setState(() => hd.loaiHoaDon = val),
            enabled: !_daThanhToan,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildDropdownRow(
            icon: Icons.payment_outlined,
            label: "Phương thức",
            value: hd.phuongThuc,
            options: ["Tiền mặt", "Chuyển khoản"],
            onChanged: (val) => setState(() => hd.phuongThuc = val),
            enabled: !_daThanhToan,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final statusColor = _daThanhToan ? Colors.green : Colors.orange;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Trạng thái",
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    hd.trangThai ?? "N/A",
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              "Tổng cộng",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              "${formatNumber(hd.tongTien)} VND",
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6200EE), // Màu tím giống layout
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "DANH SÁCH MẶT HÀNG (${hd.items.length})",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            if (!_daThanhToan)
              TextButton.icon(
                onPressed: _themMatHang,
                icon: const Icon(Icons.add, size: 16),
                label: const Text("Thêm"),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (hd.items.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                "Chưa có mặt hàng nào.",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ...hd.items.asMap().entries.map((entry) {
            final i = entry.key;
            final mh = entry.value;
            return Card(
              elevation: 1,
              margin: const EdgeInsets.symmetric(vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                title: Text(
                  mh.tenHang,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "SL: ${mh.soLuong} x ${formatNumber(mh.giaTien)}",
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "${formatNumber(mh.thanhTien())} VND",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (!_daThanhToan) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Colors.blueGrey,
                          size: 20,
                        ),
                        onPressed: () => _capNhatMatHang(i),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                        onPressed: () => _xoaMatHang(i),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _luuHoaDonVaThoat,
              child: const Text("Lưu"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6200EE),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _thanhToan,
              child: const Text("Thanh toán"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ... Các hàm logic ...
  Future<void> _luuHoaDonVaThoat() async {
    if (hd.loaiHoaDon == null || hd.loaiHoaDon!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng chọn loại hóa đơn")),
      );
      return;
    }
    if (hd.phuongThuc == null || hd.phuongThuc!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng chọn phương thức thanh toán")),
      );
      return;
    }

    hd.tinhTongTien();
    final result = await ApiService.themHoacSuaHoaDon(hd);
    if (result != null) {
      if (mounted) {
        // ✨ KÍCH HOẠT THÔNG BÁO KHI LƯU
        Provider.of<NotificationService>(
          context,
          listen: false,
        ).addNotification(
          title: _isCreatingNew ? 'Tạo Hóa Đơn Mới' : 'Cập Nhật Hóa Đơn',
          body: 'Hóa đơn mã "${result.maHoaDon}" đã được lưu thành công.',
        );
        Navigator.pop(context, result);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Lưu hóa đơn thất bại, vui lòng thử lại"),
          ),
        );
      }
    }
  }

  Future<void> _thanhToan() async {
    // ... code giữ nguyên
    if (hd.phuongThuc == null || hd.phuongThuc!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng chọn phương thức thanh toán")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BillScreen(
          hoaDon: hd,
          phuongThuc: hd.phuongThuc!,
          onConfirmPayment: () async {
            setState(() => hd.trangThai = "Đã thanh toán");
            final saved = await ApiService.themHoacSuaHoaDon(hd);
            if (saved != null) {
              Provider.of<NotificationService>(
                context,
                listen: false,
              ).addNotification(
                title: 'Thanh Toán Thành Công',
                body: 'Hóa đơn mã "${saved.maHoaDon}" đã được thanh toán.',
              );

              if (mounted) Navigator.pop(context, saved);
              widget.onDaThanhToan?.call();
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Thanh toán thất bại, vui lòng thử lại"),
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }

  // ... Các hàm helper, xóa, in, share, ... giữ nguyên không đổi
  // (Tôi sẽ lược bỏ để code ngắn gọn, bạn chỉ cần giữ nguyên các hàm này trong file của bạn)

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey.shade600, size: 20),
            const SizedBox(width: 16),
            Text(label),
            const Spacer(),
            if (trailing != null) ...[
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              trailing,
            ] else
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownRow({
    required IconData icon,
    required String label,
    String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 20),
          const SizedBox(width: 16),
          Text(label),
          const Spacer(),
          enabled
              ? DropdownButton<String>(
                  value: value,
                  hint: const Text("Chọn..."),
                  underline: const SizedBox(),
                  items: options
                      .map(
                        (opt) => DropdownMenuItem(value: opt, child: Text(opt)),
                      )
                      .toList(),
                  onChanged: onChanged,
                )
              : Text(
                  value ?? "N/A",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
        ],
      ),
    );
  }

  Future<void> _chonNgayLap() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: hd.ngayLap ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => hd.ngayLap = picked);
  }

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
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: "Số lượng"),
            ),
            TextField(
              controller: giaController,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsFormatter()],
              decoration: const InputDecoration(labelText: "Giá tiền (VND)"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
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
            tenHang: result["ten"],
            soLuong: result["soLuong"],
            giaTien: result["gia"],
          ),
        );
        hd.tinhTongTien();
      });
    }
  }

  void _capNhatMatHang(int index) async {
    final item = hd.items[index];
    final tenController = TextEditingController(text: item.tenHang);
    final soLuongController = TextEditingController(
      text: item.soLuong.toString(),
    );
    final giaController = TextEditingController(
      text: formatNumber(item.giaTien),
    );

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Cập nhật mặt hàng"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tenController,
              decoration: const InputDecoration(labelText: "Tên hàng"),
            ),
            TextField(
              controller: soLuongController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: "Số lượng"),
            ),
            TextField(
              controller: giaController,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsFormatter()],
              decoration: const InputDecoration(labelText: "Giá tiền (VND)"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () {
              if (tenController.text.trim().isEmpty) return;
              Navigator.pop(ctx, {
                "ten": tenController.text.trim(),
                "soLuong": int.tryParse(soLuongController.text) ?? 1,
                "gia": parseNumber(giaController.text),
              });
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        hd.items[index]
          ..tenHang = result["ten"]
          ..soLuong = result["soLuong"]
          ..giaTien = result["gia"];
        hd.tinhTongTien();
      });
    }
  }

  void _xoaMatHang(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xóa mặt hàng"),
        content: Text(
          "Bạn có chắc muốn xóa '${hd.items[index].tenHang}' không?",
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

    if (confirm == true) {
      setState(() {
        hd.items.removeAt(index);
        hd.tinhTongTien();
      });
    }
  }

  Future<void> _xoaHoaDon() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xóa hóa đơn"),
        content: const Text("Bạn có chắc chắn muốn xóa hóa đơn này?"),
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
    if (confirm == true) {
      final deleted = await ApiService.xoaHoaDon(hd.id);
      if (deleted) {
        if (mounted) Navigator.pop(context, null);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Xóa hóa đơn thất bại")));
        }
      }
    }
  }

  Future<Uint8List> _generateHoaDonPdf() async {
    final pdf = pw.Document();
    final font = pw.Font.ttf(
      await rootBundle.load('assets/fonts/DejaVuSans.ttf'),
    );
    final fontBold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/DejaVuSans-Bold.ttf'),
    );
    final qrUrl =
        "https://img.vietqr.io/image/MB-9704229999-compact2.png?amount=${hd.tongTien}&addInfo=Thanh%20toan%20HD%20${hd.maHoaDon}";
    final qrImage = (await networkImage(qrUrl));

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  "HÓA ĐƠN BÁN HÀNG",
                  style: pw.TextStyle(font: fontBold, fontSize: 20),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                "Mã hóa đơn: ${hd.maHoaDon}",
                style: pw.TextStyle(font: font),
              ),
              pw.Text(
                "Ngày lập: ${DateFormat('dd/MM/yyyy HH:mm').format(hd.ngayLap!)}",
                style: pw.TextStyle(font: font),
              ),
              pw.Text(
                "Phương thức: ${hd.phuongThuc}",
                style: pw.TextStyle(font: font),
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ["Tên hàng", "SL", "Giá", "Thành tiền"],
                headerStyle: pw.TextStyle(font: fontBold),
                cellStyle: pw.TextStyle(font: font),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey300,
                ),
                data: hd.items
                    .map(
                      (e) => [
                        e.tenHang,
                        "${e.soLuong}",
                        formatNumber(e.giaTien),
                        formatNumber(e.thanhTien()),
                      ],
                    )
                    .toList(),
              ),
              pw.SizedBox(height: 20),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  "Tổng tiền: ${formatNumber(hd.tongTien)} VND",
                  style: pw.TextStyle(font: fontBold, fontSize: 14),
                ),
              ),
              pw.SizedBox(height: 30),
              pw.Center(child: pw.Image(qrImage, width: 120, height: 120)),
              pw.Center(
                child: pw.Text(
                  "Quét mã VietQR để thanh toán",
                  style: pw.TextStyle(font: font, fontSize: 10),
                ),
              ),
              pw.Spacer(),
              pw.Center(
                child: pw.Text(
                  "Xin cảm ơn quý khách!",
                  style: pw.TextStyle(font: fontBold, fontSize: 12),
                ),
              ),
            ],
          );
        },
      ),
    );
    return pdf.save();
  }

  Future<void> _inHoaDonPdf() async {
    final bytes = await _generateHoaDonPdf();
    await Printing.layoutPdf(onLayout: (format) async => bytes);
  }

  Future<void> _shareHoaDonPdf() async {
    final bytes = await _generateHoaDonPdf();
    final file = XFile.fromData(
      bytes,
      name: "HoaDon_${hd.maHoaDon}.pdf",
      mimeType: "application/pdf",
    );
    await Share.shareXFiles([file], text: "Hóa đơn ${hd.maHoaDon}");
  }
}

class ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return newValue.copyWith(text: '');
    final number = int.parse(digits);
    final newText = NumberFormat("#,###", "vi_VN").format(number);
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
