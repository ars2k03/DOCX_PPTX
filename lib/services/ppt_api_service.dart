import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../core/constants.dart';

class PptApiService {
  Future<Uint8List> generatePpt({
    required File file,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(apiEndpoint),
    );

    request.files.add(
      await http.MultipartFile.fromPath('file', file.path),
    );

    final streamed = await request.send().timeout(
      const Duration(seconds: 180),
    );

    final bodyBytes = await streamed.stream.toBytes();

    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      final body = utf8.decode(bodyBytes, allowMalformed: true);
      throw Exception(_extractServerMessage(body, streamed.statusCode));
    }

    return Uint8List.fromList(bodyBytes);
  }

  String _extractServerMessage(String body, int statusCode) {
    try {
      final decoded = jsonDecode(body);

      if (decoded is Map && decoded['detail'] != null) {
        return decoded['detail'].toString();
      }
    } catch (_) {
      // Ignore invalid JSON response.
    }

    if (body.trim().isNotEmpty) {
      return body.trim();
    }

    return 'Server error: $statusCode';
  }

  String friendlyError(Object error) {
    final text = error.toString();

    if (text.contains('Connection refused') ||
        text.contains('Failed host lookup') ||
        text.contains('SocketException')) {
      return 'Cannot connect to backend. Please run the FastAPI server first.';
    }

    if (text.contains('TimeoutException')) {
      return 'Generation timed out. Try again with a smaller DOCX file.';
    }

    return text.replaceFirst('Exception: ', '');
  }
}