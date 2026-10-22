import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isUnauthorised => statusCode == 401;

  @override
  String toString() => message;
}

/// Thin JSON wrapper around `http` for the MedConnect backend.
class ApiClient {
  ApiClient({required this.baseUrlReader, required this.tokenReader, http.Client? client})
      : _http = client ?? http.Client();

  /// Current API base, e.g. https://medconnect-web.vercel.app/api (changes when the server is edited).
  final String Function() baseUrlReader;

  /// Returns the signed-in staff token (doctor / pharmacy / admin), if any.
  final String? Function() tokenReader;

  final http.Client _http;
  static const Duration _timeout = Duration(seconds: 20);

  Future<dynamic> get(String path, {Map<String, String>? query}) =>
      _send('GET', path, query: query);

  Future<dynamic> post(String path, [Object? body]) => _send('POST', path, body: body ?? const {});

  Future<dynamic> patch(String path, [Object? body]) => _send('PATCH', path, body: body ?? const {});

  Future<dynamic> _send(String method, String path, {Object? body, Map<String, String>? query}) async {
    final base = baseUrlReader();
    if (base.isEmpty) throw ApiException('Server address not set. Open Settings → Server.');
    final uri = Uri.parse('$base$path').replace(
      queryParameters: (query == null || query.isEmpty) ? null : query,
    );
    final headers = <String, String>{'Accept': 'application/json'};
    if (body != null) headers['Content-Type'] = 'application/json';
    final token = tokenReader();
    if (token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';

    final request = http.Request(method, uri)..headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);

    http.Response res;
    try {
      res = await http.Response.fromStream(await _http.send(request).timeout(_timeout));
    } on TimeoutException {
      throw ApiException('The server is taking too long. Check the internet connection.');
    } on SocketException {
      throw ApiException('Cannot reach the server. Check the internet connection.');
    } on http.ClientException {
      throw ApiException('Cannot reach the server. Check the internet connection.');
    } on HandshakeException {
      throw ApiException('Secure connection to the server failed. Check the server address.');
    } on FormatException {
      throw ApiException('The server address is not valid. Check Settings → Server.');
    }

    dynamic data;
    if (res.body.isNotEmpty) {
      try {
        data = jsonDecode(utf8.decode(res.bodyBytes));
      } catch (_) {
        data = null;
      }
    }

    if (res.statusCode >= 200 && res.statusCode < 300) return data;

    final message = (data is Map && data['error'] is String)
        ? data['error'] as String
        : res.statusCode == 404
            ? 'Not found on the server — is the server address correct?'
            : 'Request failed (${res.statusCode})';
    throw ApiException(message, statusCode: res.statusCode);
  }
}
