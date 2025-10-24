// lib/services/notification_service.dart

import 'dart:convert';
import 'package:flutter/material.dart'; // Dòng này bắt buộc phải có
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/thongbao.dart';

var uuid = Uuid();

// ✨ ĐẢM BẢO CÓ "extends ChangeNotifier" Ở ĐÂY ✨
class NotificationService extends ChangeNotifier {
  final String _storageKey = "notifications";
  List<ThongBao> _notifications = [];

  List<ThongBao> get notifications => _notifications;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationService() {
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final String? notificationsString = prefs.getString(_storageKey);
    if (notificationsString != null) {
      final List<dynamic> jsonList = jsonDecode(notificationsString);
      _notifications = jsonList.map((json) => ThongBao.fromJson(json)).toList();
      _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }
    notifyListeners();
  }

  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final String notificationsString = jsonEncode(
      _notifications.map((n) => n.toJson()).toList(),
    );
    await prefs.setString(_storageKey, notificationsString);
  }

  Future<void> addNotification({
    required String title,
    required String body,
  }) async {
    final newNotification = ThongBao(
      id: uuid.v4(),
      title: title,
      body: body,
      timestamp: DateTime.now(),
    );
    _notifications.insert(0, newNotification);
    await _saveNotifications();
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isRead = true;
      await _saveNotifications();
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    for (var notification in _notifications) {
      notification.isRead = true;
    }
    await _saveNotifications();
    notifyListeners();
  }
}
