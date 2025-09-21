import 'hoadon_item.dart';

class HoaDon {
  int id;
  String maHoaDon;
  List<HoaDonItem> items;
  int tongTien;
  DateTime? ngayLap;
  String? trangThai;
  String? loaiHoaDon; // null nếu chưa chọn

  HoaDon({
    this.id = 0,
    this.maHoaDon = '',
    this.items = const [],
    this.tongTien = 0,
    this.ngayLap,
    this.trangThai,
    this.loaiHoaDon, // không có default, bắt buộc chọn
  });

  factory HoaDon.fromJson(Map<String, dynamic> json) {
    return HoaDon(
      id: json['id'] ?? 0,
      maHoaDon: json['maHoaDon'] ?? '',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => HoaDonItem.fromJson(e))
          .toList(),
      tongTien: json['tongTien'] ?? 0,
      ngayLap: json['ngayLap'] != null ? DateTime.parse(json['ngayLap']) : null,
      trangThai: json['trangThai'],
      loaiHoaDon: json['loaiHoaDon'], // giữ nguyên null nếu chưa chọn
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
      'loaiHoaDon': loaiHoaDon, // sẽ null nếu chưa chọn
    };
  }

  void tinhTongTien() {
    tongTien = items.fold(0, (sum, item) => sum + item.thanhTien());
  }
}
