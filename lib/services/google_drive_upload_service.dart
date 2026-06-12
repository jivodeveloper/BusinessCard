import 'package:businesscard/core/app_config.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

class GoogleDriveUploadService {
  Future<String> uploadBusinessCardImage(String imagePath) async {
    final scriptUrl = AppConfig.googleAppsScriptUrl.trim();
    if (scriptUrl.isEmpty) {
      throw const GoogleDriveUploadException(
        'Google Apps Script URL is not configured.',
      );
    }

    final file = File(imagePath);
    if (!await file.exists()) {
      throw GoogleDriveUploadException(
        'The selected image could not be found at $imagePath.',
      );
    }

    // Apps Script cannot reliably read multipart *file* parts, so the image is
    // sent as base64 in a normal form field and decoded by the script instead.
    final bytes = await file.readAsBytes();
    final response = await _sendUploadRequest(
      initialUrl: Uri.parse(scriptUrl),
      fields: {
        'fileName': p.basename(imagePath),
        'name': p.basename(imagePath),
        'mimeType': _mimeTypeForPath(imagePath),
        'data': base64Encode(bytes),
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final location = response.headers['location'];
      if (location != null && location.trim().isNotEmpty) {
        throw const GoogleDriveUploadException(
          'Drive upload was redirected but could not be completed. '
          'Verify that the Apps Script web app is deployed for external access.',
        );
      }

      throw GoogleDriveUploadException(
        'Drive upload failed with status ${response.statusCode}.',
      );
    }

    final body = response.body.trim();
    if (body.isEmpty) {
      throw const GoogleDriveUploadException(
        'Drive upload succeeded but returned an empty response.',
      );
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        // The script signals a server-side failure with success:false. Surface
        // its message instead of saving the error JSON as if it were a URL.
        if (decoded['success'] == false) {
          final message = decoded['message'];
          throw GoogleDriveUploadException(
            message is String && message.trim().isNotEmpty
                ? 'Drive upload failed: ${message.trim()}'
                : 'Drive upload failed on the Apps Script side.',
          );
        }

        for (final key in const [
          'image_path',
          'filePath',
          'path',
          'url',
          'fileUrl',
          'webViewLink',
        ]) {
          final value = decoded[key];
          if (value is String && value.trim().isNotEmpty) {
            return value.trim();
          }
        }

        throw const GoogleDriveUploadException(
          'Drive upload succeeded but no image URL was returned by the script.',
        );
      }
    } on GoogleDriveUploadException {
      rethrow;
    } catch (_) {
      // Some Apps Script deployments return a plain-text URL instead of JSON.
    }

    // Only treat a plain-text body as a URL; never store a JSON error blob.
    if (body.startsWith('http')) {
      return body;
    }

    throw GoogleDriveUploadException(
      'Drive upload returned an unexpected response: $body',
    );
  }

  Future<http.Response> _sendUploadRequest({
    required Uri initialUrl,
    required Map<String, String> fields,
  }) async {
    // Apps Script web apps process doPost on the initial /exec request, then
    // hand the result back via a 302 redirect to script.googleusercontent.com.
    // dart:io does not auto-follow a 302 for a POST, so the body is posted
    // exactly once and every redirect afterwards is followed with a GET.
    var response = await http.post(initialUrl, body: fields);
    var currentUrl = initialUrl;

    for (var redirectCount = 0; redirectCount < 5; redirectCount++) {
      if (!_isRedirect(response.statusCode)) {
        return response;
      }

      final location = response.headers['location'];
      if (location == null || location.trim().isEmpty) {
        return response;
      }

      currentUrl = currentUrl.resolve(location);
      response = await http.get(currentUrl);
    }

    throw const GoogleDriveUploadException(
      'Drive upload redirected too many times.',
    );
  }

  String _mimeTypeForPath(String path) {
    final extension = p.extension(path).toLowerCase();
    switch (extension) {
      case '.png':
        return 'image/png';
      case '.heic':
        return 'image/heic';
      case '.webp':
        return 'image/webp';
      case '.jpg':
      case '.jpeg':
      default:
        return 'image/jpeg';
    }
  }

  bool _isRedirect(int statusCode) {
    return statusCode == 301 ||
        statusCode == 302 ||
        statusCode == 303 ||
        statusCode == 307 ||
        statusCode == 308;
  }
}

class GoogleDriveUploadException implements Exception {
  const GoogleDriveUploadException(this.message);

  final String message;

  @override
  String toString() => message;
}
