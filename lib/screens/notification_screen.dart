// lib/screens/notification_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../models/thongbao.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Lắng nghe sự thay đổi từ NotificationService
    final notificationService = Provider.of<NotificationService>(context);
    final notifications = notificationService.notifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông Báo'),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          // Nút để đánh dấu tất cả đã đọc
          TextButton(
            onPressed: () {
              notificationService.markAllAsRead();
            },
            child: const Text('Đọc hết', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: notifications.isEmpty
          ? const Center(
              child: Text(
                'Không có thông báo nào',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _buildNotificationItem(context, notification);
              },
            ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, ThongBao notification) {
    // Định dạng thời gian
    final timeAgo = formatTimeAgo(notification.timestamp);

    return Container(
      color: notification.isRead ? Colors.white : Colors.blue.shade50,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
          child: Icon(
            Icons.notifications,
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead
                ? FontWeight.normal
                : FontWeight.bold,
          ),
        ),
        subtitle: Text('${notification.body}\n$timeAgo'),
        isThreeLine: true,
        onTap: () {
          // Khi người dùng nhấn vào, đánh dấu là đã đọc
          Provider.of<NotificationService>(
            context,
            listen: false,
          ).markAsRead(notification.id);
        },
      ),
    );
  }

  // Hàm định dạng thời gian (ví dụ: "5 phút trước", "Hôm qua lúc 10:30")
  String formatTimeAgo(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} giây trước';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays == 1) {
      return 'Hôm qua lúc ${DateFormat('HH:mm').format(time)}';
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(time);
    }
  }
}
