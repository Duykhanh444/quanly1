// models/hoadon.dart
import 'hoadon_item.dart';

class HoaDon {
  int id;
  String maHoaDon;
  List<HoaDonItem> items;
  int tongTien;
  DateTime? ngayLap;
  String? trangThai;
  String? loaiHoaDon; // "Nhập" hoặc "Xuất"
  String? phuongThuc; // "Tiền mặt" hoặc "Chuyển khoản"

  // Thông tin nhà cung cấp (nếu là Hóa đơn Nhập)
  String? supplierBankName;
  String? supplierAccount;
  String? supplierAccountName;

  HoaDon({
    this.id = 0,
    this.maHoaDon = '',
    List<HoaDonItem>? items, // Cho phép khởi tạo với list có thể null
    this.tongTien = 0,
    this.ngayLap,
    this.trangThai,
    this.loaiHoaDon,
    this.phuongThuc,
    this.supplierBankName,
    this.supplierAccount,
    this.supplierAccountName,
  }) : items = items ?? []; // Gán list rỗng nếu null

  factory HoaDon.fromJson(Map<String, dynamic> json) {
    return HoaDon(
      id: json['id'] ?? 0,
      maHoaDon: json['maHoaDon'] ?? '',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => HoaDonItem.fromJson(e))
          .toList(),
      // ✅ ĐÃ SỬA: Xử lý số lớn an toàn khi đọc từ JSON
      tongTien: (json['tongTien'] as num? ?? 0).toInt(),
      ngayLap: json['ngayLap'] != null ? DateTime.parse(json['ngayLap']) : null,
      trangThai: json['trangThai'],
      loaiHoaDon: json['loaiHoaDon'],
      phuongThuc: json['phuongThuc'],
      supplierBankName: json['supplierBankName'],
      supplierAccount: json['supplierAccount'],
      supplierAccountName: json['supplierAccountName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'maHoaDon': maHoaDon,
      'items': items.map((e) => e.toJson()).toList(),
      'tongTien': tongTien,
      'ngayLap': ngayLap?.toIso8601String(),
      'trangThai': trangThai,
      'loaiHoaDon': loaiHoaDon,
      'phuongThuc': phuongThuc,
      'supplierBankName': supplierBankName,
      'supplierAccount': supplierAccount,
      'supplierAccountName': supplierAccountName,
    };
  }

  void tinhTongTien() {
    tongTien = items.fold(0, (sum, item) => sum + item.thanhTien());
  }
}
