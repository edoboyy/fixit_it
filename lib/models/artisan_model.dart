class ArtisanModel {
  const ArtisanModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    this.phone,
    required this.category,
    this.skills = const [],
    this.bio,
    this.photoUrl,
    this.location,
    this.latitude,
    this.longitude,
    this.rating = 0,
    this.reviewCount = 0,
    this.hourlyRate = 0,
    this.isAvailable = true,
    this.isVerified = false,
    this.experience,
    this.nationalId,
    this.certificateUrl,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String name;
  final String email;
  final String? phone;
  final String category;
  final List<String> skills;
  final String? bio;
  final String? photoUrl;
  final String? location;
  final double? latitude;
  final double? longitude;
  final double rating;
  final int reviewCount;
  final double hourlyRate;
  final bool isAvailable;
  final bool isVerified;
  final String? experience;
  final String? nationalId;
  final String? certificateUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ArtisanModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return ArtisanModel(
      id: id ?? map['id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      phone: map['phone']?.toString(),
      category: map['category']?.toString() ?? '',
      skills: _parseSkills(map['skills']),
      bio: map['bio']?.toString(),
      photoUrl: map['photoUrl']?.toString(),
      location: map['location']?.toString(),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
      hourlyRate: (map['hourlyRate'] as num?)?.toDouble() ?? 0,
      isAvailable: map['isAvailable'] != false,
      isVerified: map['isVerified'] == true,
      experience: map['experience']?.toString(),
      nationalId: map['nationalId']?.toString(),
      certificateUrl: map['certificateUrl']?.toString(),
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  static List<String> _parseSkills(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return const [];
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'category': category,
      'skills': skills,
      'bio': bio,
      'photoUrl': photoUrl,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'rating': rating,
      'reviewCount': reviewCount,
      'hourlyRate': hourlyRate,
      'isAvailable': isAvailable,
      'isVerified': isVerified,
      'experience': experience,
      'nationalId': nationalId,
      'certificateUrl': certificateUrl,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  ArtisanModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? email,
    String? phone,
    String? category,
    List<String>? skills,
    String? bio,
    String? photoUrl,
    String? location,
    double? latitude,
    double? longitude,
    double? rating,
    int? reviewCount,
    double? hourlyRate,
    bool? isAvailable,
    bool? isVerified,
    String? experience,
    String? nationalId,
    String? certificateUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ArtisanModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      category: category ?? this.category,
      skills: skills ?? this.skills,
      bio: bio ?? this.bio,
      photoUrl: photoUrl ?? this.photoUrl,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      isAvailable: isAvailable ?? this.isAvailable,
      isVerified: isVerified ?? this.isVerified,
      experience: experience ?? this.experience,
      nationalId: nationalId ?? this.nationalId,
      certificateUrl: certificateUrl ?? this.certificateUrl,
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
    return 'ArtisanModel(id: $id, name: $name, category: $category, rating: $rating)';
  }
}

