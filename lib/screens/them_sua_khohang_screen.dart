import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/khohang.dart';

class ThemSuaKhoHangScreen extends StatefulWidget {
  final KhoHang? kho;
  const ThemSuaKhoHangScreen({this.kho, super.key});

  @override
  State<ThemSuaKhoHangScreen> createState() => _ThemSuaKhoHangScreenState();
}

class _ThemSuaKhoHangScreenState extends State<ThemSuaKhoHangScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tenController;
  late TextEditingController _ghiChuController;
  DateTime? _ngayNhap;
  DateTime? _ngayXuat;

  @override
  void initState() {
    super.initState();
    _tenController = TextEditingController(text: widget.kho?.tenKho ?? "");
    _ghiChuController = TextEditingController(text: widget.kho?.ghiChu ?? "");
    _ngayNhap = widget.kho?.ngayNhap ?? DateTime.now();
    _ngayXuat = widget.kho?.ngayXuat;
  }

  Future<void> _chonNgayNhap() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _ngayNhap ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _ngayNhap = picked);
    }
  }

  Future<void> _chonNgayXuat() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _ngayXuat ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _ngayXuat = picked);
    }
  }

  /// Tính số ngày
  int _tinhSoNgay() {
    if (_ngayNhap == null) return 0;
    final end = _ngayXuat ?? DateTime.now();
    return end.difference(_ngayNhap!).inDays;
  }

  Future<void> _luu() async {
    if (_formKey.currentState!.validate()) {
      final kho = KhoHang(
        id: widget.kho?.id ?? 0,
        tenKho: _tenController.text,
        ghiChu: _ghiChuController.text,
        ngayNhap: _ngayNhap,
        ngayXuat: _ngayXuat,
        trangThai: _ngayXuat == null ? "Hoạt động" : "Đã xuất",
      );

      final ketQua = await ApiService.themHoacSuaKhoHang(kho);
      if (ketQua != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Lưu thành công")));
        Navigator.pop(context, true); // báo về để reload danh sách
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Lưu thất bại")));
      }
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final soNgay = _tinhSoNgay();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.kho == null ? "Thêm Kho Hàng" : "Sửa Kho Hàng"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _tenController,
                decoration: const InputDecoration(labelText: "Tên kho"),
                validator: (val) =>
                    val == null || val.isEmpty ? "Nhập tên kho" : null,
              ),
              TextFormField(
                controller: _ghiChuController,
                decoration: const InputDecoration(labelText: "Ghi chú"),
              ),
              const SizedBox(height: 16),

              // Ngày nhập
              ListTile(
                title: Text(
                  _ngayNhap == null
                      ? "Chưa chọn ngày nhập"
                      : "Ngày nhập: ${_formatDate(_ngayNhap!)}",
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _chonNgayNhap,
              ),

              // Ngày xuất
              ListTile(
                title: Text(
                  _ngayXuat == null
                      ? "Chưa xuất"
                      : "Ngày xuất: ${_formatDate(_ngayXuat!)}",
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _chonNgayXuat,
              ),

              // Số ngày
              if (_ngayNhap != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    "Thời gian: $soNgay ngày",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              const SizedBox(height: 20),
              ElevatedButton(onPressed: _luu, child: const Text("Lưu")),
            ],
          ),
        ),
      ),
    );
  }
}
