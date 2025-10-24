import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/nhanvien.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../api_config.dart';
import 'them_nhan_vien_screen.dart';
import 'chi_tiet_nhan_vien_screen.dart';

class DanhSachNhanVienScreen extends StatefulWidget {
  const DanhSachNhanVienScreen({Key? key}) : super(key: key);

  @override
  State<DanhSachNhanVienScreen> createState() => _DanhSachNhanVienScreenState();
}

class _DanhSachNhanVienScreenState extends State<DanhSachNhanVienScreen> {
  List<NhanVien> danhSachNhanVien = [];
  List<NhanVien> danhSachLoc = [];
  bool isLoading = true;
  final NumberFormat numberFormat = NumberFormat('#,###', 'vi_VN');
  final TextEditingController _searchController = TextEditingController();
  final int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadDanhSach();
    ApiConfig.hostNotifier.addListener(() {
      _loadDanhSach();
    });
    _searchController.addListener(() {
      _locNhanVien(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDanhSach() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    await Future.wait([
      ApiService.layDanhSachNhanVien().then((list) {
        if (mounted) {
          setState(() {
            danhSachNhanVien = list ?? [];
            _locNhanVien(_searchController.text);
          });
        }
      }),
      Provider.of<NotificationService>(
        context,
        listen: false,
      ).loadNotifications(),
    ]);

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _locNhanVien(String query) {
    setState(() {
      if (query.isEmpty) {
        danhSachLoc = List.from(danhSachNhanVien);
      } else {
        danhSachLoc = danhSachNhanVien.where((nv) {
          final ten = nv.hoTen.toLowerCase();
          final sdt = (nv.soDienThoai ?? "").toLowerCase();
          final q = query.toLowerCase();
          return ten.contains(q) || sdt.contains(q);
        }).toList();
      }
    });
  }

  String formatVND(double value) => numberFormat.format(value);

  double _tinhTongLuongTatCa() {
    return danhSachNhanVien.fold(
      0,
      (sum, nv) => sum + (nv.tongTienDaNhan ?? 0),
    );
  }

  Future<void> _themNhanVien() async {
    final result = await Navigator.push<NhanVien>(
      context,
      MaterialPageRoute(builder: (_) => const ThemNhanVienScreen()),
    );
    if (result != null) {
      await _loadDanhSach();
    }
  }

  Future<void> _xoaNhanVien(NhanVien nv) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận'),
        content: Text('Bạn có chắc muốn xóa nhân viên ${nv.hoTen}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final deleted = await ApiService.xoaNhanVien(nv.id);
    if (deleted) {
      await _loadDanhSach();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Xóa thành công')));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Xóa thất bại')));
      }
    }
  }

  String getChaoBuoi() {
    final gio = DateTime.now().hour;
    if (gio < 12) return "Chào buổi sáng,";
    if (gio < 18) return "Chào buổi chiều,";
    return "Chào buổi tối,";
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('dd/MM/yyyy').format(DateTime.now());

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6200EE),
        onPressed: _themNhanVien,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 50, 16, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6200EE), Color(0xFF8E2DE2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        getChaoBuoi(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        today,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '💰 Tổng lương: ${numberFormat.format(_tinhTongLuongTatCa())} VND',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        softWrap: true,
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Consumer<NotificationService>(
                      builder: (context, service, child) {
                        return Stack(
                          children: [
                            IconButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/notifications');
                              },
                              icon: const Icon(
                                Icons.notifications_outlined,
                                color: Colors.white,
                                size: 30,
                              ),
                              tooltip: 'Thông báo',
                            ),
                            if (service.unreadCount > 0)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    '${service.unreadCount}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        "assets/icon/app_icon.png",
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Danh sách nhân viên",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6200EE),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Tìm theo tên hoặc số điện thoại...",
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF6200EE),
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF6200EE)),
                  )
                : RefreshIndicator(
                    color: const Color(0xFF6200EE),
                    onRefresh: _loadDanhSach,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: danhSachLoc.length,
                      itemBuilder: (_, index) {
                        final nv = danhSachLoc[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 2,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () async {
                              final needReload = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ChiTietNhanVienScreen(nhanVienId: nv.id),
                                ),
                              );
                              if (needReload == true) {
                                await _loadDanhSach();
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 12,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: const Color(
                                      0xFF8E2DE2,
                                    ).withOpacity(0.1),
                                    backgroundImage:
                                        (nv.anhDaiDien != null &&
                                            nv.anhDaiDien!.isNotEmpty)
                                        ? NetworkImage(
                                            ApiService.getAnhUrl(nv.anhDaiDien),
                                          )
                                        : null,
                                    child:
                                        (nv.anhDaiDien == null ||
                                            nv.anhDaiDien!.isEmpty)
                                        ? const Icon(
                                            Icons.person,
                                            color: Color(0xFF6200EE),
                                            size: 26,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          nv.hoTen,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Color(0xFF6200EE),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.phone,
                                              color: Colors.blueAccent,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                (nv.soDienThoai != null &&
                                                        nv
                                                            .soDienThoai!
                                                            .isNotEmpty)
                                                    ? nv.soDienThoai!
                                                    : "Chưa có SĐT",
                                                style: const TextStyle(
                                                  color: Colors.black54,
                                                  fontSize: 13.5,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        if (nv.tongTienDaNhan != null)
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Icon(
                                                Icons.monetization_on,
                                                color: Colors.green,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  "Đã nhận: ${formatVND(nv.tongTienDaNhan!)} VND",
                                                  style: const TextStyle(
                                                    color: Colors.black87,
                                                    fontSize: 13.5,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  softWrap: true,
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.redAccent,
                                      size: 22,
                                    ),
                                    onPressed: () => _xoaNhanVien(nv),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == _currentIndex) return;
          switch (index) {
            case 0:
              // Current screen
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/hoa-don');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/kho-hang');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/doanh-thu');
              break;
            case 4:
              Navigator.pushReplacementNamed(context, '/home');
              break;
          }
        },
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF6200EE),
        unselectedItemColor: Colors.grey.shade600,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Nhân Viên"),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: "Hóa Đơn",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warehouse),
            label: "Kho Hàng",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: "Doanh Thu",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        ],
      ),
    );
  }
}
