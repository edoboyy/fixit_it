import 'package:flutter/material.dart';

import '../core/services/firestore_service.dart';
import '../core/utils/booking_workflow.dart';
import '../models/artisan_model.dart';
import '../models/booking_model.dart';
import '../models/notification_model.dart';
import '../models/payment_model.dart';
import '../models/user_model.dart';

class AdminProvider extends ChangeNotifier {
  AdminProvider({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  final FirestoreService _firestoreService;

  List<UserModel> _users = [];
  List<ArtisanModel> _artisans = [];
  List<BookingModel> _bookings = [];
  List<PaymentModel> _payments = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<UserModel> get users => List.unmodifiable(_users);
  List<ArtisanModel> get artisans => List.unmodifiable(_artisans);
  List<BookingModel> get bookings => List.unmodifiable(_bookings);
  List<PaymentModel> get payments => List.unmodifiable(_payments);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalUsers => _users.length;
  int get totalArtisans => _artisans.length;
  int get pendingVerifications =>
      _artisans.where((a) => !a.isVerified).length;
  int get totalBookings => _bookings.length;
  int get totalPayments => _payments.length;
  double get totalRevenue => _payments
      .where((p) => p.status == PaymentStatus.completed)
      .fold(0.0, (sum, p) => sum + p.amount);
  int get suspendedUsers => _users.where((u) => u.isSuspended).length;
  int get totalCustomers =>
      _users.where((u) => u.role == UserRole.customer).length;
  int get activeBookings => _bookings
      .where(
        (b) =>
            b.status != BookingStatus.cancelled &&
            b.status != BookingStatus.paid,
      )
      .length;

  /// All accounts including admins (for credential management).
  List<UserModel> get manageableUsers => List.unmodifiable(_users);

  List<UserModel> get customers =>
      _users.where((u) => u.role == UserRole.customer).toList();

  /// Recent platform activity for the admin overview.
  List<AdminActivityItem> get recentActivities {
    final items = <AdminActivityItem>[];

    for (final booking in _bookings.take(20)) {
      items.add(
        AdminActivityItem(
          title: '${booking.serviceCategory} · ${booking.status.name}',
          subtitle:
              'Customer ${booking.customerId.substring(0, 8)} → '
              'Artisan ${booking.artisanId.substring(0, 8)} · '
              '${booking.location}',
          timestamp: booking.updatedAt ?? booking.scheduledDate,
          icon: Icons.calendar_month,
        ),
      );
    }

    for (final payment in _payments.take(20)) {
      items.add(
        AdminActivityItem(
          title:
              'Payment GHS ${payment.amount.toStringAsFixed(2)} (${payment.status.name})',
          subtitle:
              '${payment.method.name} · Ref ${payment.reference ?? payment.id}',
          timestamp: payment.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
          icon: Icons.payments,
        ),
      );
    }

    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items.take(12).toList();
  }

  Future<bool> loadDashboard() async {
    return _runAction(() async {
      final results = await Future.wait([
        _firestoreService.getAllUsers(),
        _firestoreService.getArtisans(),
        _firestoreService.getAllBookings(),
        _firestoreService.getAllPayments(),
      ]);

      _users = results[0] as List<UserModel>;
      _artisans = results[1] as List<ArtisanModel>;
      _bookings = results[2] as List<BookingModel>;
      _payments = results[3] as List<PaymentModel>;

      _users.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      _artisans.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      _bookings.sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));
      _payments.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
    });
  }

  Future<bool> loadUsers() async {
    return _runAction(() async {
      _users = await _firestoreService.getAllUsers();
      _users.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    });
  }

  Future<bool> loadArtisans() async {
    return _runAction(() async {
      _artisans = await _firestoreService.getArtisans();
      _artisans.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    });
  }

  Future<bool> loadBookings() async {
    return _runAction(() async {
      _bookings = await _firestoreService.getAllBookings();
      _bookings.sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));
    });
  }

  Future<bool> loadPayments() async {
    return _runAction(() async {
      _payments = await _firestoreService.getAllPayments();
      _payments.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
    });
  }

  Future<bool> setUserSuspended(String userId, bool isSuspended) async {
    return _runAction(() async {
      await _firestoreService.setUserSuspended(userId, isSuspended);
      final index = _users.indexWhere((u) => u.id == userId);
      if (index != -1) {
        _users = [
          ..._users.sublist(0, index),
          _users[index].copyWith(isSuspended: isSuspended),
          ..._users.sublist(index + 1),
        ];
      }
    });
  }

  Future<bool> updateUserCredentials({
    required String userId,
    required String name,
    required String email,
    String? phone,
    String? location,
    required UserRole role,
    String? password,
    bool? isSuspended,
  }) async {
    return _runAction(() async {
      await _firestoreService.adminUpdateAccount(
        userId: userId,
        name: name,
        email: email,
        phone: phone,
        location: location,
        role: role,
        password: password,
        isSuspended: isSuspended,
      );

      final index = _users.indexWhere((u) => u.id == userId);
      if (index != -1) {
        final previous = _users[index];
        _users = [
          ..._users.sublist(0, index),
          previous.copyWith(
            name: name,
            email: email,
            phone: phone,
            location: location,
            role: role,
            password: (password != null && password.trim().length >= 6)
                ? password.trim()
                : previous.password,
            isSuspended: isSuspended ?? previous.isSuspended,
          ),
          ..._users.sublist(index + 1),
        ];
      } else {
        await loadUsers();
      }
    });
  }

  Future<bool> setArtisanVerified(String artisanId, bool isVerified) async {
    return _runAction(() async {
      await _firestoreService.setArtisanVerified(artisanId, isVerified);
      final index = _artisans.indexWhere((a) => a.id == artisanId);
      ArtisanModel? artisan;
      if (index != -1) {
        artisan = _artisans[index].copyWith(isVerified: isVerified);
        _artisans = [
          ..._artisans.sublist(0, index),
          artisan,
          ..._artisans.sublist(index + 1),
        ];
      } else {
        artisan = await _firestoreService.getArtisan(artisanId);
      }

      // Notify outside the critical path so verify UI never stays stuck loading.
      if (isVerified && artisan != null) {
        final notifyId =
            artisan.userId.isNotEmpty ? artisan.userId : artisan.id;
        _notifyArtisanVerified(notifyId);
      }
    });
  }

  void _notifyArtisanVerified(String userId) {
    _sendNotification(
      userId: userId,
      type: NotificationType.artisanVerified,
      body:
          'Your artisan account has been verified. You can now receive '
          'approved job requests from customers.',
    );
  }

  void _sendNotification({
    required String userId,
    required NotificationType type,
    required String body,
    String? bookingId,
  }) {
    Future<void>(() async {
      try {
        await _firestoreService.createNotification(
          userId: userId,
          title: type.defaultTitle,
          body: body,
          type: type,
          bookingId: bookingId,
        );
      } catch (_) {
        // Non-blocking.
      }
    });
  }

  List<BookingModel> get awaitingApprovalBookings => _bookings
      .where((b) => b.status == BookingStatus.awaitingApproval)
      .toList();

  Future<bool> approveBooking(String bookingId) async {
    return _runAction(() async {
      final booking = _bookings.where((b) => b.id == bookingId).firstOrNull ??
          await _firestoreService.getBooking(bookingId);
      if (booking == null) {
        throw StateError('Booking not found.');
      }

      if (!BookingWorkflow.canAdminApprove(booking.status)) {
        throw StateError(
          'This booking was already sent to the artisan '
          '(${BookingWorkflow.label(booking.status)}).',
        );
      }

      // Resolve artisan auth id so the request list can find the job.
      final artisan = await _firestoreService.getArtisan(booking.artisanId);
      final artisanUserId = (artisan?.userId.isNotEmpty == true)
          ? artisan!.userId
          : booking.artisanId;

      final updated = booking.copyWith(
        status: BookingStatus.pending,
        artisanId: artisanUserId,
      );
      await _firestoreService.updateBooking(updated);

      // Refresh from server so the admin queue updates immediately.
      _bookings = await _firestoreService.getAllBookings();
      _bookings.sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));

      _sendNotification(
        userId: artisanUserId,
        type: NotificationType.newBooking,
        body:
            'Admin approved a ${updated.serviceCategory} job at '
            '${updated.location}. Open Booking Requests → Accept to start.',
        bookingId: updated.id,
      );
      _sendNotification(
        userId: updated.customerId,
        type: NotificationType.adminApprovedJob,
        body:
            'Admin approved your ${updated.serviceCategory} booking. '
            'The artisan can now accept and work on it.',
        bookingId: updated.id,
      );
    });
  }

  Future<bool> rejectBooking(String bookingId) async {
    return _runAction(() async {
      final booking = _bookings.where((b) => b.id == bookingId).firstOrNull ??
          await _firestoreService.getBooking(bookingId);
      if (booking == null) {
        throw StateError('Booking not found.');
      }
      if (!BookingWorkflow.canAdminReject(booking.status)) {
        throw StateError(
          'This booking can no longer be rejected by admin.',
        );
      }

      final updated = booking.copyWith(status: BookingStatus.cancelled);
      await _firestoreService.updateBooking(updated);
      _bookings = await _firestoreService.getAllBookings();
      _bookings.sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));

      _sendNotification(
        userId: updated.customerId,
        type: NotificationType.adminRejectedJob,
        body:
            'Admin rejected your ${updated.serviceCategory} booking at '
            '${updated.location}.',
        bookingId: updated.id,
      );
    });
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> _runAction(Future<void> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
      return true;
    } catch (e) {
      final raw = e.toString();
      _errorMessage = raw.startsWith('Exception: ')
          ? raw.substring('Exception: '.length)
          : raw;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

class AdminActivityItem {
  const AdminActivityItem({
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final DateTime timestamp;
  final IconData icon;
}
