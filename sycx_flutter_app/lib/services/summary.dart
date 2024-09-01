import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sycx_flutter_app/utils/secure_storage.dart';

class Summary {
  static const _baseUrl = 'https://your-api-url.com';

  static Future<Summary?> summarizeDocument(
      String userId, dynamic document) async {
    final token = await SecureStorage.getToken();
    final request = http.MultipartRequest(
        'POST', Uri.parse('$_baseUrl/summarize'))
      ..headers.addAll({'Authorization': 'Bearer $token'})
      ..fields['user_id'] = userId
      ..files.add(await http.MultipartFile.fromPath('document', document.path));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return Summary.fromJson(jsonDecode(responseBody));
    }
    return null;
  }

  static Future<void> giveFeedback(
      String summaryId, String userId, String feedback) async {
    final token = await SecureStorage.getToken();
    await http.post(
      Uri.parse('$_baseUrl/feedback'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      },
      body: jsonEncode(
          {'summary_id': summaryId, 'user_id': userId, 'feedback': feedback}),
    );
  }

  static Future<void> deleteSummary(String summaryId, String userId) async {
    final token = await SecureStorage.getToken();
    await http.delete(
      Uri.parse(
          '$_baseUrl/delete_summary?summary_id=$summaryId&user_id=$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  static Future<String> downloadSummary(String summaryId, String format) async {
    final token = await SecureStorage.getToken();
    final response = await http.get(
      Uri.parse(
          '$_baseUrl/download_summary?summary_id=$summaryId&format=$format'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return response.body;
    }
    throw Exception('Failed to download summary');
  }
}
