import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sycx_flutter_app/services/api_client.dart';
import 'package:sycx_flutter_app/services/database.dart';
import 'package:sycx_flutter_app/utils/secure_storage.dart';
import 'package:sycx_flutter_app/models/summary.dart';

class SummaryService {
  static final ApiClient apiClient = ApiClient(httpClient: http.Client());
  static final Database database = Database();

  static Future<List<Summary>> summarizeDocuments(
    List<Map<String, dynamic>> documents,
    double summaryDepth,
    String language,
    String userId,
  ) async {
    try {
      final url = apiClient.buildUri('/summarize');

      // Prepare the JSON payload
      final payload = {
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

        if (jsonResponse['status'] != 'success') {
          throw Exception('API returned unsuccessful status');
        }

        // Process and decode any base64 encoded data in the response
        final summaries = (jsonResponse['summaries'] as List).map((summary) {
          // Create original documents list
          final originalDocuments = documents
              .map((doc) => OriginalDocument(
                    title: doc['name'],
                    content: doc['content'],
                  ))
              .toList();

          String summaryContent;
          // Check if the content is base64 encoded PDF or plain text
          if (summary['content'] != null &&
              summary['content'].startsWith('JVBERi')) {
            // It's a base64 encoded PDF, store as is
            summaryContent = summary['content'];
          } else {
            // Use original_content if available, otherwise use content
            summaryContent =
                summary['original_content'] ?? summary['content'] ?? '';
          }

          final newSummary = Summary(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            userId: userId,
            originalDocuments: originalDocuments,
            summaryContent: summaryContent,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          // Save each summary to Firebase
          database.createSummary(newSummary).catchError((error) {
            print('Error saving summary to database: $error');
          });

          return newSummary;
        }).toList();

        return summaries;
      } else {
        final errorMessage = _parseErrorResponse(response);
        throw Exception('Failed to summarize documents: $errorMessage');
      }
    } catch (e) {
      print('Error in summarizeDocuments: $e');
      rethrow;
    }
  }

  static String _parseErrorResponse(http.Response response) {
    try {
      final bodyJson = jsonDecode(response.body);
      return bodyJson['error'] ?? response.body;
    } catch (_) {
      return '${response.statusCode}\n${response.body}';
    }
  }

  static Future<void> giveFeedback(
    String summaryId,
    String userId,
    String feedback,
    String summaryContent,
  ) async {
    final token = await SecureStorage.getToken();
    final response = await apiClient.post(
      '/feedback',
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      },
      body: jsonEncode({
        'summary_id': summaryId,
        'user_id': userId,
        'feedback': feedback,
        'summary_content': summaryContent,
      }),
      authRequired: true,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to submit feedback: ${response.body}');
    }
  }

  static Future<void> deleteSummary(String summaryId, String userId) async {
    final token = await SecureStorage.getToken();

    // First delete from Firebase
    await database.deleteSummary(summaryId);

    // Then delete from backend if needed
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
