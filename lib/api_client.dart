import 'dart:convert';

import 'package:http/http.dart' as http;

import 'object_item.dart';

class ApiException implements Exception {
  const ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => message;
}

class ApiClient {
  static final Uri _baseUri = Uri.parse('https://api.restful-api.dev/objects');

  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json',
  };

  Future<List<ObjectItem>> fetchAll() async {
    final response = await http.get(_baseUri);
    final list = _decode(response) as List<dynamic>;
    return list
        .map((json) => ObjectItem.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<ObjectItem> fetchById(String id) async {
    final response = await http.get(_objectUri(id));
    return ObjectItem.fromJson(_decode(response) as Map<String, dynamic>);
  }

  Future<ObjectItem> create({
    required String name,
    Map<String, dynamic>? data,
  }) async {
    final response = await http.post(
      _baseUri,
      headers: _jsonHeaders,
      body: jsonEncode({'name': name, 'data': data}),
    );
    return ObjectItem.fromJson(_decode(response) as Map<String, dynamic>);
  }

  Future<ObjectItem> update(ObjectItem item) async {
    final response = await http.put(
      _objectUri(item.id),
      headers: _jsonHeaders,
      body: jsonEncode(item.toJson()),
    );
    return ObjectItem.fromJson(_decode(response) as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    final response = await http.delete(_objectUri(id));
    _decode(response);
  }

  Uri _objectUri(String id) =>
      _baseUri.replace(pathSegments: [..._baseUri.pathSegments, id]);

  dynamic _decode(http.Response response) {
    final body = utf8.decode(response.bodyBytes);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(response.statusCode, _errorMessage(response, body));
    }
    return jsonDecode(body);
  }


  String _errorMessage(http.Response response, String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> && decoded['error'] is String) {
        return decoded['error'] as String;
      }
    } on FormatException {
      // placeholder
    }
    return body.isNotEmpty
        ? body
        : 'Request failed with status ${response.statusCode}';
  }
}
