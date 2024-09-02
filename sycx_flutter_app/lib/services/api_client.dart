import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sycx_flutter_app/utils/constants.dart';
import 'package:sycx_flutter_app/utils/secure_storage.dart';

class ApiClient {
  final http.Client httpClient;

  ApiClient({required this.httpClient});

  Future<http.Response> post(
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
    Future<http.MultipartFile>? file,
    bool authRequired = false,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final defaultHeaders = await _getHeaders(authRequired);
    if (headers != null) {
      defaultHeaders.addAll(headers);
    }

    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(defaultHeaders);

    if (body != null) {
      request.fields['body'] = jsonEncode(body);
    }

    if (file != null) {
      request.files.add(await file);
    }

    final response = await httpClient.send(request);
    final responseBody = await response.stream.bytesToString();

    _handleErrors(response as http.Response);
    return http.Response(responseBody, response.statusCode);
  }

  Future<http.Response> get(
    String endpoint, {
    Map<String, String>? headers,
    bool authRequired = false,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final defaultHeaders = await _getHeaders(authRequired);
    if (headers != null) {
      defaultHeaders.addAll(headers);
    }

    final response = await httpClient.get(
      uri,
      headers: defaultHeaders,
    );

    _handleErrors(response);
    return response;
  }

  Future<http.Response> put(
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
    bool authRequired = false,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final defaultHeaders = await _getHeaders(authRequired);
    if (headers != null) {
      defaultHeaders.addAll(headers);
    }

    final response = await httpClient.put(
      uri,
      headers: defaultHeaders,
      body: jsonEncode(body),
    );

    _handleErrors(response);
    return response;
  }

  Future<http.Response> delete(
    String endpoint, {
    Map<String, String>? headers,
    bool authRequired = false,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final defaultHeaders = await _getHeaders(authRequired);
    if (headers != null) {
      defaultHeaders.addAll(headers);
    }

    final response = await httpClient.delete(
      uri,
      headers: defaultHeaders,
    );

    _handleErrors(response);
    return response;
  }

  Future<Map<String, String>> _getHeaders(bool authRequired) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (authRequired) {
      String? token = await SecureStorage.getToken();
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  void _handleErrors(http.Response response) {
    if (response.statusCode >= 400) {
      throw Exception('Error ${response.statusCode}: ${response.reasonPhrase}');
    }
  }
}
