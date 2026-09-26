import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kkopiconnect_app/services/cloudinary_service.dart';

void main() {
  late Directory tempDirectory;
  late File imageFile;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('cloudinary-test-');
    imageFile = File('${tempDirectory.path}/drink.png');
    await imageFile.writeAsBytes([137, 80, 78, 71]);
  });

  tearDown(() async {
    await tempDirectory.delete(recursive: true);
  });

  test(
    'uploads with the configured unsigned preset and returns secure URL',
    () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.host, 'api.cloudinary.com');
        expect(request.url.path, '/v1_1/c1kodukt/image/upload');
        expect(
          request.headers['content-type'],
          startsWith('multipart/form-data; boundary='),
        );
        final body = String.fromCharCodes(request.bodyBytes);
        expect(body, contains('name="upload_preset"'));
        expect(body, contains('Kkopi.tea'));
        expect(body, contains('name="public_id"'));
        expect(body, contains('menu/iced-americano'));
        expect(body, contains('filename="drink.png"'));
        return http.Response(
          '{"secure_url":"https://res.cloudinary.com/c1kodukt/image/upload/drink.png","public_id":"menu/iced-americano","format":"png"}',
          200,
        );
      });
      final service = CloudinaryService(client: client);

      final result = await service.uploadImage(
        XFile(imageFile.path),
        publicId: 'menu/iced-americano',
      );

      expect(result.secureUrl, contains('https://res.cloudinary.com/'));
      expect(result.publicId, 'menu/iced-americano');
      expect(result.format, 'png');
      client.close();
    },
  );

  test(
    'throws a readable exception when Cloudinary rejects the upload',
    () async {
      final client = MockClient(
        (_) async => http.Response(
          '{"error":{"message":"Upload preset not found"}}',
          400,
        ),
      );
      final service = CloudinaryService(client: client);

      await expectLater(
        service.uploadImage(XFile(imageFile.path)),
        throwsA(
          isA<CloudinaryUploadException>().having(
            (error) => error.message,
            'message',
            'Upload preset not found',
          ),
        ),
      );
      client.close();
    },
  );
}
