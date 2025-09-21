class KhoHang {
  int id;
  String? tenKho; // ✅ tên chuẩn
  String? ghiChu;
  DateTime? ngayNhap;
  DateTime? ngayXuat;
  String? trangThai; // "Hoạt động" hoặc "Đã xuất"

  KhoHang({
    required this.id,
    this.tenKho,
    this.ghiChu,
    this.ngayNhap,
    this.ngayXuat,
    this.trangThai,
  });

  factory KhoHang.fromJson(Map<String, dynamic> json) {
    return KhoHang(
      id: json['id'],
      tenKho: json['tenKho'], // ✅ đúng key API trả về
      ghiChu: json['ghiChu'],
      ngayNhap: json['ngayNhap'] != null
          ? DateTime.parse(json['ngayNhap'])
          : null,
      ngayXuat: json['ngayXuat'] != null
          ? DateTime.parse(json['ngayXuat'])
          : null,
      trangThai: json['trangThai'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenKho': tenKho, // ✅ đúng field
      'ghiChu': ghiChu,
      'ngayNhap': ngayNhap?.toIso8601String(),
      'ngayXuat': ngayXuat?.toIso8601String(),
      'trangThai': trangThai,
    };
  }
}
