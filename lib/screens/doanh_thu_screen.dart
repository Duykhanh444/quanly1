import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/nhanvien.dart';
import '../models/khohang.dart';
import '../models/hoadon.dart';
import 'chi_tiet_doanh_thu_screen.dart';

// ===== MODEL DOANH THU THÁNG =====
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

  double get tongTien =>
      (hoaDonXuat + khoXuat) - (hoaDonNhap + khoNhap + nhanVien);
}

// ===== MÀN HÌNH DOANH THU =====
class DoanhThuScreen extends StatefulWidget {
  const DoanhThuScreen({super.key});

  @override
  State<DoanhThuScreen> createState() => _DoanhThuScreenState();
}

class _DoanhThuScreenState extends State<DoanhThuScreen> {
  List<DoanhThuThang> _dsDoanhThu = [];
  double _tongDoanhThuNam = 0;
  DateTime _selectedMonth = DateTime.now();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDoanhThu();
  }

  Future<void> _loadDoanhThu() async {
    final hoaDonList = await ApiService.layDanhSachHoaDon();
    final khoHangList = await ApiService.layDanhSachKhoHang();
    final nhanVienList = await ApiService.layDanhSachNhanVien();

    List<DoanhThuThang> temp = [];
    DateTime now = DateTime.now();

    for (int i = 1; i <= 12; i++) {
      DateTime thang = DateTime(now.year, i, 1);
      double hoaDonNhap = 0;
      double hoaDonXuat = 0;
      double khoNhap = 0;
      double khoXuat = 0;
      double tongLuong = 0;

      // Hóa đơn
      for (HoaDon hd in hoaDonList) {
        if (hd.ngayLap != null &&
            hd.ngayLap!.month == thang.month &&
            hd.ngayLap!.year == thang.year) {
          if (hd.loaiHoaDon?.toLowerCase() == "xuất") {
            hoaDonXuat += hd.tongTien.toDouble();
          } else if (hd.loaiHoaDon?.toLowerCase() == "nhập") {
            hoaDonNhap += hd.tongTien.toDouble();
          }
        }
      }

      // Kho hàng
      for (KhoHang kho in khoHangList) {
        if (kho.ngayNhap != null &&
            kho.ngayNhap!.month == thang.month &&
            kho.ngayNhap!.year == thang.year) {
          if (kho.trangThai == "Đã xuất") {
            khoXuat += kho.giaTri ?? 0;
          } else if (kho.trangThai == "Hoạt động") {
            khoNhap += kho.giaTri ?? 0;
          }
        }
      }

      // Nhân viên
      for (NhanVien nv in nhanVienList) {
        for (var wd in nv.workDays) {
          if (wd.ngay.month == thang.month && wd.ngay.year == thang.year) {
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
        _tongDoanhThuNam = _dsDoanhThu.fold(0, (sum, d) => sum + d.tongTien);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final selected = _dsDoanhThu.firstWhere(
      (d) =>
          d.thang.month == _selectedMonth.month &&
          d.thang.year == _selectedMonth.year,
      orElse: () => DoanhThuThang(thang: _selectedMonth),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Báo cáo doanh thu",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true, // 👈 để chữ nằm chính giữa
        backgroundColor: Colors.deepPurple,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Image.asset(
              "assets/icon/app_icon.png",
              width: 95, // 👈 chỉnh size logo
              height: 95,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ==== CARD TỔNG DOANH THU NĂM ====
                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: Colors.deepPurple.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Icon(
                            Icons.attach_money,
                            size: 40,
                            color: Colors.deepPurple,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Tổng doanh thu năm",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  formatter.format(_tongDoanhThuNam),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Expanded(
                    flex: 2,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY:
                            _dsDoanhThu
                                .map((e) => e.tongTien < 0 ? 0 : e.tongTien)
                                .reduce((a, b) => a > b ? a : b) *
                            1.2,
                        minY: 0,
                        barGroups: _dsDoanhThu.map((dt) {
                          bool selected =
                              dt.thang.month == _selectedMonth.month;
                          return BarChartGroupData(
                            x: dt.thang.month,
                            barRods: [
                              BarChartRodData(
                                toY: dt.tongTien < 0 ? 0 : dt.tongTien,
                                gradient: LinearGradient(
                                  colors: selected
                                      ? [Colors.deepPurple, Colors.purpleAccent]
                                      : [Colors.grey, Colors.grey.shade400],
                                ),
                                width: selected ? 30 : 22,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ],
                          );
                        }).toList(),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: (value, _) => Text(
                                "T${value.toInt()}",
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 60,
                              getTitlesWidget: (value, _) => Text(
                                NumberFormat.compactCurrency(
                                  locale: 'vi_VN',
                                  symbol: 'VND',
                                  decimalDigits: 0,
                                ).format(value),
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        gridData: FlGridData(show: true),
                        borderData: FlBorderData(show: false),

                        // ✅ Khi bấm vào cột → đổi _selectedMonth
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem:
                                (group, groupIndex, rod, rodIndex) => null,
                          ),
                          touchCallback: (event, response) {
                            if (response != null &&
                                response.spot != null &&
                                event is FlTapUpEvent) {
                              final touchedMonth =
                                  response.spot!.touchedBarGroup.x;
                              setState(() {
                                _selectedMonth = DateTime(
                                  _selectedMonth.year,
                                  touchedMonth,
                                );
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ==== DANH SÁCH DOANH THU TỪNG THÁNG ====
                  Expanded(
                    flex: 3,
                    child: ListView.builder(
                      itemCount: _dsDoanhThu.length,
                      itemBuilder: (context, index) {
                        final dt = _dsDoanhThu[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.deepPurple.shade100,
                              child: Text(dt.thang.month.toString()),
                            ),
                            title: Text(
                              "Tháng ${dt.thang.month}/${dt.thang.year}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              "Doanh thu: ${formatter.format(dt.tongTien)}",
                            ),
                            onTap: () {
                              setState(() => _selectedMonth = dt.thang);
                            },
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ==== NÚT XEM CHI TIẾT ====
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ChiTietDoanhThuScreen(dsDoanhThu: _dsDoanhThu),
                        ),
                      );
                    },
                    icon: const Icon(Icons.table_chart),
                    label: const Text("Xem chi tiết báo cáo"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
