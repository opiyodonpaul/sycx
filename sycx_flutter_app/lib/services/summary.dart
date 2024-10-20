import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sycx_flutter_app/services/api_client.dart';
import 'package:sycx_flutter_app/services/database.dart';
import 'package:sycx_flutter_app/utils/secure_storage.dart';

class SummaryService {
  static final ApiClient apiClient = ApiClient(httpClient: http.Client());
  static final Database database = Database();

  static Future<List<Map<String, dynamic>>> summarizeDocuments(
    List<Map<String, dynamic>> documents,
    bool mergeSummaries,
    double summaryDepth,
    String language,
    Function(double) updateProgress,
  ) async {
    try {
      final url = apiClient.buildUri('/summarize');

      // Prepare the JSON payload
      final payload = {
        'merge_summaries': mergeSummaries,
        'summary_depth': summaryDepth,
        'language': language,
        'documents': documents,
      };

      // Set up headers for large JSON payload
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      // Send the request with a timeout of 5 minutes
      final response = await http
          .post(
            url,
            headers: headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(minutes: 5));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        // Process and decode any base64 encoded data in the response
        final summaries =
            List<Map<String, dynamic>>.from(jsonResponse['summaries'])
                .map((summary) {
          if (summary.containsKey('visuals')) {
            summary['visuals'] =
                List<Map<String, dynamic>>.from(summary['visuals'])
                    .map((visual) {
              if (visual.containsKey('data') && visual['data'] is String) {
                // Decode base64 data back to bytes
                visual['data'] = base64Decode(visual['data']);
              }
              return visual;
            }).toList();
          }
          return summary;
        }).toList();

        return summaries;
      } else {
        throw Exception(
            'Failed to summarize documents: ${response.statusCode}\n${response.body}');
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
