import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../models/nhanvien.dart';
import '../models/khohang.dart';
import '../models/hoadon.dart';

class DoanhThuThang {
  final DateTime thang;
  final double hoaDon;
  final double khoHang;
  final double nhanVien;

  DoanhThuThang({
    required this.thang,
    required this.hoaDon,
    required this.khoHang,
    required this.nhanVien,
  });

  double get tongTien => hoaDon + khoHang - nhanVien;
}

class DoanhThuScreen extends StatefulWidget {
  const DoanhThuScreen({super.key});

  @override
  State<DoanhThuScreen> createState() => _DoanhThuScreenState();
}

class _DoanhThuScreenState extends State<DoanhThuScreen> {
  List<DoanhThuThang> _dsDoanhThu = [];
  double _tongDoanhThu = 0;
  DateTime _selectedMonth = DateTime.now();

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

    // ✅ lấy 7 tháng (trước 3 tháng, hiện tại, sau 3 tháng)
    for (int i = -3; i <= 3; i++) {
      DateTime thang = DateTime(now.year, now.month + i, 1);
      double tongHoaDon = 0;
      double tongKho = 0;
      double tongLuong = 0;

      // Hóa đơn
      for (HoaDon hd in hoaDonList) {
        if (hd.ngayLap != null &&
            hd.ngayLap!.month == thang.month &&
            hd.ngayLap!.year == thang.year) {
          if (hd.loaiHoaDon?.toLowerCase() == "xuất") {
            tongHoaDon += hd.tongTien.toDouble();
          } else if (hd.loaiHoaDon?.toLowerCase() == "nhập") {
            tongHoaDon -= hd.tongTien.toDouble();
          }
        }
      }

      // Kho hàng
      for (KhoHang kho in khoHangList) {
        if (kho.ngayNhap != null &&
            kho.ngayNhap!.month == thang.month &&
            kho.ngayNhap!.year == thang.year) {
          if (kho.trangThai == "Đã xuất") {
            tongKho += kho.giaTri ?? 0;
          } else if (kho.trangThai == "Hoạt động") {
            tongKho -= kho.giaTri ?? 0;
          }
        }
      }

      // Nhân viên (tính lương)
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
          hoaDon: tongHoaDon,
          khoHang: tongKho,
          nhanVien: tongLuong,
        ),
      );
    }

    if (mounted) {
      setState(() {
        _dsDoanhThu = temp;
        final thangChon = _dsDoanhThu.firstWhere(
          (d) =>
              d.thang.month == _selectedMonth.month &&
              d.thang.year == _selectedMonth.year,
          orElse: () => DoanhThuThang(
            thang: _selectedMonth,
            hoaDon: 0,
            khoHang: 0,
            nhanVien: 0,
          ),
        );
        _tongDoanhThu = thangChon.tongTien;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    final thangChon = _dsDoanhThu.firstWhere(
      (d) =>
          d.thang.month == _selectedMonth.month &&
          d.thang.year == _selectedMonth.year,
      orElse: () => DoanhThuThang(
        thang: _selectedMonth,
        hoaDon: 0,
        khoHang: 0,
        nhanVien: 0,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Báo cáo doanh thu"),
        backgroundColor: const Color(0xFF4A00E0),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              "Tổng doanh thu tháng ${_selectedMonth.month}/${_selectedMonth.year}: ${formatter.format(thangChon.tongTien)}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // ✅ Biểu đồ
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 30),
                child: BarChart(
                  BarChartData(
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                            null, // ❌ tắt tooltip
                      ),
                      touchCallback: (event, response) {
                        if (response != null &&
                            response.spot != null &&
                            event.isInterestedForInteractions) {
                          final touchedX = response.spot!.touchedBarGroup.x;
                          final month = _dsDoanhThu.firstWhere(
                            (d) => d.thang.month == touchedX,
                            orElse: () => DoanhThuThang(
                              thang: _selectedMonth,
                              hoaDon: 0,
                              khoHang: 0,
                              nhanVien: 0,
                            ),
                          );
                          setState(() {
                            _selectedMonth = month.thang;
                            _tongDoanhThu = month.tongTien;
                          });
                        }
                      },
                    ),
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _dsDoanhThu.isNotEmpty
                        ? _dsDoanhThu
                                  .map((e) => e.hoaDon + e.khoHang + e.nhanVien)
                                  .reduce((a, b) => a > b ? a : b) *
                              1.1
                        : 100,
                    minY: 0,
                    barGroups: _dsDoanhThu.map((dt) {
                      final tong = dt.hoaDon + dt.khoHang + dt.nhanVien;
                      final isSelected = dt.thang.month == _selectedMonth.month;
                      return BarChartGroupData(
                        x: dt.thang.month,
                        barRods: [
                          BarChartRodData(
                            toY: tong,
                            width: isSelected ? 30 : 24,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(6),
                            ),
                            rodStackItems: [
                              BarChartRodStackItem(0, dt.hoaDon, Colors.orange),
                              BarChartRodStackItem(
                                dt.hoaDon,
                                dt.hoaDon + dt.khoHang,
                                Colors.grey,
                              ),
                              BarChartRodStackItem(
                                dt.hoaDon + dt.khoHang,
                                tong,
                                Colors.blue,
                              ),
                            ],
                            borderSide: isSelected
                                ? const BorderSide(
                                    color: Colors.red,
                                    width: 2,
                                  ) // viền đỏ
                                : BorderSide.none,
                          ),
                        ],
                      );
                    }).toList(),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 36,
                          getTitlesWidget: (value, meta) {
                            final isSelected =
                                value.toInt() == _selectedMonth.month;
                            return GestureDetector(
                              onTap: () {
                                final month = _dsDoanhThu.firstWhere(
                                  (d) => d.thang.month == value.toInt(),
                                  orElse: () => DoanhThuThang(
                                    thang: _selectedMonth,
                                    hoaDon: 0,
                                    khoHang: 0,
                                    nhanVien: 0,
                                  ),
                                );
                                setState(() {
                                  _selectedMonth = month.thang;
                                  _tongDoanhThu = month.tongTien;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? Colors.purple.withOpacity(0.3)
                                      : Colors.transparent,
                                ),
                                child: Text(
                                  "T${value.toInt()}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.purple
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              NumberFormat.compactCurrency(
                                locale: "vi_VN",
                                symbol: "₫",
                                decimalDigits: 0,
                              ).format(value),
                              style: const TextStyle(fontSize: 11),
                            );
                          },
                        ),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(show: true),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ✅ Legend bên dưới
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildLegend(
                      "Hóa đơn",
                      Colors.orange,
                      formatter.format(thangChon.hoaDon),
                    ),
                    _buildLegend(
                      "Kho hàng",
                      Colors.grey,
                      formatter.format(thangChon.khoHang),
                    ),
                    _buildLegend(
                      "Nhân viên",
                      Colors.blue,
                      formatter.format(thangChon.nhanVien),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(String title, Color color, String value) {
    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.square, color: color, size: 12),
            const SizedBox(width: 4),
            Text(title, style: const TextStyle(fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
