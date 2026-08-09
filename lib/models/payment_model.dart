enum PaymentStatus {
  pending,
  completed,
  failed,
  refunded;

  String get value => name;

  static PaymentStatus fromString(String? value) {
    return PaymentStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => PaymentStatus.pending,
    );
  }
}

enum PaymentMethod {
  mobileMoney,
  card,
  cash;

  String get value => name;

  static PaymentMethod fromString(String? value) {
    return PaymentMethod.values.firstWhere(
      (method) => method.name == value,
      orElse: () => PaymentMethod.mobileMoney,
    );
  }
}

class PaymentModel {
  const PaymentModel({
    required this.id,
    required this.bookingId,
    required this.customerId,
    required this.artisanId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.method,
    this.transactionId,
    this.reference,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String bookingId;
  final String customerId;
  final String artisanId;
  final double amount;
  final String currency;
  final PaymentStatus status;
  final PaymentMethod method;
  final String? transactionId;
  final String? reference;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory PaymentModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return PaymentModel(
      id: id ?? map['id'] as String? ?? '',
      bookingId: map['bookingId'] as String? ?? '',
      customerId: map['customerId'] as String? ?? '',
      artisanId: map['artisanId'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      currency: map['currency'] as String? ?? 'GHS',
      status: PaymentStatus.fromString(map['status'] as String?),
      method: PaymentMethod.fromString(map['method'] as String?),
      transactionId: map['transactionId'] as String?,
      reference: map['reference'] as String?,
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookingId': bookingId,
      'customerId': customerId,
      'artisanId': artisanId,
      'amount': amount,
      'currency': currency,
      'status': status.value,
      'method': method.value,
      'transactionId': transactionId,
      'reference': reference,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  PaymentModel copyWith({
    String? id,
    String? bookingId,
    String? customerId,
    String? artisanId,
    double? amount,
    String? currency,
    PaymentStatus? status,
    PaymentMethod? method,
    String? transactionId,
    String? reference,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      customerId: customerId ?? this.customerId,
      artisanId: artisanId ?? this.artisanId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      method: method ?? this.method,
      transactionId: transactionId ?? this.transactionId,
      reference: reference ?? this.reference,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  String toString() {
    return 'PaymentModel(id: $id, amount: $amount $currency, status: ${status.value})';
  }
}

