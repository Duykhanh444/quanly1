// lib/screens/them_hoa_don_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/hoadon.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class ThemHoaDonScreen extends StatefulWidget {
  const ThemHoaDonScreen({Key? key}) : super(key: key);

  @override
  State<ThemHoaDonScreen> createState() => _ThemHoaDonScreenState();
}

class _ThemHoaDonScreenState extends State<ThemHoaDonScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _maHoaDonController = TextEditingController();
  final TextEditingController _tongTienController = TextEditingController();
  DateTime? _ngayLap;
  String _trangThai = "Chưa thanh toán";

  @override
  void initState() {
    super.initState();
    _ngayLap = DateTime.now();
  }

  @override
  void dispose() {
    _maHoaDonController.dispose();
    _tongTienController.dispose();
    super.dispose();
  }

  Future<void> _chonNgay() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _ngayLap ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() => _ngayLap = picked);
    }
  }

  Future<void> _themHoaDon() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng điền đầy đủ thông tin")),
      );
      return;
    }

    final ngayHoaDon = _ngayLap ?? DateTime.now();

    final hoaDonMoi = HoaDon(
      id: 0,
      maHoaDon: _maHoaDonController.text.trim(),
      tongTien: int.tryParse(_tongTienController.text.trim()) ?? 0,
      ngayLap: ngayHoaDon,
      trangThai: _trangThai,
      items: const [],
    );

    try {
      final result = await ApiService.themHoaDon(hoaDonMoi);
      if (result != null) {
        if (!mounted) return;

        // ✨ KÍCH HOẠT THÔNG BÁO TẠI ĐÂY
        Provider.of<NotificationService>(
          context,
          listen: false,
        ).addNotification(
          title: 'Tạo Hóa Đơn Mới',
          body: 'Hóa đơn mã "${result.maHoaDon}" đã được tạo thành công.',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Thêm hóa đơn thành công"),
            action: SnackBarAction(
              label: 'Hoàn tác',
              onPressed: () async {
                await ApiService.xoaHoaDon(result.id);
                if (!mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("Đã hoàn tác")));
              },
            ),
          ),
        );
        Navigator.pop(context, result);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Không thêm được hóa đơn")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi khi thêm hóa đơn: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Thêm Hóa Đơn")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _maHoaDonController,
                decoration: const InputDecoration(
                  labelText: "Mã Hóa Đơn",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    (value == null || value.isEmpty) ? "Nhập mã hóa đơn" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tongTienController,
                decoration: const InputDecoration(
                  labelText: "Tổng tiền (VND)",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    (value == null || value.isEmpty) ? "Nhập tổng tiền" : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _ngayLap == null
                      ? "Chọn ngày lập"
                      : "Ngày lập: ${_ngayLap!.day}-${_ngayLap!.month}-${_ngayLap!.year}",
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _chonNgay,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _trangThai,
                items: const [
                  DropdownMenuItem(
                    value: "Chưa thanh toán",
                    child: Text("Chưa thanh toán"),
                  ),
                  DropdownMenuItem(
                    value: "Đã thanh toán",
                    child: Text("Đã thanh toán"),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _trangThai = value);
                },
                decoration: const InputDecoration(
                  labelText: "Trạng thái",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _themHoaDon,
                child: const Text("Thêm Hóa Đơn"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
