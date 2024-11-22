import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sycx_flutter_app/utils/constants.dart';

class Unsplash {
  static const String _baseUrl = 'https://api.unsplash.com';

  static Future<String?> getRandomImageUrl(String query) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/photos/random?query=${Uri.encodeComponent(query)}&orientation=landscape'),
        headers: {'Authorization': 'Client-ID $accessKey'},
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