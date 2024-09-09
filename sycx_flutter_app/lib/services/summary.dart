import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:sycx_flutter_app/dummy_data.dart';
import 'package:sycx_flutter_app/models/summary.dart';
import 'package:sycx_flutter_app/services/api_client.dart';
import 'package:sycx_flutter_app/utils/secure_storage.dart';

class SummaryService {
  static final ApiClient apiClient = ApiClient(httpClient: http.Client());

  static Future<Summary> summarizeDocument(
      String userId, dynamic document, Function(double) updateProgress) async {
    // Simulate summarization process
    final random = Random();
    int totalSteps = 10;
    for (int i = 0; i < totalSteps; i++) {
      await Future.delayed(Duration(milliseconds: 500 + random.nextInt(1000)));
      updateProgress((i + 1) / totalSteps);
    }

    // Return a dummy summary
    final dummySummary =
        DummyData.summaries[random.nextInt(DummyData.summaries.length)];
    return Summary.fromJson(dummySummary);
  }

  static Future<List<Summary>> getSummaries(String userId) async {
    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 1));

    // Return dummy summaries
    return DummyData.summaries.map((json) => Summary.fromJson(json)).toList();
  }

  static Future<void> giveFeedback(
      String summaryId, String userId, String feedback) async {
    final token = await SecureStorage.getToken();
    final response = await apiClient.post(
      '/feedback',
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      },
      body: {'summaryid': summaryId, 'user_id': userId, 'feedback': feedback},
      authRequired: true,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to submit feedback');
    }
  }

  static Future<void> deleteSummary(String summaryId, String userId) async {
    final token = await SecureStorage.getToken();
    final response = await apiClient.delete(
      '/deletesummary?summary_id=$summaryId&user_id=$userId',
      headers: {'Authorization': 'Bearer $token'},
      authRequired: true,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete summary');
    }
  }

  static Future<String> downloadSummary(String summaryId, String format) async {
    final token = await SecureStorage.getToken();
    final response = await apiClient.get(
      '/downloadsummary?summary_id=$summaryId&format=$format',
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
    final response = await apiClient.get(
      '/usersummaries?user_id=$userId',
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
