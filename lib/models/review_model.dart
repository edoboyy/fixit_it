class ReviewModel {
  const ReviewModel({
    required this.id,
    required this.bookingId,
    required this.customerId,
    required this.artisanId,
    required this.rating,
    this.comment,
    this.customerName,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String bookingId;
  final String customerId;
  final String artisanId;
  final double rating;
  final String? comment;
  final String? customerName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ReviewModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return ReviewModel(
      id: id ?? map['id'] as String? ?? '',
      bookingId: map['bookingId'] as String? ?? '',
      customerId: map['customerId'] as String? ?? '',
      artisanId: map['artisanId'] as String? ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      comment: map['comment'] as String?,
      customerName: map['customerName'] as String?,
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
      'rating': rating,
      'comment': comment,
      'customerName': customerName,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  ReviewModel copyWith({
    String? id,
    String? bookingId,
    String? customerId,
    String? artisanId,
    double? rating,
    String? comment,
    String? customerName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      customerId: customerId ?? this.customerId,
      artisanId: artisanId ?? this.artisanId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      customerName: customerName ?? this.customerName,
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
    return 'ReviewModel(id: $id, rating: $rating, artisanId: $artisanId)';
  }
}

