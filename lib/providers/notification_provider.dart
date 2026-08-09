import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/services/firestore_service.dart';
import '../models/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  final FirestoreService _firestoreService;

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<NotificationModel>>? _subscription;
  String? _watchedUserId;

  List<NotificationModel> get notifications =>
      List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  void watchNotifications(String userId) {
    if (_watchedUserId == userId) return;

    _subscription?.cancel();
    _watchedUserId = userId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _subscription = _firestoreService.watchNotifications(userId).listen(
      (items) {
        _notifications = items;
        _isLoading = false;
        notifyListeners();
      },
      onError: (Object error) {
        _errorMessage = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestoreService.markNotificationRead(notificationId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      await _firestoreService.markAllNotificationsRead(userId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void stopWatching() {
    _subscription?.cancel();
    _subscription = null;
    _watchedUserId = null;
  }

  void reset() {
    stopWatching();
    _notifications = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
