import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sycx_flutter_app/utils/constants.dart';

class Unsplash {
  static const String _baseUrl = 'https://api.unsplash.com';

  /// Retrieve a random image URL based on the query
  ///
  /// @param query Search query for image retrieval
  /// @return Nullable image URL string
  static Future<String?> getRandomImageUrl(String query) async {
    try {
      // Sanitize the query by removing special characters and trimming
      final sanitizedQuery = query
          .replaceAll(RegExp(r'[^\w\s]'), '')
          .trim()
          .substring(0, query.length > 50 ? 50 : query.length);

      final response = await http.get(
        Uri.parse(
            '$_baseUrl/photos/random?query=${Uri.encodeComponent(sanitizedQuery)}&orientation=landscape'
        ),
        headers: {'Authorization': 'Client-ID ${Constants.accessKey}'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['urls']['regular'];
      }
    } catch (e) {
      print('Error fetching Unsplash image: $e');
    }
    return null;
  }
}
