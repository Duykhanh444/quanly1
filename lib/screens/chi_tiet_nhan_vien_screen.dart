import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/nhanvien.dart';
import '../models/workday.dart';
import '../services/api_service.dart';
import 'them_nhan_vien_screen.dart';
import '../api_config.dart'; // ✅ thêm import ApiConfig

class ChiTietNhanVienScreen extends StatefulWidget {
  final int nhanVienId;
  const ChiTietNhanVienScreen({Key? key, required this.nhanVienId})
    : super(key: key);

  @override
  State<ChiTietNhanVienScreen> createState() => _ChiTietNhanVienScreenState();
}

class _ChiTietNhanVienScreenState extends State<ChiTietNhanVienScreen> {
  NhanVien? nhanVien;
  bool isLoading = true;
  final NumberFormat _currencyFormatter = NumberFormat('#,###', 'vi_VN');

  @override
  void initState() {
    super.initState();
    _loadNhanVien();
  }

  Future<void> _loadNhanVien() async {
    setState(() => isLoading = true);
    nhanVien = await ApiService.layChiTietNhanVien(widget.nhanVienId);
    setState(() => isLoading = false);
  }

  String _formatVND(double value) =>
      '${_currencyFormatter.format(value.round())} ₫';

  // --- Thêm ngày công ---
  Future<void> _themNgayLam() async {
    if (nhanVien == null) return;

    final ngayPicked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (ngayPicked == null) return;

    final gioController = TextEditingController();
    final soGio = await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nhập số giờ làm'),
        content: TextField(
          controller: gioController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Số giờ'),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, int.tryParse(gioController.text)),
            child: const Text('Thêm'),
          ),
        ],
      ),
    );

    if (soGio == null) return;

    final wd = WorkDay(id: 0, ngay: ngayPicked, soGio: soGio);
    final updated = await ApiService.chamCong(nhanVien!.id, wd);
    if (updated != null) setState(() => nhanVien = updated);
  }

  // --- Sửa số giờ ---
  Future<void> _suaSoGio(WorkDay wd) async {
    final gioController = TextEditingController(text: wd.soGio.toString());
    final soGioMoi = await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sửa số giờ làm'),
        content: TextField(
          controller: gioController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Số giờ'),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, int.tryParse(gioController.text)),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    if (soGioMoi == null) return;

    final wdUpdated = WorkDay(id: wd.id, ngay: wd.ngay, soGio: soGioMoi);
    final updated = await ApiService.suaWorkDay(nhanVien!.id, wdUpdated);
    if (updated != null) setState(() => nhanVien = updated);
  }

  // --- Xóa ngày công ---
  Future<void> _xoaWorkDay(WorkDay wd) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận'),
        content: Text(
          'Bạn có chắc muốn xóa ngày ${DateFormat('dd/MM/yyyy').format(wd.ngay)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final updated = await ApiService.xoaWorkDay(nhanVien!.id, wd.id);
    if (updated != null) setState(() => nhanVien = updated);
  }

  // --- Sửa nhân viên ---
  Future<void> _suaNhanVien() async {
    if (nhanVien == null) return;

    final updatedNhanVien = await Navigator.push<NhanVien>(
      context,
      MaterialPageRoute(builder: (_) => ThemNhanVienScreen(nhanVien: nhanVien)),
    );

    if (updatedNhanVien != null) setState(() => nhanVien = updatedNhanVien);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (nhanVien == null) {
      return const Scaffold(
        body: Center(child: Text('❌ Không tìm thấy nhân viên')),
      );
    }

    // Tính tổng tiền đã nhận
    double tongTienDaNhan = nhanVien!.workDays.fold(
      0,
      (prev, wd) => prev + (nhanVien!.luongTheoGio * wd.soGio),
    );

    return Scaffold(
      appBar: AppBar(title: Text('Chi tiết ${nhanVien!.hoTen}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundImage: nhanVien!.anhDaiDien != null
                    ? NetworkImage(
                        '${ApiConfig.host}/uploads/${nhanVien!.anhDaiDien}', // ✅ sửa
                      )
                    : null,
                child: nhanVien!.anhDaiDien == null
                    ? const Icon(Icons.person, size: 60)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Text('📞 SĐT: ${nhanVien!.soDienThoai}'),
            Text('🧰 Chức vụ: ${nhanVien!.chucVu}'),
            Text('⏱️ Tổng giờ đã chấm: ${nhanVien!.tongSoGioDaChamCong}'),
            Text('💰 Tổng tiền đã nhận: ${_formatVND(tongTienDaNhan)}'),
            Text('📅 Tổng số buổi: ${nhanVien!.workDays.length}'),
            const Divider(),
            ElevatedButton.icon(
              onPressed: _themNgayLam,
              icon: const Icon(Icons.add),
              label: const Text('Thêm ngày làm'),
            ),
            const SizedBox(height: 12),
            Column(
              children: nhanVien!.workDays.map((wd) {
                return ListTile(
                  title: Text(DateFormat('dd/MM/yyyy').format(wd.ngay)),
                  subtitle: Text(
                    '${wd.soGio} giờ • ${_formatVND(nhanVien!.luongTheoGio * wd.soGio)}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _suaSoGio(wd),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _xoaWorkDay(wd),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _suaNhanVien,
        child: const Icon(Icons.edit),
      ),
    );
  }
}
