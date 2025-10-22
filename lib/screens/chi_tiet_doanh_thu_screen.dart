import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'doanh_thu_screen.dart'; // Import để sử dụng model DoanhThuThang

class ChiTietDoanhThuScreen extends StatelessWidget {
  final List<DoanhThuThang> dsDoanhThu;

  const ChiTietDoanhThuScreen({super.key, required this.dsDoanhThu});

  String _formatCurrency(num? value) {
    final formatter = NumberFormat("#,###", "vi_VN");
    return "${formatter.format(value ?? 0)} ₫";
  }

  Future<void> _exportPdf(BuildContext context, {bool share = false}) async {
    try {
      final pdfBytes = await _generatePdf();
      if (!share) {
        await Printing.layoutPdf(onLayout: (_) async => pdfBytes);
      } else {
        final output = await getTemporaryDirectory();
        final file = File(
          "${output.path}/bao_cao_doanh_thu_${DateTime.now().year}.pdf",
        );
        await file.writeAsBytes(pdfBytes);
        await Share.shareXFiles([
          XFile(file.path),
        ], text: "Báo cáo doanh thu năm ${DateTime.now().year}");
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi khi xử lý PDF: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final double tongNhanVien = dsDoanhThu.fold(
      0,
      (sum, dt) => sum + dt.nhanVien,
    );
    final double tongHDNhap = dsDoanhThu.fold(
      0,
      (sum, dt) => sum + dt.hoaDonNhap,
    );
    final double tongKhoNhap = dsDoanhThu.fold(
      0,
      (sum, dt) => sum + dt.khoNhap,
    );
    final double tongHDXuat = dsDoanhThu.fold(
      0,
      (sum, dt) => sum + dt.hoaDonXuat,
    );
    final double tongKhoXuat = dsDoanhThu.fold(
      0,
      (sum, dt) => sum + dt.khoXuat,
    );
    final double tongDoanhThuNam = dsDoanhThu.fold(
      0,
      (sum, dt) => sum + dt.tongTien,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Chi Tiết Báo Cáo Năm",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white, // Màu icon và chữ trên AppBar
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            onPressed: () => _exportPdf(context, share: false),
            tooltip: "In báo cáo",
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => _exportPdf(context, share: true),
            tooltip: "Chia sẻ PDF",
          ),
        ],
      ),
      body: _buildDataTable(
        tongNhanVien,
        tongHDNhap,
        tongKhoNhap,
        tongHDXuat,
        tongKhoXuat,
        tongDoanhThuNam,
      ),
    );
  }

  /// ===== Bảng dữ liệu (UI) đã được làm đẹp =====
  Widget _buildDataTable(
    double tongNhanVien,
    double tongHDNhap,
    double tongKhoNhap,
    double tongHDXuat,
    double tongKhoXuat,
    double tongDoanhThuNam,
  ) {
    final cellTextStyle = TextStyle(fontSize: 13, color: Colors.grey[800]);
    final totalCellTextStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 14,
      color: Colors.deepPurple[900],
    );

    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.grey[50], // Nền nhẹ nhàng cho toàn bộ màn hình
      child: Card(
        elevation: 8, // Thêm đổ bóng cho bảng
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ), // Bo góc cho Card
        child: ClipRRect(
          // Cắt nội dung bảng theo bo góc của Card
          borderRadius: BorderRadius.circular(12),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 28, // Tăng khoảng cách giữa các cột
                dataRowMinHeight: 45,
                dataRowMaxHeight: 50,
                headingRowHeight: 55, // Chiều cao hàng tiêu đề
                border: TableBorder.symmetric(
                  inside: BorderSide(
                    color: Colors.grey.shade200,
                    width: 1,
                  ), // Đường kẻ mảnh hơn
                ),
                headingRowColor: WidgetStateProperty.all(
                  Colors.deepPurple.shade600,
                ), // Màu tím đậm cho tiêu đề
                headingTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14, // To hơn một chút
                ),
                columns: const [
                  DataColumn(label: Text('Tháng', textAlign: TextAlign.center)),
                  DataColumn(
                    label: Text('Lương NV', textAlign: TextAlign.end),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text('HĐ Nhập', textAlign: TextAlign.end),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text('Kho Nhập', textAlign: TextAlign.end),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text('HĐ Xuất', textAlign: TextAlign.end),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text('Kho Xuất', textAlign: TextAlign.end),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text('Lợi Nhuận', textAlign: TextAlign.end),
                    numeric: true,
                  ),
                ],
                rows: [
                  ...dsDoanhThu.asMap().entries.map((entry) {
                    final index = entry.key;
                    final dt = entry.value;
                    return DataRow(
                      color: WidgetStateProperty.all(
                        index % 2 == 0
                            ? Colors.white
                            : Colors.deepPurple.shade50,
                      ), // Màu xen kẽ
                      cells: [
                        DataCell(
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4.0,
                            ),
                            child: Text(
                              DateFormat('MM/yyyy').format(dt.thang),
                              style: cellTextStyle,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            _formatCurrency(dt.nhanVien),
                            style: cellTextStyle,
                          ),
                        ),
                        DataCell(
                          Text(
                            _formatCurrency(dt.hoaDonNhap),
                            style: cellTextStyle,
                          ),
                        ),
                        DataCell(
                          Text(
                            _formatCurrency(dt.khoNhap),
                            style: cellTextStyle,
                          ),
                        ),
                        DataCell(
                          Text(
                            _formatCurrency(dt.hoaDonXuat),
                            style: cellTextStyle,
                          ),
                        ),
                        DataCell(
                          Text(
                            _formatCurrency(dt.khoXuat),
                            style: cellTextStyle,
                          ),
                        ),
                        DataCell(
                          Text(
                            _formatCurrency(dt.tongTien),
                            style: cellTextStyle.copyWith(
                              fontWeight: FontWeight.w600,
                              color: dt.tongTien >= 0
                                  ? Colors.green.shade700
                                  : Colors
                                        .red
                                        .shade700, // Màu sắc theo lợi nhuận
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                  // ===== Hàng tổng =====
                  DataRow(
                    color: WidgetStateProperty.all(
                      Colors.deepPurple.shade200,
                    ), // Nền đậm hơn cho hàng tổng
                    cells: [
                      const DataCell(
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.0),
                          child: Text(
                            "TỔNG NĂM",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          _formatCurrency(tongNhanVien),
                          style: totalCellTextStyle,
                        ),
                      ),
                      DataCell(
                        Text(
                          _formatCurrency(tongHDNhap),
                          style: totalCellTextStyle,
                        ),
                      ),
                      DataCell(
                        Text(
                          _formatCurrency(tongKhoNhap),
                          style: totalCellTextStyle,
                        ),
                      ),
                      DataCell(
                        Text(
                          _formatCurrency(tongHDXuat),
                          style: totalCellTextStyle,
                        ),
                      ),
                      DataCell(
                        Text(
                          _formatCurrency(tongKhoXuat),
                          style: totalCellTextStyle,
                        ),
                      ),
                      DataCell(
                        Text(
                          _formatCurrency(tongDoanhThuNam),
                          style: totalCellTextStyle.copyWith(
                            color: tongDoanhThuNam >= 0
                                ? Colors.green.shade900
                                : Colors.red.shade900,
                            fontSize: 16, // Lớn hơn và nổi bật nhất
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ===== Hàm tạo PDF đã sửa lỗi và làm đẹp =====
  Future<Uint8List> _generatePdf() async {
    final pdf = pw.Document();
    final fontData = await rootBundle.load("assets/fonts/DejaVuSans.ttf");
    final fontBoldData = await rootBundle.load(
      "assets/fonts/DejaVuSans-Bold.ttf",
    );
    final ttf = pw.Font.ttf(fontData);
    final ttfBold = pw.Font.ttf(fontBoldData);

    final logoBytes = await rootBundle.load('assets/icon/app_icon.png');
    final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

    String formatCurrencyPdf(num? value) =>
        "${NumberFormat("#,###", "vi_VN").format(value ?? 0)} VND";

    final headers = [
      'Tháng',
      'Chi Phí Lương',
      'Chi Phí HĐ Nhập',
      'Chi Phí Kho Nhập',
      'Doanh Thu HĐ Xuất',
      'Doanh Thu Kho Xuất',
      'Lợi Nhuận',
    ];

    final data = dsDoanhThu.map((dt) {
      return [
        DateFormat('MM/yyyy').format(dt.thang),
        formatCurrencyPdf(dt.nhanVien),
        formatCurrencyPdf(dt.hoaDonNhap),
        formatCurrencyPdf(dt.khoNhap),
        formatCurrencyPdf(dt.hoaDonXuat),
        formatCurrencyPdf(dt.khoXuat),
        formatCurrencyPdf(dt.tongTien),
      ];
    }).toList();

    final double tongNhanVien = dsDoanhThu.fold(
      0,
      (sum, dt) => sum + dt.nhanVien,
    );
    final double tongHDNhap = dsDoanhThu.fold(
      0,
      (sum, dt) => sum + dt.hoaDonNhap,
    );
    final double tongKhoNhap = dsDoanhThu.fold(
      0,
      (sum, dt) => sum + dt.khoNhap,
    );
    final double tongHDXuat = dsDoanhThu.fold(
      0,
      (sum, dt) => sum + dt.hoaDonXuat,
    );
    final double tongKhoXuat = dsDoanhThu.fold(
      0,
      (sum, dt) => sum + dt.khoXuat,
    );
    final double tongDoanhThu = dsDoanhThu.fold(
      0,
      (sum, dt) => sum + dt.tongTien,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(
                    children: [
                      pw.Image(logoImage, width: 50, height: 50),
                      pw.SizedBox(width: 16),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            "VietFlow",
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          pw.Text(
                            "Báo cáo kinh doanh",
                            style: const pw.TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.Text(
                    "BÁO CÁO DOANH THU NĂM ${DateTime.now().year}",
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              pw.Divider(height: 30, thickness: 1.5),

              pw.Table(
                border: pw.TableBorder.all(
                  color: PdfColors.grey300,
                  width: 0.5,
                ),
                columnWidths: const {
                  0: pw.FixedColumnWidth(80),
                  1: pw.FlexColumnWidth(1.2),
                  2: pw.FlexColumnWidth(1.2),
                  3: pw.FlexColumnWidth(1.2),
                  4: pw.FlexColumnWidth(1.2),
                  5: pw.FlexColumnWidth(1.2),
                  6: pw.FlexColumnWidth(1.5),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.blueGrey700,
                    ),
                    children: headers.map((header) {
                      return pw.Container(
                        padding: const pw.EdgeInsets.all(6),
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          header,
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                            fontSize: 10,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  ...data.asMap().entries.map((entry) {
                    final index = entry.key;
                    final row = entry.value;
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: index % 2 == 0
                            ? PdfColors.grey100
                            : PdfColors.white,
                      ),
                      children: row.map((cell) {
                        // Căn chỉnh cột đầu (Tháng) sang trái, các cột còn lại sang phải
                        final alignment = (row.indexOf(cell) == 0)
                            ? pw.Alignment.centerLeft
                            : pw.Alignment.centerRight;
                        return pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 5,
                          ),
                          alignment: alignment,
                          child: pw.Text(
                            cell,
                            style: const pw.TextStyle(fontSize: 9.5),
                          ),
                        );
                      }).toList(),
                    );
                  }).toList(),
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.blueGrey100,
                    ),
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.all(6),
                        alignment: pw.Alignment.centerLeft,
                        child: pw.Text(
                          "TỔNG NĂM",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(5),
                        alignment: pw.Alignment.centerRight,
                        child: pw.Text(
                          formatCurrencyPdf(tongNhanVien),
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(5),
                        alignment: pw.Alignment.centerRight,
                        child: pw.Text(
                          formatCurrencyPdf(tongHDNhap),
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(5),
                        alignment: pw.Alignment.centerRight,
                        child: pw.Text(
                          formatCurrencyPdf(tongKhoNhap),
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(5),
                        alignment: pw.Alignment.centerRight,
                        child: pw.Text(
                          formatCurrencyPdf(tongHDXuat),
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(5),
                        alignment: pw.Alignment.centerRight,
                        child: pw.Text(
                          formatCurrencyPdf(tongKhoXuat),
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(5),
                        alignment: pw.Alignment.centerRight,
                        child: pw.Text(
                          formatCurrencyPdf(tongDoanhThu),
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 11,
                            color: tongDoanhThu >= 0
                                ? PdfColors.green800
                                : PdfColors.red800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Spacer(),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    "Ngày xuất báo cáo: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}",
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                  pw.Text(
                    "Người lập báo cáo: Khanh123r",
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
    return pdf.save();
  }
}
