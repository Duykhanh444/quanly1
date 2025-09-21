class WorkDay {
  int id;
  DateTime ngay;
  int soGio;

  WorkDay({required this.id, required this.ngay, required this.soGio});

  factory WorkDay.fromJson(Map<String, dynamic> json) {
    return WorkDay(
      id: json['id'] ?? 0,
      ngay: DateTime.parse(json['ngay']),
      soGio: json['soGio'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'ngay': ngay.toIso8601String(),
    'soGio': soGio,
  };
}
