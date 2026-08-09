import '../../models/booking_model.dart';

/// Booking lifecycle:
/// awaitingApproval → pending → accepted → travelling → working → completed → confirmed → paid
class BookingWorkflow {
  BookingWorkflow._();

  static const List<BookingStatus> lifecycle = [
    BookingStatus.awaitingApproval,
    BookingStatus.pending,
    BookingStatus.accepted,
    BookingStatus.travelling,
    BookingStatus.working,
    BookingStatus.completed,
    BookingStatus.confirmed,
    BookingStatus.paid,
  ];

  static String label(BookingStatus status) {
    return switch (status) {
      BookingStatus.awaitingApproval => 'Awaiting Admin',
      BookingStatus.pending => 'Pending Artisan',
      BookingStatus.accepted => 'Accepted',
      BookingStatus.travelling => 'Travelling',
      BookingStatus.working => 'Working',
      BookingStatus.completed => 'Awaiting Confirmation',
      BookingStatus.confirmed => 'Confirmed',
      BookingStatus.paid => 'Payment Released',
      BookingStatus.cancelled => 'Cancelled',
    };
  }

  static String? artisanActionLabel(BookingStatus status) {
    return switch (status) {
      BookingStatus.accepted => 'On my way',
      BookingStatus.travelling => 'Start work',
      BookingStatus.working => 'Mark done',
      _ => null,
    };
  }

  static BookingStatus? nextArtisanStatus(BookingStatus status) {
    return switch (status) {
      BookingStatus.accepted => BookingStatus.travelling,
      BookingStatus.travelling => BookingStatus.working,
      BookingStatus.working => BookingStatus.completed,
      _ => null,
    };
  }

  static bool canCustomerConfirm(BookingStatus status) =>
      status == BookingStatus.completed;

  static bool canCustomerReview(BookingModel booking) =>
      booking.status == BookingStatus.paid && !booking.hasReviewed;

  static bool canCustomerCancel(BookingStatus status) =>
      status == BookingStatus.awaitingApproval ||
      status == BookingStatus.pending;

  static bool canArtisanAccept(BookingStatus status) =>
      status == BookingStatus.pending;

  static bool canArtisanReject(BookingStatus status) =>
      status == BookingStatus.pending;

  /// Only jobs still waiting on admin can be approved/rejected here.
  /// After approval they become `pending` and leave the admin queue.
  static bool canAdminApprove(BookingStatus status) =>
      status == BookingStatus.awaitingApproval;

  static bool canAdminReject(BookingStatus status) =>
      status == BookingStatus.awaitingApproval ||
      status == BookingStatus.pending;

  static bool canSetFinalPrice(BookingStatus status) =>
      status == BookingStatus.working;

  /// Validates allowed status transitions in the booking lifecycle.
  static bool canTransition(BookingStatus from, BookingStatus to) {
    if (from == to) return false;

    if (to == BookingStatus.cancelled) {
      return from == BookingStatus.awaitingApproval ||
          from == BookingStatus.pending;
    }

    return switch ((from, to)) {
      (BookingStatus.awaitingApproval, BookingStatus.pending) => true,
      (BookingStatus.pending, BookingStatus.accepted) => true,
      (BookingStatus.accepted, BookingStatus.travelling) => true,
      (BookingStatus.travelling, BookingStatus.working) => true,
      (BookingStatus.working, BookingStatus.completed) => true,
      (BookingStatus.completed, BookingStatus.confirmed) => true,
      (BookingStatus.confirmed, BookingStatus.paid) => true,
      _ => false,
    };
  }

  static bool isActive(BookingStatus status) =>
      status == BookingStatus.accepted ||
      status == BookingStatus.travelling ||
      status == BookingStatus.working;

  static bool isFinished(BookingStatus status) =>
      status == BookingStatus.confirmed || status == BookingStatus.paid;

  static int stepIndex(BookingStatus status) {
    if (status == BookingStatus.cancelled) return -1;
    final index = lifecycle.indexOf(status);
    return index < 0 ? 0 : index;
  }
}
