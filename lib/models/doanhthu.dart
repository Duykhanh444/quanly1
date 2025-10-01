class DoanhThu {
  final int thang; // tháng (1-12)
  final double tongTien; // tổng doanh thu của tháng

  DoanhThu({required this.thang, required this.tongTien});

  // Chuyển từ JSON sang object
  factory DoanhThu.fromJson(Map<String, dynamic> json) {
    return DoanhThu(
      thang: json['thang'] ?? 0,
      tongTien: (json['tongTien'] ?? 0).toDouble(),
    );
  }

  // Chuyển từ object sang JSON
  Map<String, dynamic> toJson() {
    return {'thang': thang, 'tongTien': tongTien};
  }
}
