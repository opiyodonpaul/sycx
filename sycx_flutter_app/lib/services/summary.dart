import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sycx_flutter_app/models/summary.dart';
import 'package:sycx_flutter_app/services/api_client.dart';
import 'package:sycx_flutter_app/utils/secure_storage.dart';

class SummaryService {
  static final ApiClient _apiClient = ApiClient(httpClient: http.Client());

  static Future<Summary> summarizeDocument(
      String userId, dynamic document) async {
    final token = await SecureStorage.getToken();
    final file = await http.MultipartFile.fromPath('document', document.path);
    final response = await _apiClient.post(
      '/summarize',
      headers: {
        'Authorization': 'Bearer $token',
      },
      body: {
        'user_id': userId,
      },
      file: file,
      authRequired: true,
    );

    if (response.statusCode == 200) {
      return Summary.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to summarize document');
  }

  static Future<void> giveFeedback(
      String summaryId, String userId, String feedback) async {
    final token = await SecureStorage.getToken();
    final response = await _apiClient.post(
      '/feedback',
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      },
      body: {'summary_id': summaryId, 'user_id': userId, 'feedback': feedback},
      authRequired: true,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to submit feedback');
    }
  }

  static Future<void> deleteSummary(String summaryId, String userId) async {
    final token = await SecureStorage.getToken();
    final response = await _apiClient.delete(
      '/delete_summary?summary_id=$summaryId&user_id=$userId',
      headers: {'Authorization': 'Bearer $token'},
      authRequired: true,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete summary');
    }
  }

  static Future<String> downloadSummary(String summaryId, String format) async {
    final token = await SecureStorage.getToken();
    final response = await _apiClient.get(
      '/download_summary?summary_id=$summaryId&format=$format',
      headers: {'Authorization': 'Bearer $token'},
      authRequired: true,
    );

    if (response.statusCode == 200) {
      return response.body;
    }
    throw Exception('Failed to download summary');
  }

  static Future<List<Summary>> getUserSummaries(String userId) async {
    final token = await SecureStorage.getToken();
    final response = await _apiClient.get(
      '/user_summaries?user_id=$userId',
      headers: {'Authorization': 'Bearer $token'},
      authRequired: true,
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = jsonDecode(response.body);
      return jsonResponse.map((json) => Summary.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load user summaries');
    }
  }
}
