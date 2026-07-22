import 'dart:convert';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/api_config.dart';
import 'api_exception.dart';

typedef TokenProvider = Future<String?> Function();
typedef TokenRefresher = Future<bool> Function();

/// One file part for multipart requests.
class MultipartFilePart {
  const MultipartFilePart({
    required this.field,
    required this.filePath,
    this.filename,
    this.contentType,
  });

  final String field;
  final String filePath;
  final String? filename;
  final String? contentType;
}

class ApiClient {
  ApiClient({
    http.Client? httpClient,
    this.getAccessToken,
    this.refreshTokens,
  }) : _http = httpClient ?? http.Client();

  final http.Client _http;
  final TokenProvider? getAccessToken;
  final TokenRefresher? refreshTokens;

  Future<Map<String, dynamic>> get(
    String path, {
    bool authenticated = false,
  }) {
    return _request('GET', path, authenticated: authenticated);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) {
    return _request('POST', path, body: body, authenticated: authenticated);
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) {
    return _request('PATCH', path, body: body, authenticated: authenticated);
  }

  /// POST multipart/form-data (used for Create Delivery with parcel photos).
  Future<Map<String, dynamic>> postMultipart(
    String path, {
    Map<String, String>? fields,
    List<MultipartFilePart> files = const [],
    bool authenticated = false,
  }) {
    return _request(
      'POST',
      path,
      authenticated: authenticated,
      multipartFields: fields,
      multipartFiles: files,
    );
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? multipartFields,
    List<MultipartFilePart>? multipartFiles,
    bool authenticated = false,
    bool retried = false,
  }) async {
    final isMultipart = multipartFiles != null;
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    if (!isMultipart) {
      headers['Content-Type'] = 'application/json';
    }

    if (authenticated) {
      var token = getAccessToken != null ? await getAccessToken!() : null;

      if ((token == null || token.isEmpty) &&
          !retried &&
          refreshTokens != null) {
        final refreshed = await refreshTokens!();
        if (refreshed) {
          token = getAccessToken != null ? await getAccessToken!() : null;
        }
      }

      if (token == null || token.isEmpty) {
        throw const ApiException(
          message: 'Please sign in again to continue.',
          code: 'UNAUTHORIZED',
          statusCode: 401,
        );
      }

      headers['Authorization'] = 'Bearer $token';
    }

    final uri = Uri.parse('${ApiConfig.apiV1}$path');
    if (kDebugMode) {
      debugPrint('API → $method $uri');
    }

    late final http.Response response;
    try {
      if (isMultipart) {
        response = await _sendMultipart(
          uri,
          headers,
          multipartFields ?? const {},
          multipartFiles,
        );
      } else {
        response = await _send(method, uri, headers, body);
      }
    } on ApiException {
      rethrow;
    } on http.ClientException {
      throw const ApiException(
        message: 'Unable to reach the server. Check your connection and try again.',
        code: 'NETWORK_ERROR',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('API network error: $e');
      }
      throw const ApiException(
        message: 'Unable to reach the server. Check your connection and try again.',
        code: 'NETWORK_ERROR',
      );
    }

    if (kDebugMode) {
      debugPrint('API ← ${response.statusCode} $uri');
      if (response.body.isNotEmpty && response.body.length < 2000) {
        debugPrint('API body: ${response.body}');
      }
    }

    if (authenticated &&
        response.statusCode == 401 &&
        !retried &&
        refreshTokens != null) {
      final refreshed = await refreshTokens!();
      if (refreshed) {
        return _request(
          method,
          path,
          body: body,
          multipartFields: multipartFields,
          multipartFiles: multipartFiles,
          authenticated: authenticated,
          retried: true,
        );
      }
    }

    try {
      return _parseResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('API parse error: $e');
      }
      throw const ApiException(
        message: 'Received an invalid response from the server.',
        code: 'PARSE_ERROR',
      );
    }
  }

  Future<http.Response> _send(
    String method,
    Uri uri,
    Map<String, String> headers,
    Map<String, dynamic>? body,
  ) {
    switch (method) {
      case 'GET':
        return _http.get(uri, headers: headers);
      case 'POST':
        return _http.post(
          uri,
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        );
      case 'PATCH':
        return _http.patch(
          uri,
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        );
      default:
        throw ApiException(message: 'Unsupported HTTP method: $method');
    }
  }

  /// Reads photo bytes via [XFile] so uploads work on Android, iOS, and web.
  Future<http.Response> _sendMultipart(
    Uri uri,
    Map<String, String> headers,
    Map<String, String> fields,
    List<MultipartFilePart> files,
  ) async {
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(headers);
    request.fields.addAll(fields);

    for (final part in files) {
      final xfile = XFile(part.filePath);
      late final List<int> bytes;
      try {
        bytes = await xfile.readAsBytes();
      } catch (_) {
        throw const ApiException(
          message: 'Could not read parcel photo. Please re-add the photo and try again.',
          code: 'VALIDATION_ERROR',
        );
      }
      if (bytes.isEmpty) {
        throw const ApiException(
          message: 'Parcel photo is empty. Please re-add the photo and try again.',
          code: 'VALIDATION_ERROR',
        );
      }

      final name = part.filename ??
          _basename(part.filePath.isNotEmpty ? part.filePath : 'photo.jpg');
      final filename = name.contains('.') ? name : '$name.jpg';
      request.files.add(
        http.MultipartFile.fromBytes(
          part.field,
          bytes,
          filename: filename,
          contentType: _imageMediaType(filename),
        ),
      );
    }

    final streamed = await _http.send(request);
    return http.Response.fromStream(streamed);
  }

  static MediaType _imageMediaType(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    if (lower.endsWith('.webp')) return MediaType('image', 'webp');
    if (lower.endsWith('.heic')) return MediaType('image', 'heic');
    if (lower.endsWith('.heif')) return MediaType('image', 'heif');
    return MediaType('image', 'jpeg');
  }

  static String _basename(String path) {
    final normalized = path.replaceAll('\\', '/');
    final index = normalized.lastIndexOf('/');
    return index >= 0 ? normalized.substring(index + 1) : normalized;
  }

  Map<String, dynamic> _parseResponse(http.Response response) {
    Map<String, dynamic>? json;
    if (response.body.isNotEmpty) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        json = decoded;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (json == null) return {};
      if (json['success'] == true) {
        return json['data'] as Map<String, dynamic>? ?? {};
      }
      final error = json['error'];
      throw ApiException(
        message: error is Map ? (error['message'] as String? ?? 'Request failed') : 'Request failed',
        statusCode: response.statusCode,
        code: error is Map ? error['code'] as String? : null,
      );
    }

    final error = json?['error'];
    throw ApiException(
      message: error is Map
          ? (error['message'] as String? ?? 'Request failed')
          : 'Request failed (${response.statusCode})',
      statusCode: response.statusCode,
      code: error is Map ? error['code'] as String? : null,
    );
  }

  void dispose() => _http.close();
}
