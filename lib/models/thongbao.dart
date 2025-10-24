// lib/models/thongbao.dart

class ThongBao {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  bool isRead;

  ThongBao({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
  });

  // Chuyển đổi từ Map (JSON) sang đối tượng ThongBao
  factory ThongBao.fromJson(Map<String, dynamic> json) {
    return ThongBao(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'],
    );
  }

  // Chuyển đổi từ đối tượng ThongBao sang Map (JSON)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }
}
