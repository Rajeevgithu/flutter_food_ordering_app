import 'dart:convert';
import 'dart:io' show File; // Only used on mobile
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CloudinaryService {
  static String get _cloudName => dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? "";
  static String get _uploadPreset =>
      dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? "";

  /// ✅ Upload an image to Cloudinary and return the secure URL
  static Future<String?> uploadImage(dynamic imageFile) async {
    try {
      if (_cloudName.isEmpty || _uploadPreset.isEmpty) {
        throw "⚠️ Cloudinary config missing in .env";
      }

      final url = Uri.parse(
        "https://api.cloudinary.com/v1_1/$_cloudName/image/upload",
      );

      http.Response response;

      if (kIsWeb) {
        // 🌐 Web: Use bytes from the XFile (ImagePicker for Web gives bytes)
        final bytes = await imageFile.readAsBytes();
        final base64Image = base64Encode(bytes);

        response = await http.post(
          url,
          body: {
            "file": "data:image/png;base64,$base64Image",
            "upload_preset": _uploadPreset,
          },
        );
      } else {
        // 📱 Mobile: Use multipart form upload
        final request = http.MultipartRequest("POST", url)
          ..fields['upload_preset'] = _uploadPreset
          ..files.add(
            await http.MultipartFile.fromPath("file", imageFile.path),
          );

        final streamedResponse = await request.send();
        response = await http.Response.fromStream(streamedResponse);
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("✅ Uploaded successfully: ${data['secure_url']}");
        return data['secure_url'];
      } else {
        print("❌ Upload failed: ${response.statusCode} → ${response.body}");
        return null;
      }
    } catch (e) {
      print("⚠️ Cloudinary upload error: $e");
      return null;
    }
  }
}
