import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../screens/doanh_thu_screen.dart'; // để dùng model DoanhThuThang

class ChiTietDoanhThuScreen extends StatelessWidget {
  final List<DoanhThuThang> dsDoanhThu;
  const ChiTietDoanhThuScreen({super.key, required this.dsDoanhThu});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    // ===== Tính tổng các cột =====
    final tongNhanVien = dsDoanhThu.fold<double>(
      0,
      (sum, dt) => sum + dt.nhanVien,
    );
    final tongHDNhap = dsDoanhThu.fold<double>(
      0,
      (sum, dt) => sum + dt.hoaDonNhap,
    );
    final tongHDXuat = dsDoanhThu.fold<double>(
      0,
      (sum, dt) => sum + dt.hoaDonXuat,
    );
    final tongKhoNhap = dsDoanhThu.fold<double>(
      0,
      (sum, dt) => sum + dt.khoNhap,
    );
    final tongKhoXuat = dsDoanhThu.fold<double>(
      0,
      (sum, dt) => sum + dt.khoXuat,
    );
    final tongDoanhThuNam = dsDoanhThu.fold<double>(
      0,
      (sum, dt) => sum + dt.tongTien,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chi tiết doanh thu"),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: "Xuất PDF",
            onPressed: () async {
              final pdf = await _generatePdf(
                dsDoanhThu,
                formatter,
                tongNhanVien,
                tongHDNhap,
                tongHDXuat,
                tongKhoNhap,
                tongKhoXuat,
                tongDoanhThuNam,
              );
              await Printing.layoutPdf(
                onLayout: (PdfPageFormat format) async => pdf.save(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: "Chia sẻ PDF",
            onPressed: () async {
              final pdf = await _generatePdf(
                dsDoanhThu,
                formatter,
                tongNhanVien,
                tongHDNhap,
                tongHDXuat,
                tongKhoNhap,
                tongKhoXuat,
                tongDoanhThuNam,
              );

              final output = await getTemporaryDirectory();
              final file = File("${output.path}/bao_cao_doanh_thu.pdf");
              await file.writeAsBytes(await pdf.save());

              await Share.shareXFiles([
                XFile(file.path),
              ], text: "Báo cáo doanh thu");
            },
          ),
        ],
      ),
      body: _buildDataTable(
        formatter,
        tongNhanVien,
        tongHDNhap,
        tongHDXuat,
        tongKhoNhap,
        tongKhoXuat,
        tongDoanhThuNam,
      ),
    );
  }

  /// ===== Bảng dữ liệu =====
  Widget _buildDataTable(
    NumberFormat formatter,
    double tongNhanVien,
    double tongHDNhap,
    double tongHDXuat,
    double tongKhoNhap,
    double tongKhoXuat,
    double tongDoanhThuNam,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 10,
        dataRowMinHeight: 30,
        dataRowMaxHeight: 35,
        headingRowHeight: 38,
        border: TableBorder.all(color: Colors.grey.shade400),
        headingRowColor: WidgetStateProperty.all(Colors.deepPurple.shade100),
        columns: const [
          DataColumn(label: Text("Tháng", style: TextStyle(fontSize: 13))),
          DataColumn(label: Text("Nhân viên", style: TextStyle(fontSize: 13))),
          DataColumn(label: Text("HĐ nhập", style: TextStyle(fontSize: 13))),
          DataColumn(label: Text("HĐ xuất", style: TextStyle(fontSize: 13))),
          DataColumn(label: Text("Kho nhập", style: TextStyle(fontSize: 13))),
          DataColumn(label: Text("Kho xuất", style: TextStyle(fontSize: 13))),
          DataColumn(label: Text("Doanh thu", style: TextStyle(fontSize: 13))),
        ],
        rows: [
          ...dsDoanhThu.map(
            (dt) => DataRow(
              cells: [
                DataCell(
                  Text(
                    "${dt.thang.month}/${dt.thang.year}",
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                DataCell(
                  Text(
                    formatter.format(dt.nhanVien),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                DataCell(
                  Text(
                    formatter.format(dt.hoaDonNhap),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                DataCell(
                  Text(
                    formatter.format(dt.hoaDonXuat),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                DataCell(
                  Text(
                    formatter.format(dt.khoNhap),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                DataCell(
                  Text(
                    formatter.format(dt.khoXuat),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                DataCell(
                  Text(
                    formatter.format(dt.tongTien),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          // ===== Hàng tổng =====
          DataRow(
            color: WidgetStateProperty.all(Colors.deepPurple.shade50),
            cells: [
              const DataCell(
                Text(
                  "TỔNG NĂM",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              DataCell(
                Text(formatter.format(tongNhanVien), style: _cellTotalStyle()),
              ),
              DataCell(
                Text(formatter.format(tongHDNhap), style: _cellTotalStyle()),
              ),
              DataCell(
                Text(formatter.format(tongHDXuat), style: _cellTotalStyle()),
              ),
              DataCell(
                Text(formatter.format(tongKhoNhap), style: _cellTotalStyle()),
              ),
              DataCell(
                Text(formatter.format(tongKhoXuat), style: _cellTotalStyle()),
              ),
              DataCell(
                Text(
                  formatter.format(tongDoanhThuNam),
                  style: _cellTotalStyle(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  TextStyle _cellTotalStyle() {
    return const TextStyle(
      color: Colors.red,
      fontWeight: FontWeight.bold,
      fontSize: 13,
    );
  }

  /// ===== Xuất PDF =====
  Future<pw.Document> _generatePdf(
    List<DoanhThuThang> dsDoanhThu,
    NumberFormat formatter,
    double tongNhanVien,
    double tongHDNhap,
    double tongHDXuat,
    double tongKhoNhap,
    double tongKhoXuat,
    double tongDoanhThuNam,
  ) async {
    // Nạp font Roboto
    final robotoRegular = pw.Font.ttf(
      await rootBundle.load("assets/fonts/Roboto-Regular.ttf"),
    );
    final robotoBold = pw.Font.ttf(
      // nếu chưa có file Bold, bạn có thể dùng tạm Regular
      await rootBundle.load("assets/fonts/Roboto-Bold.ttf"),
    );

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: robotoRegular, bold: robotoBold),
        build: (_) => [
          pw.Center(
            child: pw.Text(
              "BÁO CÁO DOANH THU NĂM",
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 15),
          pw.Table.fromTextArray(
            headers: [
              "Tháng",
              "Nhân viên",
              "HĐ nhập",
              "HĐ xuất",
              "Kho nhập",
              "Kho xuất",
              "Doanh thu",
            ],
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 12,
            ),
            cellStyle: const pw.TextStyle(fontSize: 11),
            data: [
              ...dsDoanhThu.map(
                (dt) => [
                  "${dt.thang.month}/${dt.thang.year}",
                  formatter.format(dt.nhanVien),
                  formatter.format(dt.hoaDonNhap),
                  formatter.format(dt.hoaDonXuat),
                  formatter.format(dt.khoNhap),
                  formatter.format(dt.khoXuat),
                  formatter.format(dt.tongTien),
                ],
              ),
              [
                "TỔNG NĂM",
                formatter.format(tongNhanVien),
                formatter.format(tongHDNhap),
                formatter.format(tongHDXuat),
                formatter.format(tongKhoNhap),
                formatter.format(tongKhoXuat),
                formatter.format(tongDoanhThuNam),
              ],
            ],
          ),
        ],
      ),
    );

    return pdf;
  }
}
