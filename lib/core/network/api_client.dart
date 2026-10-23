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

/// Thin JSON wrapper around `http` for the Gladskin Node.js API (MedConnect routes under /api/tele).
///
/// Sends `Authorization: Bearer <Firebase ID token>`. If the server says 401, it gets a brand-new
/// token and tries once more; if that also fails, [onUnauthorised] signs the device out.
/// Responses `{ success, data }` are unwrapped to `data`.
class ApiClient {
  ApiClient({
    required this.baseUrlReader,
    required this.tokenReader,
    this.onUnauthorised,
    http.Client? client,
  }) : _http = client ?? http.Client();

  /// Current API base, e.g. https://api-12v1.gladskin.in/api/tele
  final String Function() baseUrlReader;

  /// Current Firebase ID token (refreshed automatically), or null when signed out.
  final Future<String?> Function({bool forceRefresh}) tokenReader;

  final Future<void> Function()? onUnauthorised;

  final http.Client _http;
  static const Duration _timeout = Duration(seconds: 20);

  Future<dynamic> get(String path, {Map<String, String>? query}) => _send('GET', path, query: query);

  Future<dynamic> post(String path, [Object? body]) => _send('POST', path, body: body ?? const {});

  Future<dynamic> patch(String path, [Object? body]) => _send('PATCH', path, body: body ?? const {});

  Future<dynamic> _send(String method, String path, {Object? body, Map<String, String>? query}) async {
    final base = baseUrlReader();
    if (base.isEmpty) throw ApiException('Server address not set. Open Settings → Server.');

    var token = await tokenReader();
    var res = await _request(method, base, path, body: body, query: query, token: token);
    if (res.statusCode == 401 && token != null) {
      token = await tokenReader(forceRefresh: true);
      res = await _request(method, base, path, body: body, query: query, token: token);
      if (res.statusCode == 401) await onUnauthorised?.call();
    }

    dynamic data;
    if (res.body.isNotEmpty) {
      try {
        data = jsonDecode(utf8.decode(res.bodyBytes));
      } catch (_) {
        data = null;
      }
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (data is Map && data.containsKey('data') && data.length <= 3) return data['data'];
      return data;
    }

    final serverMessage = data is Map ? (data['message'] ?? data['error']) : null;
    final message = serverMessage is String && serverMessage.isNotEmpty
        ? serverMessage
        : res.statusCode == 404
            ? 'Not found on the server — is the server address correct?'
            : 'Request failed (${res.statusCode})';
    throw ApiException(message, statusCode: res.statusCode);
  }

  Future<http.Response> _request(String method, String base, String path,
      {Object? body, Map<String, String>? query, String? token}) async {
    final uri = Uri.parse('$base$path').replace(
      queryParameters: (query == null || query.isEmpty) ? null : query,
    );
    final headers = <String, String>{'Accept': 'application/json'};
    if (body != null) headers['Content-Type'] = 'application/json';
    if (token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';

    final request = http.Request(method, uri)..headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);

    try {
      return await http.Response.fromStream(await _http.send(request).timeout(_timeout));
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
  }
}
