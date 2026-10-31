import 'dart:convert';

import 'package:dio/dio.dart';

class ApiException implements Exception {
  ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({required this.baseUrl, this.token});

  final String baseUrl;
  final String? token;

  Future<dynamic> call(String method, [Map<String, dynamic>? args]) async {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (token != null && token!.isNotEmpty) 'Authorization': 'token $token',
        },
        validateStatus: (status) => status != null && status < 500,
      ),
    );
    final response = await dio.post('/api/method/$method', data: args ?? {});
    final data = response.data;
    if (response.statusCode != null && response.statusCode! >= 400) {
      throw ApiException(_message(data));
    }
    if (data is Map && data['exc_type'] != null) {
      throw ApiException(_message(data));
    }
    if (data is Map && data.containsKey('message')) {
      return data['message'];
    }
    return data;
  }

  String _message(dynamic data) {
    if (data is Map && data['_server_messages'] != null) {
      try {
        final decoded = jsonDecode(data['_server_messages'].toString());
        if (decoded is List && decoded.isNotEmpty) {
          final first = decoded.first;
          final map = first is String ? jsonDecode(first) : first;
          if (map is Map && map['message'] != null) {
            return map['message'].toString();
          }
        }
      } catch (_) {}
    }
    if (data is Map && data['exception'] != null) {
      final text = data['exception'].toString();
      final parts = text.split(':');
      return parts.last.trim();
    }
    return 'Something went wrong. Please try again.';
  }
}
