import 'package:flutter/foundation.dart';

import '../core/services/firestore_service.dart';
import '../models/payment_model.dart';

class EarningsProvider extends ChangeNotifier {
  EarningsProvider({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  final FirestoreService _firestoreService;

  List<PaymentModel> _payments = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<PaymentModel> get payments => List.unmodifiable(_payments);

  List<PaymentModel> get paymentHistory {
    final sorted = [..._payments]
      ..sort((a, b) {
        final aDate = a.createdAt ?? DateTime(1970);
        final bDate = b.createdAt ?? DateTime(1970);
        return bDate.compareTo(aDate);
      });
    return sorted;
  }

  double get todayEarnings => _sumForDate(DateTime.now());

  double get monthlyEarnings {
    final now = DateTime.now();
    return _payments
        .where((p) {
          if (p.status != PaymentStatus.completed) return false;
          final d = p.createdAt;
          if (d == null) return false;
          return d.year == now.year && d.month == now.month;
        })
        .fold(0.0, (sum, p) => sum + p.amount);
  }

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  Future<bool> loadPayments(String artisanId) async {
    return _runAction(() async {
      _payments = await _firestoreService.getPaymentsByArtisan(artisanId);
    });
  }

  double _sumForDate(DateTime date) {
    return _payments
        .where((p) {
          if (p.status != PaymentStatus.completed) return false;
          final d = p.createdAt;
          if (d == null) return false;
          return d.year == date.year &&
              d.month == date.month &&
              d.day == date.day;
        })
        .fold(0.0, (sum, p) => sum + p.amount);
  }

  Future<bool> _runAction(Future<void> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
