import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sycx_flutter_app/models/summary.dart';
import 'package:sycx_flutter_app/services/api_client.dart';
import 'package:sycx_flutter_app/services/database.dart';
import 'package:sycx_flutter_app/utils/secure_storage.dart';

class SummaryService {
  static final ApiClient apiClient = ApiClient(httpClient: http.Client());
  static final Database database = Database();

  static Future<List<Summary>> summarizeDocuments(
      String userId,
      List<Map<String, dynamic>> documents,
      bool mergeSummaries,
      double summaryDepth,
      String language,
      Function(double) updateProgress,
      ) async {
    try {
      final response = await apiClient.post(
        '/summarize',
        body: jsonEncode({
          'user_id': userId,
          'documents': documents,
          'merge_summaries': mergeSummaries,
          'summary_depth': summaryDepth,
          'language': language,
        }),
        headers: {'Content-Type': 'application/json'},
        authRequired: true,
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final summaries = (jsonResponse['summaries'] as List)
            .map((summary) => Summary.fromJson({
          ...summary,
          'userId': userId,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        }))
            .toList();

        // Save the summaries to Firestore
        for (var summary in summaries) {
          await database.createSummary(summary);
        }

        return summaries;
      } else {
        throw Exception('Failed to summarize documents: ${response.body}');
      }
    } catch (e) {
      print('Error in summarizeDocuments: $e');
      rethrow;
    }
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
      body: jsonEncode(
          {'summary_id': summaryId, 'user_id': userId, 'feedback': feedback}),
      authRequired: true,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to submit feedback: ${response.body}');
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
      throw Exception('Failed to delete summary: ${response.body}');
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
    throw Exception('Failed to download summary: ${response.body}');
  }
}
