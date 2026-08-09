import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../models/artisan_model.dart';
import '../../models/booking_model.dart';
import '../../models/notification_model.dart';
import '../../models/payment_model.dart';
import '../../models/review_model.dart';
import '../../models/user_model.dart';
import '../../supabase/supabase_service.dart';

class FirestoreService {
  FirestoreService({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService.instance;

  final SupabaseService _supabaseService;
  final _uuid = const Uuid();

  static const String usersCollection = 'users';
  static const String artisansCollection = 'artisans';
  static const String bookingsCollection = 'bookings';
  static const String reviewsCollection = 'reviews';
  static const String paymentsCollection = 'payments';
  static const String notificationsCollection = 'notifications';

  SupabaseClient get _client => _supabaseService.client;

  String _newId() => _uuid.v4();

  Map<String, dynamic> _withTimestamps(
    Map<String, dynamic> data, {
    bool isCreate = false,
  }) {
    final now = DateTime.now().toIso8601String();
    data['updatedAt'] = now;
    if (isCreate && data['createdAt'] == null) {
      data['createdAt'] = now;
    }
    return data;
  }

  Future<void> saveUser(UserModel user) async {
    _ensureInitialized();
    final data = _withTimestamps(user.toMap(), isCreate: user.createdAt == null);
    await _client.from(usersCollection).upsert(data);
  }

  Future<void> updateUser(UserModel user) async {
    _ensureInitialized();
    final data = _withTimestamps(user.toMap());
    await _client.from(usersCollection).update(data).eq('id', user.id);
  }

  Future<UserModel?> getUser(String id) async {
    _ensureInitialized();
    final row =
        await _client.from(usersCollection).select().eq('id', id).maybeSingle();
    if (row == null) return null;
    return UserModel.fromMap(Map<String, dynamic>.from(row), id: id);
  }

  /// Resolve a login identifier to a user by email or exact name (username).
  Future<UserModel?> findUserByEmailOrName(String identifier) async {
    _ensureInitialized();
    final trimmed = identifier.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.contains('@')) {
      final byEmail = await _client
          .from(usersCollection)
          .select()
          .ilike('email', trimmed)
          .maybeSingle();
      if (byEmail != null) {
        return UserModel.fromMap(Map<String, dynamic>.from(byEmail));
      }
      return null;
    }

    final byName = await _client
        .from(usersCollection)
        .select()
        .ilike('name', trimmed)
        .limit(5);

    if (byName.isEmpty) return null;

    // Prefer exact case-insensitive match when multiple names exist.
    final exact = byName.cast<Map<String, dynamic>>().where(
          (row) =>
              (row['name'] as String? ?? '').toLowerCase() ==
              trimmed.toLowerCase(),
        );
    final row = exact.isNotEmpty ? exact.first : byName.first;
    return UserModel.fromMap(Map<String, dynamic>.from(row));
  }

  Future<List<ArtisanModel>> getArtisans({
    String? category,
    bool? isAvailable,
  }) async {
    _ensureInitialized();

    var query = _client.from(artisansCollection).select();

    if (category != null && category.isNotEmpty) {
      query = query.eq('category', category);
    }
    if (isAvailable != null) {
      query = query.eq('isAvailable', isAvailable);
    }

    final rows = await query;
    return rows
        .map((row) => ArtisanModel.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<void> saveArtisan(ArtisanModel artisan) async {
    _ensureInitialized();
    final id = artisan.id.isEmpty ? _newId() : artisan.id;
    final data = _withTimestamps(
      artisan.copyWith(id: id).toMap(),
      isCreate: artisan.createdAt == null,
    );
    await _client.from(artisansCollection).upsert(data);
  }

  Future<ArtisanModel?> getArtisan(String id) async {
    _ensureInitialized();
    final row = await _client
        .from(artisansCollection)
        .select()
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    return ArtisanModel.fromMap(Map<String, dynamic>.from(row), id: id);
  }

  Future<List<ReviewModel>> getReviewsByArtisan(String artisanId) async {
    _ensureInitialized();
    final rows = await _client
        .from(reviewsCollection)
        .select()
        .eq('artisanId', artisanId);
    return rows
        .map((row) => ReviewModel.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<List<PaymentModel>> getPaymentsByArtisan(String artisanId) async {
    _ensureInitialized();
    final rows = await _client
        .from(paymentsCollection)
        .select()
        .eq('artisanId', artisanId);
    return rows
        .map((row) => PaymentModel.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<String> saveBooking(BookingModel booking) async {
    _ensureInitialized();
    final id = booking.id.isEmpty ? _newId() : booking.id;
    final data = _withTimestamps(
      booking.copyWith(id: id).toMap(),
      isCreate: booking.createdAt == null,
    );
    await _client.from(bookingsCollection).upsert(data);
    return id;
  }

  Future<void> updateBooking(BookingModel booking) async {
    _ensureInitialized();
    final data = _withTimestamps(booking.toMap());
    await _client.from(bookingsCollection).update(data).eq('id', booking.id);
  }

  Future<BookingModel?> getBooking(String id) async {
    _ensureInitialized();
    final row = await _client
        .from(bookingsCollection)
        .select()
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    return BookingModel.fromMap(Map<String, dynamic>.from(row), id: id);
  }

  Future<List<BookingModel>> getBookingsByCustomer(String customerId) async {
    _ensureInitialized();
    final rows = await _client
        .from(bookingsCollection)
        .select()
        .eq('customerId', customerId);
    return rows
        .map((row) => BookingModel.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<List<BookingModel>> getBookingsByArtisan(String artisanId) async {
    _ensureInitialized();
    final ids = await _artisanIdentityIds(artisanId);
    final idSet = ids.toSet();

    // Prefer a simple eq / inFilter query (most common path).
    List<dynamic> rows;
    if (ids.length == 1) {
      rows = await _client
          .from(bookingsCollection)
          .select()
          .eq('artisanId', ids.first);
    } else {
      rows = await _client
          .from(bookingsCollection)
          .select()
          .inFilter('artisanId', ids);
    }

    // Fallback: some environments return empty for filtered queries; scan all.
    if (rows.isEmpty) {
      final all = await _client.from(bookingsCollection).select();
      rows = all
          .where(
            (row) => idSet.contains(
              Map<String, dynamic>.from(row as Map)['artisanId']?.toString(),
            ),
          )
          .toList();
    }

    final bookings = <BookingModel>[];
    for (final row in rows) {
      try {
        bookings.add(
          BookingModel.fromMap(Map<String, dynamic>.from(row as Map)),
        );
      } catch (e, st) {
        debugPrint('Skipping malformed booking row: $e\n$st');
      }
    }
    return bookings;
  }

  /// Collect possible artisan identity keys (auth uid / artisan row id).
  Future<List<String>> _artisanIdentityIds(String artisanId) async {
    final ids = <String>{artisanId};
    try {
      final artisan = await getArtisan(artisanId);
      if (artisan != null) {
        if (artisan.id.isNotEmpty) ids.add(artisan.id);
        if (artisan.userId.isNotEmpty) ids.add(artisan.userId);
      } else {
        // Also try matching artisans.userId == artisanId
        final rows = await _client
            .from(artisansCollection)
            .select('id, userId')
            .eq('userId', artisanId)
            .limit(1);
        if (rows.isNotEmpty) {
          final row = Map<String, dynamic>.from(rows.first);
          final id = row['id'] as String?;
          final userId = row['userId'] as String?;
          if (id != null && id.isNotEmpty) ids.add(id);
          if (userId != null && userId.isNotEmpty) ids.add(userId);
        }
      }
    } catch (_) {
      // Fall back to the original id only.
    }
    return ids.toList();
  }

  Stream<List<BookingModel>> watchBookingsByCustomer(String customerId) {
    _ensureInitialized();
    return _client
        .from(bookingsCollection)
        .stream(primaryKey: ['id'])
        .eq('customerId', customerId)
        .map(
          (rows) => rows
              .map((row) => BookingModel.fromMap(Map<String, dynamic>.from(row)))
              .toList(),
        );
  }

  Stream<List<BookingModel>> watchBookingsByArtisan(String artisanId) {
    _ensureInitialized();
    return _client
        .from(bookingsCollection)
        .stream(primaryKey: ['id'])
        .eq('artisanId', artisanId)
        .map(
          (rows) => rows
              .map((row) => BookingModel.fromMap(Map<String, dynamic>.from(row)))
              .toList(),
        );
  }

  Future<void> saveReview(ReviewModel review) async {
    _ensureInitialized();
    final id = review.id.isEmpty ? _newId() : review.id;
    final data = _withTimestamps(
      review.copyWith(id: id).toMap(),
      isCreate: review.createdAt == null,
    );
    await _client.from(reviewsCollection).upsert(data);
  }

  Future<String> submitReview(ReviewModel review) async {
    _ensureInitialized();

    final existing = await _client
        .from(reviewsCollection)
        .select('id')
        .eq('bookingId', review.bookingId)
        .limit(1);

    if (existing.isNotEmpty) {
      throw StateError('A review has already been submitted for this booking.');
    }

    final booking = await getBooking(review.bookingId);
    if (booking == null) {
      throw StateError('Booking not found.');
    }
    if (booking.hasReviewed) {
      throw StateError('This booking has already been reviewed.');
    }
    if (booking.status != BookingStatus.paid) {
      throw StateError(
        'You can only review after the job is completed and paid.',
      );
    }

    final artisan = await getArtisan(review.artisanId);
    final currentRating = artisan?.rating ?? 0;
    final currentCount = artisan?.reviewCount ?? 0;
    final newCount = currentCount + 1;
    final newRating =
        (currentRating * currentCount + review.rating) / newCount;

    final reviewId = review.id.isEmpty ? _newId() : review.id;
    final reviewData = _withTimestamps(
      review.copyWith(id: reviewId).toMap(),
      isCreate: true,
    );

    await _client.from(reviewsCollection).insert(reviewData);
    await _client.from(artisansCollection).update({
      'rating': newRating,
      'reviewCount': newCount,
      'updatedAt': DateTime.now().toIso8601String(),
    }).eq('id', review.artisanId);
    await _client.from(bookingsCollection).update({
      'hasReviewed': true,
      'updatedAt': DateTime.now().toIso8601String(),
    }).eq('id', review.bookingId);

    return reviewId;
  }

  Future<String> savePayment(PaymentModel payment) async {
    _ensureInitialized();
    final id = payment.id.isEmpty ? _newId() : payment.id;
    final data = _withTimestamps(
      payment.copyWith(id: id).toMap(),
      isCreate: payment.createdAt == null,
    );
    await _client.from(paymentsCollection).upsert(data);
    return id;
  }

  Future<List<UserModel>> getAllUsers() async {
    _ensureInitialized();
    final rows = await _client.from(usersCollection).select();
    return rows
        .map((row) => UserModel.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<void> setUserSuspended(String userId, bool isSuspended) async {
    _ensureInitialized();
    await _client.from(usersCollection).update({
      'isSuspended': isSuspended,
      'updatedAt': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  /// Admin updates account credentials (profile + Auth via SQL RPC).
  Future<void> adminUpdateAccount({
    required String userId,
    required String name,
    required String email,
    String? phone,
    String? location,
    required UserRole role,
    String? password,
    bool? isSuspended,
  }) async {
    _ensureInitialized();
    try {
      await _client.rpc(
        'admin_update_account',
        params: {
          'p_user_id': userId,
          'p_name': name,
          'p_email': email,
          'p_phone': phone ?? '',
          'p_location': location ?? '',
          'p_role': role.value,
          'p_password': password,
          'p_is_suspended': isSuspended,
        },
      );
    } on PostgrestException {
      // Fallback when RPC is not installed yet: update public.users only.
      final data = <String, dynamic>{
        'name': name,
        'email': email,
        'phone': phone,
        'location': location,
        'role': role.value,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      if (password != null && password.trim().length >= 6) {
        data['password'] = password.trim();
      }
      if (isSuspended != null) {
        data['isSuspended'] = isSuspended;
      }
      await _client.from(usersCollection).update(data).eq('id', userId);

      // Keep artisan mirror fields in sync when possible.
      if (role == UserRole.artisan) {
        await _client.from(artisansCollection).update({
          'name': name,
          'email': email,
          'phone': phone,
          'location': location,
          'updatedAt': DateTime.now().toIso8601String(),
        }).eq('userId', userId);
      }
    }
  }

  Future<void> setArtisanVerified(String artisanId, bool isVerified) async {
    _ensureInitialized();
    await _client.from(artisansCollection).update({
      'isVerified': isVerified,
      'updatedAt': DateTime.now().toIso8601String(),
    }).eq('id', artisanId);
  }

  Future<List<BookingModel>> getAllBookings() async {
    _ensureInitialized();
    final rows = await _client.from(bookingsCollection).select();
    return rows
        .map((row) => BookingModel.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<List<PaymentModel>> getAllPayments() async {
    _ensureInitialized();
    final rows = await _client.from(paymentsCollection).select();
    return rows
        .map((row) => PaymentModel.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<String> createNotification({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    String? bookingId,
  }) async {
    _ensureInitialized();
    final id = _newId();
    final notification = NotificationModel(
      id: id,
      userId: userId,
      title: title,
      body: body,
      type: type,
      bookingId: bookingId,
      createdAt: DateTime.now(),
    );
    await _client.from(notificationsCollection).insert(notification.toMap());
    return id;
  }

  Stream<List<NotificationModel>> watchNotifications(String userId) {
    _ensureInitialized();
    return _client
        .from(notificationsCollection)
        .stream(primaryKey: ['id'])
        .eq('userId', userId)
        .map((rows) {
      final items = rows
          .map(
            (row) => NotificationModel.fromMap(Map<String, dynamic>.from(row)),
          )
          .toList();
      items.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      return items;
    });
  }

  Future<void> markNotificationRead(String notificationId) async {
    _ensureInitialized();
    await _client
        .from(notificationsCollection)
        .update({'isRead': true}).eq('id', notificationId);
  }

  Future<void> markAllNotificationsRead(String userId) async {
    _ensureInitialized();
    await _client
        .from(notificationsCollection)
        .update({'isRead': true})
        .eq('userId', userId)
        .eq('isRead', false);
  }

  void _ensureInitialized() {
    if (!_supabaseService.isInitialized) {
      throw StateError(
        'Supabase is not set up. Paste your URL and anon key in '
        'lib/supabase/supabase_config.dart and run supabase/schema.sql.',
      );
    }
  }
}
