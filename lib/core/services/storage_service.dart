import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../supabase/supabase_service.dart';

class StorageService {
  StorageService({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService.instance;

  final SupabaseService _supabaseService;

  static const String certificatesBucket = 'certificates';
  static const String certificatesPath = 'certificates';
  static const String profilesPath = 'profiles';
  static const String bookingImagesPath = 'booking_images';

  Future<String> uploadProfilePicture({
    required String userId,
    required Uint8List imageBytes,
    required String fileName,
  }) {
    final path = '$profilesPath/$userId/$fileName';
    return _uploadFile(path: path, data: imageBytes);
  }

  Future<String> uploadArtisanCertificate({
    required String artisanId,
    required Uint8List fileBytes,
    required String fileName,
  }) {
    final path = 'artisans/$artisanId/$certificatesPath/$fileName';
    return _uploadFile(path: path, data: fileBytes);
  }

  Future<String> uploadBookingImage({
    required String bookingId,
    required Uint8List imageBytes,
    required String fileName,
  }) {
    final path = 'bookings/$bookingId/$bookingImagesPath/$fileName';
    return _uploadFile(path: path, data: imageBytes);
  }

  Future<String> _uploadFile({
    required String path,
    required Uint8List data,
  }) async {
    _ensureInitialized();

    await _supabaseService.client.storage.from(certificatesBucket).uploadBinary(
          path,
          data,
          fileOptions: const FileOptions(upsert: true),
        );

    return _supabaseService.client.storage
        .from(certificatesBucket)
        .getPublicUrl(path);
  }

  void _ensureInitialized() {
    if (!_supabaseService.isInitialized) {
      throw StateError(
        'Supabase is not set up. Paste your URL and anon key in '
        'lib/supabase/supabase_config.dart.',
      );
    }
  }
}
