import 'dart:convert';
import 'dart:io';

Future<String> convertFileToBase64(File file) async {
  final bytes = await file.readAsBytes();
  return base64Encode(bytes);
}
