// models/hoadon_item.dart

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
      // ✅ ĐÃ SỬA: Xử lý số lớn an toàn khi đọc từ JSON
      giaTien: (json['giaTien'] as num? ?? 0).toInt(),
    );
  }

  /// Chuyển sang JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenHang': tenHang,
      'soLuong': soLuong,
      'giaTien': giaTien,
      // 'thanhTien' không cần thiết vì backend sẽ tự tính
    };
  }

  /// Tổng tiền của item
  int thanhTien() => soLuong * giaTien;
}
