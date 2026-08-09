import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/services/firestore_service.dart';
import '../core/utils/booking_workflow.dart';
import '../models/booking_model.dart';
import '../models/notification_model.dart';
import '../models/payment_model.dart';
import '../models/review_model.dart';
import '../models/user_model.dart';

class BookingProvider extends ChangeNotifier {
  BookingProvider({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  final FirestoreService _firestoreService;

  List<BookingModel> _bookings = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<BookingModel>>? _bookingsSubscription;
  String? _watchedUserId;
  bool _watchedAsArtisan = false;
  String? _loadedUserId;
  bool _loadedAsArtisan = false;
  int _loadGeneration = 0;

  List<BookingModel> get bookings => List.unmodifiable(_bookings);

  List<BookingModel> get pendingBookings => _bookings
      .where(
        (b) =>
            b.status == BookingStatus.awaitingApproval ||
            b.status == BookingStatus.pending ||
            b.status == BookingStatus.accepted ||
            b.status == BookingStatus.travelling ||
            b.status == BookingStatus.working ||
            b.status == BookingStatus.completed,
      )
      .toList();

  List<BookingModel> get completedBookings => _bookings
      .where(
        (b) =>
            b.status == BookingStatus.confirmed ||
            b.status == BookingStatus.paid,
      )
      .toList();

  List<BookingModel> get cancelledBookings =>
      _bookings.where((b) => b.status == BookingStatus.cancelled).toList();

  List<BookingModel> get recentBookings => _bookings.take(3).toList();

  List<BookingModel> get artisanPendingJobs =>
      _bookings.where((b) => b.status == BookingStatus.pending).toList();

  List<BookingModel> get activeJobs =>
      _bookings.where((b) => BookingWorkflow.isActive(b.status)).toList();

  List<BookingModel> get todaysJobs {
    final now = DateTime.now();
    return _bookings.where((b) {
      final d = b.scheduledDate;
      final isToday =
          d.year == now.year && d.month == now.month && d.day == now.day;
      return isToday &&
          b.status != BookingStatus.cancelled &&
          !BookingWorkflow.isFinished(b.status);
    }).toList();
  }

  List<BookingModel> get artisanCompletedJobs => completedBookings;

  List<BookingModel> get requestBookings =>
      _bookings.where((b) => b.status == BookingStatus.pending).toList();

  List<BookingModel> get awaitingCustomerConfirmation => _bookings
      .where((b) => b.status == BookingStatus.completed)
      .toList();

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  Future<bool> createBooking(BookingModel booking) async {
    return _runAction(() async {
      // Always store the artisan auth/user id so request lists match.
      final artisan = await _firestoreService.getArtisan(booking.artisanId);
      final artisanUserId = (artisan?.userId.isNotEmpty == true)
          ? artisan!.userId
          : booking.artisanId;

      final toSave = booking.copyWith(
        artisanId: artisanUserId,
        status: BookingStatus.awaitingApproval,
      );

      final bookingId = await _firestoreService.saveBooking(toSave);
      final saved = toSave.copyWith(id: bookingId);
      _bookings = [..._bookings, saved];
      _sortBookings();

      // Notify admins — artisan only gets the job after admin approval.
      await _notifyAdmins(
        type: NotificationType.awaitingAdminApproval,
        body:
            'New ${saved.serviceCategory} booking at ${saved.location} '
            'needs your approval before the artisan can start.',
        bookingId: saved.id,
      );

      await _notify(
        userId: saved.customerId,
        type: NotificationType.awaitingAdminApproval,
        body:
            'Your ${saved.serviceCategory} booking was submitted and is '
            'awaiting admin approval.',
        bookingId: saved.id,
      );
    });
  }

  /// Admin sends an approved job to the artisan.
  Future<bool> adminApproveBooking(String bookingId) async {
    return _runAction(() async {
      final booking = await _findBooking(bookingId);
      if (booking == null) {
        throw StateError('Booking not found.');
      }
      if (!BookingWorkflow.canAdminApprove(booking.status)) {
        throw StateError(
          'Only jobs awaiting admin can be approved. '
          'Current status: ${BookingWorkflow.label(booking.status)}.',
        );
      }

      final updated = booking.copyWith(status: BookingStatus.pending);
      await _firestoreService.updateBooking(updated);
      _replaceBooking(updated);

      await _notify(
        userId: updated.artisanId,
        type: NotificationType.newBooking,
        body:
            'Admin approved a ${updated.serviceCategory} job at '
            '${updated.location}. Open Booking Requests to accept and start work.',
        bookingId: updated.id,
      );

      await _notify(
        userId: updated.customerId,
        type: NotificationType.adminApprovedJob,
        body:
            'Admin approved your ${updated.serviceCategory} booking. '
            'The artisan can now accept the job.',
        bookingId: updated.id,
      );
    });
  }

  /// Admin rejects a job before it reaches the artisan.
  Future<bool> adminRejectBooking(String bookingId) async {
    return _runAction(() async {
      final booking = await _findBooking(bookingId);
      if (booking == null) {
        throw StateError('Booking not found.');
      }
      if (!BookingWorkflow.canAdminReject(booking.status)) {
        throw StateError(
          'Only jobs awaiting admin can be rejected. '
          'Current status: ${BookingWorkflow.label(booking.status)}.',
        );
      }

      final updated = booking.copyWith(status: BookingStatus.cancelled);
      await _firestoreService.updateBooking(updated);
      _replaceBooking(updated);

      await _notify(
        userId: updated.customerId,
        type: NotificationType.adminRejectedJob,
        body:
            'Admin rejected your ${updated.serviceCategory} booking at '
            '${updated.location}.',
        bookingId: updated.id,
      );
    });
  }

  Future<bool> cancelBooking(String bookingId) async {
    final booking = await _findBooking(bookingId);
    if (booking == null) {
      _errorMessage = 'Booking not found.';
      notifyListeners();
      return false;
    }
    if (!BookingWorkflow.canCustomerCancel(booking.status)) {
      _errorMessage =
          'This booking can no longer be cancelled. Current status: '
          '${BookingWorkflow.label(booking.status)}.';
      notifyListeners();
      return false;
    }
    final success = await updateStatus(bookingId, BookingStatus.cancelled);
    if (success && booking.status == BookingStatus.pending) {
      await _notify(
        userId: booking.artisanId,
        type: NotificationType.bookingCancelled,
        body:
            'A ${booking.serviceCategory} booking at ${booking.location} was cancelled.',
        bookingId: booking.id,
      );
    }
    return success;
  }

  Future<bool> acceptBooking(String bookingId) async {
    final booking = await _findBooking(bookingId);
    if (booking == null || !BookingWorkflow.canArtisanAccept(booking.status)) {
      _errorMessage = 'This booking cannot be accepted.';
      notifyListeners();
      return false;
    }
    final success = await updateStatus(bookingId, BookingStatus.accepted);
    if (success) {
      await _notify(
        userId: booking.customerId,
        type: NotificationType.bookingAccepted,
        body:
            'Your ${booking.serviceCategory} booking has been accepted.',
        bookingId: booking.id,
      );
    }
    return success;
  }

  Future<bool> rejectBooking(String bookingId) async {
    final booking = await _findBooking(bookingId);
    if (booking == null || !BookingWorkflow.canArtisanReject(booking.status)) {
      _errorMessage = 'This booking cannot be rejected.';
      notifyListeners();
      return false;
    }
    final success = await updateStatus(bookingId, BookingStatus.cancelled);
    if (success) {
      await _notify(
        userId: booking.customerId,
        type: NotificationType.bookingRejected,
        body:
            'Your ${booking.serviceCategory} booking was rejected by the artisan.',
        bookingId: booking.id,
      );
    }
    return success;
  }

  Future<bool> advanceBooking(String bookingId, {double? finalPrice}) async {
    final booking = await _findBooking(bookingId);
    if (booking == null) {
      _errorMessage = 'Booking not found.';
      notifyListeners();
      return false;
    }

    final next = BookingWorkflow.nextArtisanStatus(booking.status);
    if (next == null) {
      _errorMessage = 'No further action available.';
      notifyListeners();
      return false;
    }

    if (next == BookingStatus.completed && finalPrice == null) {
      _errorMessage = 'Final price is required to mark the job completed.';
      notifyListeners();
      return false;
    }

    if (!BookingWorkflow.canTransition(booking.status, next)) {
      _errorMessage =
          'Cannot move from ${BookingWorkflow.label(booking.status)} '
          'to ${BookingWorkflow.label(next)}.';
      notifyListeners();
      return false;
    }

    return _runAction(() async {
      final updated = booking.copyWith(
        status: next,
        finalPrice: next == BookingStatus.completed
            ? finalPrice
            : booking.finalPrice,
      );
      await _firestoreService.updateBooking(updated);
      _replaceBooking(updated);

      await _notifyCustomerOfProgress(updated);
    });
  }

  Future<bool> confirmCompletion(
    String bookingId, {
    PaymentMethod method = PaymentMethod.mobileMoney,
  }) async {
    return _runAction(() async {
      final booking = await _findBooking(bookingId);
      if (booking == null) {
        throw StateError('Booking not found.');
      }
      if (!BookingWorkflow.canCustomerConfirm(booking.status)) {
        throw StateError(
          'This booking is not ready for confirmation. '
          'Current status: ${BookingWorkflow.label(booking.status)}.',
        );
      }
      final amount = booking.paymentAmount > 0
          ? booking.paymentAmount
          : booking.estimatedPrice;
      if (amount <= 0) {
        throw StateError(
          'A valid price is required before payment. '
          'Ask the artisan to set a final price when marking done.',
        );
      }

      final now = DateTime.now();
      final confirmed = booking.copyWith(
        status: BookingStatus.confirmed,
        customerConfirmedAt: now,
      );
      await _firestoreService.updateBooking(confirmed);
      _replaceBooking(confirmed);

      await _releasePayment(confirmed, method: method);
    });
  }

  Future<bool> submitReview({
    required String bookingId,
    required String customerId,
    required String customerName,
    required double rating,
    String? comment,
  }) async {
    if (rating < 1 || rating > 5) {
      _errorMessage = 'Please select a rating between 1 and 5 stars.';
      notifyListeners();
      return false;
    }

    return _runAction(() async {
      final booking = await _findBooking(bookingId);
      if (booking == null) {
        throw StateError('Booking not found.');
      }
      if (!BookingWorkflow.canCustomerReview(booking)) {
        throw StateError('This booking cannot be reviewed.');
      }
      if (booking.customerId != customerId) {
        throw StateError('You can only review your own bookings.');
      }

      final review = ReviewModel(
        id: '',
        bookingId: booking.id,
        customerId: customerId,
        artisanId: booking.artisanId,
        rating: rating,
        comment: comment?.trim().isEmpty == true ? null : comment?.trim(),
        customerName: customerName,
      );

      await _firestoreService.submitReview(review);

      _replaceBooking(booking.copyWith(hasReviewed: true));
    });
  }

  Future<void> _notifyCustomerOfProgress(BookingModel booking) async {
    NotificationType? type;
    String? body;

    switch (booking.status) {
      case BookingStatus.travelling:
        type = NotificationType.artisanTravelling;
        body =
            'Your ${booking.serviceCategory} artisan is travelling to ${booking.location}.';
      case BookingStatus.working:
        type = NotificationType.workStarted;
        body =
            'The artisan has started work on your ${booking.serviceCategory} booking.';
      case BookingStatus.completed:
        type = NotificationType.jobCompleted;
        body =
            'Your ${booking.serviceCategory} job is done. Please confirm and pay '
            'GHS ${booking.paymentAmount.toStringAsFixed(2)}.';
      default:
        break;
    }

    if (type == null || body == null) return;

    await _notify(
      userId: booking.customerId,
      type: type,
      body: body,
      bookingId: booking.id,
    );
  }

  Future<void> _releasePayment(
    BookingModel booking, {
    PaymentMethod method = PaymentMethod.mobileMoney,
  }) async {
    final shortId = booking.id.length >= 8
        ? booking.id.substring(0, 8)
        : booking.id;
    final txnId =
        'SIM-${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}';

    final payment = PaymentModel(
      id: '',
      bookingId: booking.id,
      customerId: booking.customerId,
      artisanId: booking.artisanId,
      amount: booking.paymentAmount,
      currency: 'GHS',
      status: PaymentStatus.completed,
      method: method,
      transactionId: txnId,
      reference: 'BK-$shortId',
    );

    await _firestoreService.savePayment(payment);

    final paid = booking.copyWith(
      status: BookingStatus.paid,
      paymentReleasedAt: DateTime.now(),
    );
    await _firestoreService.updateBooking(paid);
    _replaceBooking(paid);

    await _notify(
      userId: booking.artisanId,
      type: NotificationType.paymentReleased,
      body:
          'Payment of GHS ${booking.paymentAmount.toStringAsFixed(2)} '
          '(${method.value}) has been released for your '
          '${booking.serviceCategory} job. Ref: BK-$shortId',
      bookingId: booking.id,
    );

    await _notify(
      userId: booking.customerId,
      type: NotificationType.paymentReleased,
      body:
          'You paid GHS ${booking.paymentAmount.toStringAsFixed(2)} for '
          '${booking.serviceCategory}. Transaction: $txnId',
      bookingId: booking.id,
    );
  }

  Future<void> _notify({
    required String userId,
    required NotificationType type,
    required String body,
    String? bookingId,
  }) async {
    try {
      await _firestoreService.createNotification(
        userId: userId,
        title: type.defaultTitle,
        body: body,
        type: type,
        bookingId: bookingId,
      );
    } catch (_) {
      // Notification failures should not block booking workflow.
    }
  }

  Future<void> _notifyAdmins({
    required NotificationType type,
    required String body,
    String? bookingId,
  }) async {
    try {
      final users = await _firestoreService.getAllUsers();
      final admins = users.where((u) => u.role == UserRole.admin);
      for (final admin in admins) {
        await _notify(
          userId: admin.id,
          type: type,
          body: body,
          bookingId: bookingId,
        );
      }
    } catch (_) {
      // Non-blocking.
    }
  }

  Future<bool> updateStatus(String bookingId, BookingStatus status) async {
    return _runAction(() async {
      final booking = await _findBooking(bookingId);
      if (booking == null) {
        throw StateError('Booking not found.');
      }

      if (!BookingWorkflow.canTransition(booking.status, status)) {
        throw StateError(
          'Cannot change status from ${booking.status.name} to ${status.name}.',
        );
      }

      final updated = booking.copyWith(status: status);
      await _firestoreService.updateBooking(updated);
      _replaceBooking(updated);
    });
  }

  Future<bool> loadBookingHistory({
    required String userId,
    bool asArtisan = false,
  }) async {
    // Drop a previous user's realtime watcher so it cannot overwrite this load.
    if (_watchedUserId != null &&
        (_watchedUserId != userId || _watchedAsArtisan != asArtisan)) {
      stopWatchingBookings();
    }

    final generation = ++_loadGeneration;

    return _runAction(() async {
      final loaded = asArtisan
          ? await _firestoreService.getBookingsByArtisan(userId)
          : await _firestoreService.getBookingsByCustomer(userId);

      // Ignore stale responses from an older in-flight load.
      if (generation != _loadGeneration) return;

      // Never blank a list we already showed for this user with an empty
      // race/glitch response.
      if (loaded.isEmpty &&
          _bookings.isNotEmpty &&
          _loadedUserId == userId &&
          _loadedAsArtisan == asArtisan) {
        return;
      }

      _bookings = loaded;
      _loadedUserId = userId;
      _loadedAsArtisan = asArtisan;
      _sortBookings();
    });
  }

  /// Loads bookings over REST (reliable), then optionally listens for changes.
  /// Realtime stream rows are not trusted as the only data source — they often
  /// never emit on Supabase unless Realtime is enabled for the table.
  Future<bool> watchBookingHistory({
    required String userId,
    bool asArtisan = false,
    bool force = false,
  }) async {
    final alreadyWatching = !force &&
        _watchedUserId == userId &&
        _watchedAsArtisan == asArtisan &&
        _bookingsSubscription != null;

    // Always fetch via REST so the artisan list is never stuck empty/loading.
    final loaded = await loadBookingHistory(
      userId: userId,
      asArtisan: asArtisan,
    );

    if (alreadyWatching) return loaded;

    _bookingsSubscription?.cancel();
    _watchedUserId = userId;
    _watchedAsArtisan = asArtisan;

    final stream = asArtisan
        ? _firestoreService.watchBookingsByArtisan(userId)
        : _firestoreService.watchBookingsByCustomer(userId);

    _bookingsSubscription = stream.listen(
      (_) {
        // Ignore stale events from a previous session/user.
        if (_watchedUserId != userId || _watchedAsArtisan != asArtisan) {
          return;
        }
        // On any realtime signal, re-fetch with the robust REST query.
        loadBookingHistory(userId: userId, asArtisan: asArtisan);
      },
      onError: (Object error) {
        if (_watchedUserId != userId || _watchedAsArtisan != asArtisan) {
          return;
        }
        // Keep the REST-loaded data; only surface the error.
        _errorMessage = error.toString();
        notifyListeners();
      },
    );

    return loaded;
  }

  void stopWatchingBookings() {
    _bookingsSubscription?.cancel();
    _bookingsSubscription = null;
    _watchedUserId = null;
  }

  /// Clears bookings and watchers — call on logout / before a new login.
  void reset() {
    stopWatchingBookings();
    _bookings = [];
    _isLoading = false;
    _errorMessage = null;
    _watchedAsArtisan = false;
    _loadedUserId = null;
    _loadedAsArtisan = false;
    _loadGeneration++;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<BookingModel?> _findBooking(String bookingId) async {
    final local = _bookings.where((b) => b.id == bookingId).firstOrNull;
    if (local != null) return local;
    return _firestoreService.getBooking(bookingId);
  }

  void _replaceBooking(BookingModel updated) {
    final index = _bookings.indexWhere((b) => b.id == updated.id);
    if (index == -1) {
      _bookings = [..._bookings, updated];
    } else {
      _bookings = [
        ..._bookings.sublist(0, index),
        updated,
        ..._bookings.sublist(index + 1),
      ];
    }
    _sortBookings();
  }

  void _sortBookings() {
    _bookings.sort(
      (a, b) => b.scheduledDate.compareTo(a.scheduledDate),
    );
  }

  Future<bool> _runAction(Future<void> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
      return true;
    } on StateError catch (e) {
      _errorMessage = e.message;
      return false;
    } on PostgrestException catch (e) {
      _errorMessage = e.code == '42501'
          ? 'Database permission error. Run supabase/fix_rls.sql, then try again.'
          : (e.message.isNotEmpty ? e.message : 'Database error.');
      return false;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
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

  @override
  void dispose() {
    _bookingsSubscription?.cancel();
    super.dispose();
  }
}
