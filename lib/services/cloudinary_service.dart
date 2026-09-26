import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  CloudinaryService({http.Client? client}) : _client = client ?? http.Client();

  static const cloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
    defaultValue: 'c1kodukt',
  );
  static const uploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
    defaultValue: 'Kkopi.tea',
  );
  static const _uploadTimeout = Duration(seconds: 60);

  final http.Client _client;

  Uri get _uploadUri =>
      Uri.https('api.cloudinary.com', '/v1_1/$cloudName/image/upload');

  Future<CloudinaryUploadResult> uploadImage(
    XFile image, {
    String? publicId,
  }) async {
    final request = http.MultipartRequest('POST', _uploadUri)
      ..fields['upload_preset'] = uploadPreset;

    if (publicId != null && publicId.trim().isNotEmpty) {
      request.fields['public_id'] = publicId.trim();
    }

    request.files.add(await http.MultipartFile.fromPath('file', image.path));

    final streamedResponse = await _client
        .send(request)
        .timeout(_uploadTimeout);
    final response = await http.Response.fromStream(streamedResponse);
    final payload = _decodePayload(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = payload['error'];
      final message = error is Map<String, dynamic>
          ? error['message']?.toString()
          : null;
      throw CloudinaryUploadException(
        message ?? 'Cloudinary upload failed (${response.statusCode}).',
      );
    }

    final secureUrl = payload['secure_url'];
    if (secureUrl is! String || secureUrl.isEmpty) {
      throw const CloudinaryUploadException(
        'Cloudinary returned a response without a secure image URL.',
      );
    }

    return CloudinaryUploadResult(
      secureUrl: secureUrl,
      publicId: payload['public_id']?.toString() ?? '',
      format: payload['format']?.toString() ?? '',
    );
  }

  Map<String, dynamic> _decodePayload(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
    } on FormatException {
      // Convert malformed responses into the same typed upload error.
    }
    throw const CloudinaryUploadException(
      'Cloudinary returned an invalid response.',
    );
  }
}

class CloudinaryUploadResult {
  const CloudinaryUploadResult({
    required this.secureUrl,
    required this.publicId,
    required this.format,
  });

  final String secureUrl;
  final String publicId;
  final String format;
}

class CloudinaryUploadException implements Exception {
  const CloudinaryUploadException(this.message);

  final String message;

  @override
  String toString() => message;
}
