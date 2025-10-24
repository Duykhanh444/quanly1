// lib/screens/chi_tiet_doanh_thu_screen.dart
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

String _formatCurrency(num? value) {
  final formatter = NumberFormat("#,###", "vi_VN");
  return "${formatter.format(value ?? 0)} ₫";
}

class ChiTietDoanhThuScreen extends StatefulWidget {
  final List<DoanhThuThang> dsDoanhThu;

  const ChiTietDoanhThuScreen({super.key, required this.dsDoanhThu});

  @override
  State<ChiTietDoanhThuScreen> createState() => _ChiTietDoanhThuScreenState();
}

// ⭐ SỬA LẠI: ĐÃ XÓA initState và dispose ĐỂ KHÔNG ÉP XOAY MÀN HÌNH
class _ChiTietDoanhThuScreenState extends State<ChiTietDoanhThuScreen> {
  @override
  Widget build(BuildContext context) {
    // Tính toán các giá trị tổng MỘT LẦN DUY NHẤT
    final totals = {
      'tongNhanVien': widget.dsDoanhThu.fold(
        0.0,
        (sum, dt) => sum + dt.nhanVien,
      ),
      'tongHDNhap': widget.dsDoanhThu.fold(
        0.0,
        (sum, dt) => sum + dt.hoaDonNhap,
      ),
      'tongKhoNhap': widget.dsDoanhThu.fold(0.0, (sum, dt) => sum + dt.khoNhap),
      'tongHDXuat': widget.dsDoanhThu.fold(
        0.0,
        (sum, dt) => sum + dt.hoaDonXuat,
      ),
      'tongKhoXuat': widget.dsDoanhThu.fold(0.0, (sum, dt) => sum + dt.khoXuat),
      'tongLoiNhuan': widget.dsDoanhThu.fold(
        0.0,
        (sum, dt) => sum + dt.tongTien,
      ),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Báo Cáo Chi Tiết Năm ${DateTime.now().year}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            onPressed: () => _exportPdf(
              context,
              share: false,
              totals: totals,
              dsDoanhThu: widget.dsDoanhThu,
            ),
            tooltip: "In báo cáo",
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => _exportPdf(
              context,
              share: true,
              totals: totals,
              dsDoanhThu: widget.dsDoanhThu,
            ),
            tooltip: "Chia sẻ PDF",
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: _buildDataTable(totals, widget.dsDoanhThu),
        ),
      ),
    );
  }
}

/// ===== Widget xây dựng bảng dữ liệu UI (Không đổi) =====
Widget _buildDataTable(
  Map<String, double> totals,
  List<DoanhThuThang> dsDoanhThu,
) {
  final cellTextStyle = TextStyle(fontSize: 13, color: Colors.grey[800]);
  final totalCellTextStyle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 14,
    color: Colors.deepPurple[900],
  );

  return DataTable(
    columnSpacing: 28,
    dataRowMinHeight: 45,
    dataRowMaxHeight: 50,
    headingRowHeight: 55,
    border: TableBorder.all(color: Colors.grey.shade300, width: 1),
    headingRowColor: MaterialStateProperty.all(Colors.deepPurple.shade600),
    headingTextStyle: const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 14,
    ),
    columns: const [
      DataColumn(label: Text('Tháng')),
      DataColumn(label: Text('Lương NV'), numeric: true),
      DataColumn(label: Text('HĐ Nhập'), numeric: true),
      DataColumn(label: Text('Kho Nhập'), numeric: true),
      DataColumn(label: Text('HĐ Xuất'), numeric: true),
      DataColumn(label: Text('Kho Xuất'), numeric: true),
      DataColumn(label: Text('Lợi Nhuận'), numeric: true),
    ],
    rows: [
      ...dsDoanhThu.asMap().entries.map((entry) {
        final index = entry.key;
        final dt = entry.value;
        return DataRow(
          color: MaterialStateProperty.all(
            index % 2 == 0 ? Colors.white : Colors.deepPurple.shade50,
          ),
          cells: [
            DataCell(
              Text(
                DateFormat('MM/yyyy').format(dt.thang),
                style: cellTextStyle,
              ),
            ),
            DataCell(Text(_formatCurrency(dt.nhanVien), style: cellTextStyle)),
            DataCell(
              Text(_formatCurrency(dt.hoaDonNhap), style: cellTextStyle),
            ),
            DataCell(Text(_formatCurrency(dt.khoNhap), style: cellTextStyle)),
            DataCell(
              Text(_formatCurrency(dt.hoaDonXuat), style: cellTextStyle),
            ),
            DataCell(Text(_formatCurrency(dt.khoXuat), style: cellTextStyle)),
            DataCell(
              Text(
                _formatCurrency(dt.tongTien),
                style: cellTextStyle.copyWith(
                  fontWeight: FontWeight.w600,
                  color: dt.tongTien >= 0
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                ),
              ),
            ),
          ],
        );
      }).toList(),
      DataRow(
        color: MaterialStateProperty.all(Colors.deepPurple.shade200),
        cells: [
          const DataCell(
            Text(
              "TỔNG NĂM",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          ),
          DataCell(
            Text(
              _formatCurrency(totals['tongNhanVien']),
              style: totalCellTextStyle,
            ),
          ),
          DataCell(
            Text(
              _formatCurrency(totals['tongHDNhap']),
              style: totalCellTextStyle,
            ),
          ),
          DataCell(
            Text(
              _formatCurrency(totals['tongKhoNhap']),
              style: totalCellTextStyle,
            ),
          ),
          DataCell(
            Text(
              _formatCurrency(totals['tongHDXuat']),
              style: totalCellTextStyle,
            ),
          ),
          DataCell(
            Text(
              _formatCurrency(totals['tongKhoXuat']),
              style: totalCellTextStyle,
            ),
          ),
          DataCell(
            Text(
              _formatCurrency(totals['tongLoiNhuan']),
              style: totalCellTextStyle.copyWith(
                color: (totals['tongLoiNhuan'] ?? 0) >= 0
                    ? Colors.green.shade900
                    : Colors.red.shade900,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

/// ===== Hàm logic để xuất PDF (Không đổi) =====
Future<void> _exportPdf(
  BuildContext context, {
  required bool share,
  required Map<String, double> totals,
  required List<DoanhThuThang> dsDoanhThu,
}) async {
  try {
    final pdfBytes = await _generatePdf(totals, dsDoanhThu);
    if (!context.mounted) return;

    if (!share) {
      await Printing.layoutPdf(onLayout: (_) async => pdfBytes);
    } else {
      final output = await getTemporaryDirectory();
      final fileName = "bao_cao_doanh_thu_${DateTime.now().year}.pdf";
      final file = File("${output.path}/$fileName");
      await file.writeAsBytes(pdfBytes);
      await Share.shareXFiles([
        XFile(file.path),
      ], text: "Báo cáo doanh thu năm ${DateTime.now().year}");
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi khi xử lý PDF: $e")));
    }
  }
}

// ===== Hàm tạo PDF (Không đổi) =====
Future<Uint8List> _generatePdf(
  Map<String, double> totals,
  List<DoanhThuThang> dsDoanhThu,
) async {
  final pdf = pw.Document();
  final fontData = await rootBundle.load("assets/fonts/DejaVuSans.ttf");
  final ttf = pw.Font.ttf(fontData);
  final fontBoldData = await rootBundle.load(
    "assets/fonts/DejaVuSans-Bold.ttf",
  );
  final ttfBold = pw.Font.ttf(fontBoldData);

  final logoBytes = await rootBundle.load('assets/icon/app_icon.png');
  final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

  String formatCurrencyPdf(num? value) =>
      "${NumberFormat("#,###", "vi_VN").format(value ?? 0)} VND";

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(32),
      theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
      build: (pw.Context context) {
        return pw.Column(
          children: [
            // 1. Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
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

            // 2. Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: const {
                0: pw.FixedColumnWidth(80), // Tháng
                1: pw.FlexColumnWidth(1.2), // Lương NV
                2: pw.FlexColumnWidth(1.2), // HĐ Nhập
                3: pw.FlexColumnWidth(1.2), // Kho Nhập
                4: pw.FlexColumnWidth(1.2), // HĐ Xuất
                5: pw.FlexColumnWidth(1.2), // Kho Xuất
                6: pw.FlexColumnWidth(1.5), // Lợi Nhuận
              },
              children: [
                // Hàng Header của bảng
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.blueGrey700,
                  ),
                  children:
                      [
                            'Tháng',
                            'Lương NV',
                            'HĐ Nhập',
                            'Kho Nhập',
                            'HĐ Xuất',
                            'Kho Xuất',
                            'Lợi Nhuận',
                          ]
                          .map(
                            (header) => pw.Container(
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
                            ),
                          )
                          .toList(),
                ),
                // Các hàng dữ liệu
                ...dsDoanhThu.asMap().entries.map((entry) {
                  final index = entry.key;
                  final dt = entry.value;
                  final dataRow = [
                    DateFormat('MM/yyyy').format(dt.thang),
                    formatCurrencyPdf(dt.nhanVien),
                    formatCurrencyPdf(dt.hoaDonNhap),
                    formatCurrencyPdf(dt.khoNhap),
                    formatCurrencyPdf(dt.hoaDonXuat),
                    formatCurrencyPdf(dt.khoXuat),
                    formatCurrencyPdf(dt.tongTien),
                  ];
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: index % 2 == 0
                          ? PdfColors.grey100
                          : PdfColors.white,
                    ),
                    children: dataRow.asMap().entries.map((cellEntry) {
                      final cellIndex = cellEntry.key;
                      final cellData = cellEntry.value;
                      return pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 5,
                        ),
                        alignment: cellIndex == 0
                            ? pw.Alignment.centerLeft
                            : pw.Alignment.centerRight,
                        child: pw.Text(
                          cellData,
                          style: const pw.TextStyle(fontSize: 9.5),
                        ),
                      );
                    }).toList(),
                  );
                }),

                // Hàng TỔNG NĂM
                _buildTotalRowPdf(totals, formatCurrencyPdf),
              ],
            ),

            // 3. Footer
            pw.Spacer(),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  "Ngày xuất: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}",
                  style: const pw.TextStyle(fontSize: 9),
                ),
                pw.Text(
                  "Người lập: NGUYEN DUY KHANH",
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

pw.TableRow _buildTotalRowPdf(
  Map<String, double> totals,
  String Function(num?) formatCurrencyPdf,
) {
  final totalData = [
    'TỔNG NĂM',
    formatCurrencyPdf(totals['tongNhanVien']),
    formatCurrencyPdf(totals['tongHDNhap']),
    formatCurrencyPdf(totals['tongKhoNhap']),
    formatCurrencyPdf(totals['tongHDXuat']),
    formatCurrencyPdf(totals['tongKhoXuat']),
    formatCurrencyPdf(totals['tongLoiNhuan']),
  ];

  return pw.TableRow(
    decoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
    children: totalData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;

      final isProfitCell = index == totalData.length - 1;
      final profitColor = (totals['tongLoiNhuan'] ?? 0) >= 0
          ? PdfColors.green800
          : PdfColors.red800;
      final defaultStyle = pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 10,
      );

      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        alignment: index == 0
            ? pw.Alignment.centerLeft
            : pw.Alignment.centerRight,
        child: pw.Text(
          data,
          style: isProfitCell
              ? defaultStyle.copyWith(color: profitColor, fontSize: 11)
              : defaultStyle,
        ),
      );
    }).toList(),
  );
}
