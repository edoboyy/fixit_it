import 'package:fixit_gh/core/utils/booking_workflow.dart';
import 'package:fixit_gh/models/booking_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BookingWorkflow lifecycle', () {
    test('defines the full happy-path sequence', () {
      expect(BookingWorkflow.lifecycle, [
        BookingStatus.awaitingApproval,
        BookingStatus.pending,
        BookingStatus.accepted,
        BookingStatus.travelling,
        BookingStatus.working,
        BookingStatus.completed,
        BookingStatus.confirmed,
        BookingStatus.paid,
      ]);
    });

    test('allows admin approve then artisan accept', () {
      expect(
        BookingWorkflow.canTransition(
          BookingStatus.awaitingApproval,
          BookingStatus.pending,
        ),
        isTrue,
      );
      expect(
        BookingWorkflow.canTransition(
          BookingStatus.pending,
          BookingStatus.accepted,
        ),
        isTrue,
      );
      expect(
        BookingWorkflow.canAdminApprove(BookingStatus.awaitingApproval),
        isTrue,
      );
      expect(
        BookingWorkflow.canAdminApprove(BookingStatus.pending),
        isFalse,
      );
      expect(
        BookingWorkflow.canArtisanAccept(BookingStatus.awaitingApproval),
        isFalse,
      );
      expect(
        BookingWorkflow.canArtisanAccept(BookingStatus.pending),
        isTrue,
      );
    });

    test('allows valid artisan advance transitions', () {
      expect(
        BookingWorkflow.canTransition(
          BookingStatus.accepted,
          BookingStatus.travelling,
        ),
        isTrue,
      );
      expect(
        BookingWorkflow.canTransition(
          BookingStatus.travelling,
          BookingStatus.working,
        ),
        isTrue,
      );
      expect(
        BookingWorkflow.canTransition(
          BookingStatus.working,
          BookingStatus.completed,
        ),
        isTrue,
      );
    });

    test('allows customer confirm and payment release', () {
      expect(
        BookingWorkflow.canTransition(
          BookingStatus.completed,
          BookingStatus.confirmed,
        ),
        isTrue,
      );
      expect(
        BookingWorkflow.canTransition(
          BookingStatus.confirmed,
          BookingStatus.paid,
        ),
        isTrue,
      );
    });

    test('allows cancel from awaitingApproval or pending', () {
      expect(
        BookingWorkflow.canTransition(
          BookingStatus.awaitingApproval,
          BookingStatus.cancelled,
        ),
        isTrue,
      );
      expect(
        BookingWorkflow.canTransition(
          BookingStatus.pending,
          BookingStatus.cancelled,
        ),
        isTrue,
      );
      expect(
        BookingWorkflow.canTransition(
          BookingStatus.accepted,
          BookingStatus.cancelled,
        ),
        isFalse,
      );
    });

    test('blocks skipping lifecycle steps', () {
      expect(
        BookingWorkflow.canTransition(
          BookingStatus.awaitingApproval,
          BookingStatus.accepted,
        ),
        isFalse,
      );
      expect(
        BookingWorkflow.canTransition(
          BookingStatus.pending,
          BookingStatus.travelling,
        ),
        isFalse,
      );
    });

    test('nextArtisanStatus returns correct next step', () {
      expect(
        BookingWorkflow.nextArtisanStatus(BookingStatus.accepted),
        BookingStatus.travelling,
      );
      expect(
        BookingWorkflow.nextArtisanStatus(BookingStatus.working),
        BookingStatus.completed,
      );
      expect(
        BookingWorkflow.nextArtisanStatus(BookingStatus.completed),
        isNull,
      );
    });

    test('customer can confirm only when completed', () {
      expect(BookingWorkflow.canCustomerConfirm(BookingStatus.completed), isTrue);
      expect(BookingWorkflow.canCustomerConfirm(BookingStatus.working), isFalse);
    });
  });
}
