import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/nhanvien.dart';
import '../models/workday.dart';
import '../services/api_service.dart';
import 'them_nhan_vien_screen.dart';
import '../api_config.dart';
import 'xem_anh_screen.dart';
import 'package:url_launcher/url_launcher.dart';

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

  // ✅ 1. Thêm biến để theo dõi sự thay đổi
  bool _hasChanged = false;

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

  Future<void> _goiDienThoai(String soDienThoai) async {
    final Uri uri = Uri(scheme: 'tel', path: soDienThoai);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw 'Không thể mở ứng dụng gọi điện';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở ứng dụng gọi điện')),
      );
    }
  }

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
    if (updated != null) {
      setState(() => nhanVien = updated);
      _hasChanged = true; // ✅ 2. Đánh dấu có thay đổi
    }
  }

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
    if (updated != null) {
      setState(() => nhanVien = updated);
      _hasChanged = true; // ✅ 2. Đánh dấu có thay đổi
    }
  }

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
    if (updated != null) {
      setState(() => nhanVien = updated);
      _hasChanged = true; // ✅ 2. Đánh dấu có thay đổi
    }
  }

  Future<void> _suaNhanVien() async {
    if (nhanVien == null) return;

    final updatedNhanVien = await Navigator.push<NhanVien>(
      context,
      MaterialPageRoute(builder: (_) => ThemNhanVienScreen(nhanVien: nhanVien)),
    );

    if (updatedNhanVien != null) {
      setState(() => nhanVien = updatedNhanVien);
      _hasChanged = true; // ✅ 2. Đánh dấu có thay đổi
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (nhanVien == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('❌ Không tìm thấy nhân viên')),
      );
    }

    double tongTienDaNhan = nhanVien!.workDays.fold(
      0,
      (prev, wd) => prev + (nhanVien!.luongTheoGio * wd.soGio),
    );

    // ✅ 3. Bọc Scaffold bằng WillPopScope để xử lý nút back vật lý
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _hasChanged);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Chi tiết ${nhanVien!.hoTen}'),
          // ✅ 4. Xử lý nút back trên AppBar
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _hasChanged),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              Center(
                child: GestureDetector(
                  onTap: () {
                    if (nhanVien!.anhDaiDien != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => XemAnhScreen(
                            imageUrl: ApiService.getAnhUrl(
                              nhanVien!.anhDaiDien,
                            ),
                            heroTag: 'avatar_${nhanVien!.id}',
                          ),
                        ),
                      );
                    }
                  },
                  child: Hero(
                    tag: 'avatar_${nhanVien!.id}',
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: nhanVien!.anhDaiDien != null
                          ? NetworkImage(
                              ApiService.getAnhUrl(nhanVien!.anhDaiDien),
                            )
                          : null,
                      child: nhanVien!.anhDaiDien == null
                          ? const Icon(Icons.person, size: 60)
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('📞 SĐT: ${nhanVien!.soDienThoai}'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  if (nhanVien!.soDienThoai != null &&
                      nhanVien!.soDienThoai!.isNotEmpty) {
                    _goiDienThoai(nhanVien!.soDienThoai!);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Nhân viên chưa có số điện thoại'),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.phone, color: Colors.white, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'GỌI NGAY',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
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
      ),
    );
  }
}
