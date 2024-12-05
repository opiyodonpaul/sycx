import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:sycx_flutter_app/services/api_client.dart';
import 'package:sycx_flutter_app/services/database.dart';
import 'package:sycx_flutter_app/utils/constants.dart';
import 'package:sycx_flutter_app/utils/secure_storage.dart';
import 'package:sycx_flutter_app/models/summary.dart';

class SummaryService {
  static final ApiClient apiClient =
      ApiClient(httpClient: http.Client(), baseUrl: Constants.baseUrl);
  static final Database database = Database();

  /// Handles document summarization with support for large file uploads
  /// Supports file sizes up to 1.1GB
  static Future<List<Summary>> summarizeDocuments({
    required List<File> files,
    required double summaryDepth,
    required String language,
    required String userId,
  }) async {
    try {
      // Prepare multipart request with file upload
      final request = http.MultipartRequest(
          'POST', Uri.parse('${Constants.baseUrl}/summarize'));

      // Add fields to the request
      request.fields.addAll({
        'summary_depth': summaryDepth.toString(),
        'language': language,
        'user_id': userId,
      });

      // Add files to the request
      List<OriginalDocument> originalDocuments = [];
      for (var file in files) {
        // Read file content and convert to base64
        String fileContent = base64Encode(await file.readAsBytes());

        // Create OriginalDocument with file details
        originalDocuments.add(OriginalDocument(
            title: path.basename(file.path),
            content: fileContent,
            type: path.extension(file.path).replaceFirst('.', '')));

        // Add file to the multipart request
        request.files.add(await http.MultipartFile.fromPath(
            path.basename(file.path), file.path));
      }

      // Send the request using a stream
      final streamedResponse = await request.send();

// Handle response
      if (streamedResponse.statusCode == 200) {
// Read response body
        final responseBody = await streamedResponse.stream.bytesToString();
        final Map<String, dynamic> responseJson = json.decode(responseBody);

// Check for successful status
        if (responseJson['status'] != 'success') {
          throw Exception('Summarization failed: ${responseJson['message']}');
        }

// Create summaries list to store
        List<Summary> summaries = [];

// Process each summary in the response
        for (var summaryData in responseJson['summaries']) {
// Create summary object
          final summary = Summary(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            userId: userId,
            originalDocuments: originalDocuments,
// Store the summary content as-is, without encoding/decoding
            summaryContent: summaryData['content'],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

// Save summary to database
          await database.createSummary(summary);
          summaries.add(summary);
        }

        return summaries;
      } else {
// Handle error response
        final errorBody = await streamedResponse.stream.bytesToString();
        throw Exception('Failed to summarize documents: $errorBody');
      }
    } catch (e) {
      print('Error in summarizeDocuments: $e');
      rethrow;
    }
  }

  // Existing feedback method remains the same
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
}
