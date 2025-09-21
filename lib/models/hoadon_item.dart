// ------------------------- HoaDonItem -------------------------
class HoaDonItem {
  int id; // id item trong hóa đơn (0 = mới)
  String tenHang; // Tên hàng
  int soLuong; // Số lượng
  int giaTien; // Giá tiền 1 đơn vị (VND)

  HoaDonItem({
    this.id = 0,
    required this.tenHang,
    required this.soLuong,
    required this.giaTien,
  });

  /// Tạo từ JSON
  factory HoaDonItem.fromJson(Map<String, dynamic> json) {
    return HoaDonItem(
      id: json['id'] ?? 0,
      tenHang: json['tenHang'] ?? '',
      soLuong: json['soLuong'] ?? 0,
      giaTien: json['giaTien'] ?? 0,
    );
  }

  /// Chuyển sang JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenHang': tenHang,
      'soLuong': soLuong,
      'giaTien': giaTien,
      'thanhTien': thanhTien(), // tổng tiền từng mặt hàng
    };
  }

  /// Tổng tiền của item
  int thanhTien() => soLuong * giaTien;
}
