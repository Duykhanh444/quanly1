import 'package:flutter/material.dart';
import 'package:quan_ly_xuong/services/api_service.dart';

class TongHopDanhSachScreen extends StatefulWidget {
  @override
  _TongHopDanhSachScreenState createState() => _TongHopDanhSachScreenState();
}

class _TongHopDanhSachScreenState extends State<TongHopDanhSachScreen> {
  List dsNhanVien = [];
  List dsHoaDon = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final nhanVien = await ApiService.layDanhSachNhanVien();
      final hoaDon = await ApiService.layDanhSachHoaDon();

      setState(() {
        dsNhanVien = nhanVien;
        dsHoaDon = hoaDon;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi khi tải dữ liệu: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading)
      return Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: Text("Tổng Danh Sách")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Danh sách nhân viên
            ExpansionTile(
              title: Text("Danh sách nhân viên (${dsNhanVien.length})"),
              children: dsNhanVien
                  .map(
                    (nv) => ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(nv['HoTen'] ?? ''),
                      subtitle: Text(nv['ChucVu'] ?? ''),
                    ),
                  )
                  .toList(),
            ),

            // Danh sách hóa đơn
            ExpansionTile(
              title: Text("Danh sách hóa đơn (${dsHoaDon.length})"),
              children: [
                // Đã thanh toán
                ExpansionTile(
                  title: Text("Đã thanh toán"),
                  children: dsHoaDon
                      .where((hd) => hd['TrangThai'] == "Đã thanh toán")
                      .map(
                        (hd) => ListTile(
                          leading: const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                          ),
                          title: Text(hd['MaHoaDon'] ?? ''),
                          subtitle: Text(
                            "Tổng tiền: ${hd['TongTien'] ?? 0} VNĐ",
                          ),
                        ),
                      )
                      .toList(),
                ),
                // Chưa thanh toán
                ExpansionTile(
                  title: Text("Chưa thanh toán"),
                  children: dsHoaDon
                      .where((hd) => hd['TrangThai'] == "Chưa thanh toán")
                      .map(
                        (hd) => ListTile(
                          leading: const Icon(
                            Icons.pending_actions,
                            color: Colors.red,
                          ),
                          title: Text(hd['MaHoaDon'] ?? ''),
                          subtitle: Text(
                            "Tổng tiền: ${hd['TongTien'] ?? 0} VNĐ",
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
