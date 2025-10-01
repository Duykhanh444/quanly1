class KhoHang {
  int id;
  String? tenKho; // Tên kho
  String? ghiChu; // Ghi chú
  double? giaTri; // Giá trị kho hàng
  DateTime? ngayNhap; // Ngày nhập kho
  DateTime? ngayXuat; // Ngày xuất kho (nếu có)
  String? trangThai; // "Hoạt động" hoặc "Đã xuất"

  KhoHang({
    required this.id,
    this.tenKho,
    this.ghiChu,
    this.giaTri,
    this.ngayNhap,
    this.ngayXuat,
    this.trangThai,
  });

  // ✅ Parse từ JSON (API trả về)
  factory KhoHang.fromJson(Map<String, dynamic> json) {
    return KhoHang(
      id: json['id'] ?? 0,
      tenKho: json['tenKho'] ?? "",
      ghiChu: json['ghiChu'],
      giaTri: json['giaTri'] != null
          ? (json['giaTri'] as num).toDouble()
          : 0.0, // đảm bảo luôn có số, tránh null
      ngayNhap: json['ngayNhap'] != null && json['ngayNhap'] != ""
          ? DateTime.parse(json['ngayNhap'])
          : null,
      ngayXuat: json['ngayXuat'] != null && json['ngayXuat'] != ""
          ? DateTime.parse(json['ngayXuat'])
          : null,
      trangThai: json['trangThai'] ?? "Hoạt động",
    );
  }

  // ✅ Convert sang JSON (gửi API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenKho': tenKho,
      'ghiChu': ghiChu,
      'giaTri': giaTri,
      'ngayNhap': ngayNhap?.toIso8601String(),
      'ngayXuat': ngayXuat?.toIso8601String(),
      'trangThai': trangThai,
    };
  }
}
