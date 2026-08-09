enum BookingStatus {
  /// Customer submitted — waiting for admin to approve for the artisan.
  awaitingApproval,
  /// Admin approved — waiting for the artisan to accept.
  pending,
  accepted,
  travelling,
  working,
  completed,
  confirmed,
  paid,
  cancelled;

  String get value => name;

  static BookingStatus fromString(String? value) {
    if (value == 'inProgress') return BookingStatus.working;
    return BookingStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => BookingStatus.awaitingApproval,
    );
  }
}

class BookingModel {
  const BookingModel({
    required this.id,
    required this.customerId,
    required this.artisanId,
    required this.serviceCategory,
    required this.description,
    required this.status,
    required this.scheduledDate,
    required this.location,
    this.latitude,
    this.longitude,
    this.estimatedPrice = 0,
    this.finalPrice,
    this.notes,
    this.customerConfirmedAt,
    this.paymentReleasedAt,
    this.hasReviewed = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String customerId;
  final String artisanId;
  final String serviceCategory;
  final String description;
  final BookingStatus status;
  final DateTime scheduledDate;
  final String location;
  final double? latitude;
  final double? longitude;
  final double estimatedPrice;
  final double? finalPrice;
  final String? notes;
  final DateTime? customerConfirmedAt;
  final DateTime? paymentReleasedAt;
  final bool hasReviewed;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  double get paymentAmount => finalPrice ?? estimatedPrice;

  factory BookingModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return BookingModel(
      id: id ?? map['id']?.toString() ?? '',
      customerId: map['customerId']?.toString() ?? '',
      artisanId: map['artisanId']?.toString() ?? '',
      serviceCategory: map['serviceCategory']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      status: BookingStatus.fromString(map['status']?.toString()),
      scheduledDate: _parseDateTime(map['scheduledDate']) ?? DateTime.now(),
      location: map['location']?.toString() ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      estimatedPrice: (map['estimatedPrice'] as num?)?.toDouble() ?? 0,
      finalPrice: (map['finalPrice'] as num?)?.toDouble(),
      notes: map['notes']?.toString(),
      customerConfirmedAt: _parseDateTime(map['customerConfirmedAt']),
      paymentReleasedAt: _parseDateTime(map['paymentReleasedAt']),
      hasReviewed: map['hasReviewed'] == true,
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'artisanId': artisanId,
      'serviceCategory': serviceCategory,
      'description': description,
      'status': status.value,
      'scheduledDate': scheduledDate.toIso8601String(),
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'estimatedPrice': estimatedPrice,
      'finalPrice': finalPrice,
      'notes': notes,
      'customerConfirmedAt': customerConfirmedAt?.toIso8601String(),
      'paymentReleasedAt': paymentReleasedAt?.toIso8601String(),
      'hasReviewed': hasReviewed,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  BookingModel copyWith({
    String? id,
    String? customerId,
    String? artisanId,
    String? serviceCategory,
    String? description,
    BookingStatus? status,
    DateTime? scheduledDate,
    String? location,
    double? latitude,
    double? longitude,
    double? estimatedPrice,
    double? finalPrice,
    String? notes,
    DateTime? customerConfirmedAt,
    DateTime? paymentReleasedAt,
    bool? hasReviewed,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BookingModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      artisanId: artisanId ?? this.artisanId,
      serviceCategory: serviceCategory ?? this.serviceCategory,
      description: description ?? this.description,
      status: status ?? this.status,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      finalPrice: finalPrice ?? this.finalPrice,
      notes: notes ?? this.notes,
      customerConfirmedAt: customerConfirmedAt ?? this.customerConfirmedAt,
      paymentReleasedAt: paymentReleasedAt ?? this.paymentReleasedAt,
      hasReviewed: hasReviewed ?? this.hasReviewed,
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
    return 'BookingModel(id: $id, status: ${status.value}, category: $serviceCategory)';
  }
}

