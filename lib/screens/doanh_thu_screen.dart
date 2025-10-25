// lib/screens/doanh_thu_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';
import '../models/nhanvien.dart';
import '../models/khohang.dart';
import '../models/hoadon.dart';
import 'chi_tiet_doanh_thu_screen.dart';
import '../services/notification_service.dart';

// ===== MODEL DOANH THU THÁNG (CẬP NHẬT) =====
class DoanhThuThang {
  final DateTime thang;
  final double hoaDonNhap;
  final double hoaDonXuat;
  final double khoNhap;
  final double khoXuat;
  final double nhanVien;

  DoanhThuThang({
    required this.thang,
    this.hoaDonNhap = 0,
    this.hoaDonXuat = 0,
    this.khoNhap = 0,
    this.khoXuat = 0,
    this.nhanVien = 0,
  });

  double get tongThu => hoaDonXuat + khoXuat;
  double get tongChi => hoaDonNhap + khoNhap + nhanVien;
  double get loiNhuan => tongThu - tongChi;
  double get tongTien => loiNhuan;
}

// ===== MÀN HÌNH DOANH THU (THIẾT KẾ MỚI) =====
class DoanhThuScreen extends StatefulWidget {
  const DoanhThuScreen({super.key});

  @override
  State<DoanhThuScreen> createState() => _DoanhThuScreenState();
}

class _DoanhThuScreenState extends State<DoanhThuScreen> {
  List<DoanhThuThang> _dsDoanhThu = [];
  double _tongLoiNhuanNam = 0;
  int _selectedMonthIndex = DateTime.now().month - 1;
  bool _isLoading = true;
  final int _currentIndex = 3;

  @override
  void initState() {
    super.initState();
    _loadDoanhThu();
  }

  Future<void> _loadDoanhThu() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    await Future.wait([
      _fetchApiData(),
      if (context.mounted)
        Provider.of<NotificationService>(
          context,
          listen: false,
        ).loadNotifications(),
    ]);

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchApiData() async {
    final hoaDonList = await ApiService.layDanhSachHoaDon();
    final khoHangList = await ApiService.layDanhSachKhoHang();
    final nhanVienList = await ApiService.layDanhSachNhanVien();

    List<DoanhThuThang> temp = [];
    DateTime now = DateTime.now();

    for (int i = 1; i <= 12; i++) {
      DateTime thang = DateTime(now.year, i, 1);
      double hoaDonNhap = 0,
          hoaDonXuat = 0,
          khoNhap = 0,
          khoXuat = 0,
          tongLuong = 0;

      for (HoaDon hd in hoaDonList) {
        if (hd.ngayLap?.month == i && hd.ngayLap?.year == now.year) {
          if (hd.loaiHoaDon?.toLowerCase() == "xuất")
            hoaDonXuat += hd.tongTien.toDouble();
          else if (hd.loaiHoaDon?.toLowerCase() == "nhập")
            hoaDonNhap += hd.tongTien.toDouble();
        }
      }
      for (KhoHang kho in khoHangList) {
        if (kho.ngayNhap?.month == i && kho.ngayNhap?.year == now.year) {
          if (kho.trangThai == "Đã xuất")
            khoXuat += kho.giaTri ?? 0;
          else if (kho.trangThai == "Hoạt động")
            khoNhap += kho.giaTri ?? 0;
        }
      }
      for (NhanVien nv in nhanVienList) {
        for (var wd in nv.workDays) {
          if (wd.ngay.month == i && wd.ngay.year == now.year) {
            tongLuong += nv.luongTheoGio * wd.soGio;
          }
        }
      }
      temp.add(
        DoanhThuThang(
          thang: thang,
          hoaDonNhap: hoaDonNhap,
          hoaDonXuat: hoaDonXuat,
          khoNhap: khoNhap,
          khoXuat: khoXuat,
          nhanVien: tongLuong,
        ),
      );
    }

    if (mounted) {
      setState(() {
        _dsDoanhThu = temp;
        _tongLoiNhuanNam = _dsDoanhThu.fold(0, (sum, d) => sum + d.loiNhuan);
      });
    }
  }

  String _formatCurrency(num value) {
    if (value == 0) return "0 ₫";
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'VND').format(value);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Chào buổi sáng,';
    }
    if (hour < 18) {
      return 'Chào buổi chiều,';
    }
    return 'Chào buổi tối,';
  }

  @override
  Widget build(BuildContext context) {
    final bool hasData = _dsDoanhThu.isNotEmpty;
    final DoanhThuThang? selectedData = hasData
        ? _dsDoanhThu[_selectedMonthIndex]
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FD),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDoanhThu,
              child: CustomScrollView(
                slivers: [
                  _buildHeader(), // Header đã được cập nhật
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildYearlySummaryCard(),
                          const SizedBox(height: 20),
                          if (hasData) _buildChartCard(),
                          const SizedBox(height: 20),
                          if (selectedData != null)
                            _buildMonthlyDetailCard(selectedData),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChiTietDoanhThuScreen(
                                    dsDoanhThu: _dsDoanhThu,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.table_chart_outlined),
                            label: const Text("Xem báo cáo chi tiết"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4A00E0),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (_currentIndex == index) return;
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/danh-sach-nhan-vien');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/hoa-don');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/kho-hang');
              break;
            case 3:
              break;
            case 4:
              Navigator.pushReplacementNamed(context, '/home');
              break;
          }
        },
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF4A00E0),
        unselectedItemColor: Colors.grey,
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

  // PHẦN HEADER ĐÃ ĐƯỢC CẬP NHẬT THEO YÊU CẦU MỚI

  Widget _buildHeader() {
    return SliverAppBar(
      foregroundColor: Colors.white,
      pinned: true,
      toolbarHeight: 80,
      automaticallyImplyLeading: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _getGreeting(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('dd/MM/yyyy').format(DateTime.now()),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        Consumer<NotificationService>(
          builder: (context, service, child) {
            return Stack(
              children: [
                IconButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/notifications'),
                  icon: const Icon(Icons.notifications_outlined, size: 28),
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
        // ✨ SỬA: Logo được làm to hơn nữa
        Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: Center(
            child: Image.asset(
              "assets/icon/app_icon.png",
              height: 65,
              width: 65,
            ),
          ),
        ),
      ],
      //  Thêm nền gradient để đồng bộ với app
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }

  Widget _buildYearlySummaryCard() {
    return Card(
      elevation: 4,
      shadowColor: Colors.deepPurple.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF4A00E0).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.show_chart,
                color: Color(0xFF4A00E0),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Lợi nhuận năm ${DateTime.now().year}",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  _formatCurrency(_tongLoiNhuanNam),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A00E0),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard() {
    final profits = _dsDoanhThu
        .map((e) => e.loiNhuan > 0 ? e.loiNhuan : 0)
        .toList();
    double maxY = profits.isEmpty
        ? 100000
        : profits.reduce((a, b) => a > b ? a : b) * 1.3;
    if (maxY == 0) maxY = 100000;

    return Card(
      elevation: 4,
      shadowColor: Colors.deepPurple.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
        child: SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              barGroups: _dsDoanhThu.asMap().entries.map((entry) {
                int index = entry.key;
                DoanhThuThang dt = entry.value;
                bool isSelected = index == _selectedMonthIndex;
                return BarChartGroupData(
                  x: dt.thang.month,
                  barRods: [
                    BarChartRodData(
                      toY: dt.loiNhuan < 0 ? 0 : dt.loiNhuan,
                      gradient: LinearGradient(
                        colors: isSelected
                            ? [const Color(0xFF4A00E0), const Color(0xFF8E2DE2)]
                            : [Colors.grey.shade300, Colors.grey.shade400],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      width: isSelected ? 22 : 16,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                    ),
                  ],
                );
              }).toList(),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, _) => Text("T${value.toInt()}"),
                  ),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) => null,
                ),
                touchCallback: (event, response) {
                  if (response?.spot != null && event is FlTapUpEvent) {
                    setState(
                      () => _selectedMonthIndex =
                          response!.spot!.touchedBarGroupIndex,
                    );
                  }
                },
              ),
            ),
            swapAnimationDuration: const Duration(milliseconds: 250),
            swapAnimationCurve: Curves.easeInOut,
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyDetailCard(DoanhThuThang data) {
    return Card(
      elevation: 4,
      shadowColor: Colors.deepPurple.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Chi tiết tháng ${data.thang.month}/${data.thang.year}",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A00E0),
              ),
            ),
            const Divider(height: 24),
            _buildDetailRow(
              Icons.arrow_upward,
              "Tổng thu",
              _formatCurrency(data.tongThu),
              Colors.green,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.arrow_downward,
              "Tổng chi",
              _formatCurrency(data.tongChi),
              Colors.red,
            ),
            const Divider(height: 24),
            _buildDetailRow(
              Icons.account_balance_wallet,
              "Lợi nhuận",
              _formatCurrency(data.loiNhuan),
              const Color(0xFF4A00E0),
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    Color color, {
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 16)),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 18 : 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
  }
}
