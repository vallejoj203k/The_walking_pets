import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../core/services/supabase_service.dart';

enum VerificationStatus { idle, uploading, verifying, approved, rejected, error }

class IdentityVerificationProvider extends ChangeNotifier {
  VerificationStatus _status = VerificationStatus.idle;
  String? _error;
  String? _rejectionReason;

  VerificationStatus get status => _status;
  String? get error => _error;
  String? get rejectionReason => _rejectionReason;
  bool get isLoading =>
      _status == VerificationStatus.uploading ||
      _status == VerificationStatus.verifying;

  Future<bool> submitVerification({
    required String userId,
    required File cedulaFront,
    required File cedulaBack,
    required File selfie,
  }) async {
    _status = VerificationStatus.uploading;
    _error = null;
    _rejectionReason = null;
    notifyListeners();

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final basePath = 'identity-docs/$userId/$timestamp';

      // Upload all three images to Supabase Storage
      final uploads = await Future.wait([
        _uploadFile('$basePath/cedula_front.jpg', cedulaFront),
        _uploadFile('$basePath/cedula_back.jpg', cedulaBack),
        _uploadFile('$basePath/selfie.jpg', selfie),
      ]);

      final cedulaFrontUrl = uploads[0];
      final cedulaBackUrl = uploads[1];
      final selfieUrl = uploads[2];

      if (cedulaFrontUrl == null || cedulaBackUrl == null || selfieUrl == null) {
        _status = VerificationStatus.error;
        _error = 'Error al subir las imágenes. Intenta de nuevo.';
        notifyListeners();
        return false;
      }

      // Save record in identity_verifications table
      await SupabaseService.client.from('identity_verifications').upsert({
        'user_id': userId,
        'cedula_front_url': cedulaFrontUrl,
        'cedula_back_url': cedulaBackUrl,
        'selfie_url': selfieUrl,
        'status': 'pending',
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');

      _status = VerificationStatus.verifying;
      notifyListeners();

      // Call Edge Function to verify with Face++
      final res = await SupabaseService.client.functions.invoke(
        'verify-identity',
        body: {
          'userId': userId,
          'cedulaFrontUrl': cedulaFrontUrl,
          'selfieUrl': selfieUrl,
        },
      );

      debugPrint('[IdentityVerification] result: ${res.data}');

      final status = res.data?['status'] as String?;

      if (status == 'approved') {
        _status = VerificationStatus.approved;
        notifyListeners();
        return true;
      } else {
        _status = VerificationStatus.rejected;
        _rejectionReason = res.data?['reason'] as String? ??
            'Las fotos no coinciden. Asegúrate de que tu rostro sea visible en ambas imágenes.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('[IdentityVerification] error: $e');
      _status = VerificationStatus.error;
      _error = 'Error de conexión. Intenta de nuevo.';
      notifyListeners();
      return false;
    }
  }

  Future<String?> _uploadFile(String path, File file) async {
    try {
      await SupabaseService.client.storage
          .from('identity-docs')
          .upload(path, file, fileOptions: const FileOptions(upsert: true));
      return SupabaseService.client.storage
          .from('identity-docs')
          .getPublicUrl(path);
    } catch (e) {
      debugPrint('[IdentityVerification] upload error: $e');
      return null;
    }
  }

  void reset() {
    _status = VerificationStatus.idle;
    _error = null;
    _rejectionReason = null;
    notifyListeners();
  }
}
