import 'package:intl/intl.dart';
import 'workday.dart';

class NhanVien {
  int id;
  String hoTen;
  String soDienThoai;
  String chucVu;
  double luongTheoGio; // VND thực
  String? anhDaiDien;
  List<WorkDay> workDays;

  NhanVien({
    required this.id,
    required this.hoTen,
    required this.soDienThoai,
    required this.chucVu,
    required this.luongTheoGio,
    this.anhDaiDien,
    List<WorkDay>? workDays,
  }) : workDays = workDays ?? [];

  int get tongSoGioDaChamCong => workDays.fold(0, (sum, wd) => sum + wd.soGio);
  int get tongSoBuoiLam => workDays.length;
  double get tongTienDaNhan => luongTheoGio * tongSoGioDaChamCong;

  // Tổng tiền hiển thị như một phép tính
  String get tongTienDaNhanCalculation {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(luongTheoGio)} × $tongSoGioDaChamCong = ${formatter.format(tongTienDaNhan)} ₫';
  }

  String get luongTheoGioFormatted {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(luongTheoGio)} ₫/giờ';
  }

  factory NhanVien.fromJson(Map<String, dynamic> json) {
    return NhanVien(
      id: json['id'] ?? 0,
      hoTen: json['hoTen'] ?? '',
      soDienThoai: json['soDienThoai'] ?? '',
      chucVu: json['chucVu'] ?? '',
      luongTheoGio: (json['luongTheoGio'] ?? 0).toDouble(),
      anhDaiDien: json['anhDaiDien'],
      workDays: json['workDays'] != null
          ? (json['workDays'] as List).map((e) => WorkDay.fromJson(e)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'hoTen': hoTen,
    'soDienThoai': soDienThoai,
    'chucVu': chucVu,
    'luongTheoGio': luongTheoGio,
    'anhDaiDien': anhDaiDien,
    'workDays': workDays.map((e) => e.toJson()).toList(),
  };
}
