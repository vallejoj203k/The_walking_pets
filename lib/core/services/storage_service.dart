import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/constants/supabase_config.dart';
import 'supabase_service.dart';

class StorageService {
  SupabaseClient get _client => SupabaseService.client;

  Future<String> uploadAvatar({
    required File file,
    required String storagePath,
  }) async {
    await _client.storage.from(SupabaseConfig.avatarsBucket).upload(
          storagePath,
          file,
          fileOptions:
              const FileOptions(contentType: 'image/jpeg', upsert: true),
        );

    return _client.storage
        .from(SupabaseConfig.avatarsBucket)
        .getPublicUrl(storagePath);
  }
}
