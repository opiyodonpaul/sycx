# Flaskie API Documentation

A powerful Flask REST API with advanced text processing, document handling, and image analysis capabilities.

## Table of Contents
1. [Authentication](#authentication)
   - [Register User](#register-user)
   - [Login User](#login-user)
   - [Get User Profile](#get-user-profile)
2. [Document Processing](#document-processing)
   - [Analyze Document](#analyze-document)
   - [Get Document](#get-document)
3. [Text Analysis](#text-analysis)
   - [Analyze Sentiment](#analyze-sentiment)
   - [Generate Summary](#generate-summary)
   - [Extract Keywords](#extract-keywords)
4. [Image Analysis](#image-analysis)
   - [Extract Text from Image](#extract-text-from-image)
   - [Generate Word Cloud](#generate-word-cloud)
   - [Analyze Image](#analyze-image)
5. [Error Handling](#error-handling)
6. [Best Practices](#best-practices)
7. [Flutter Integration](#flutter-integration)
8. [Deployment to Railway.com](#deployment-to-railwaycom)

## Authentication

### Register User
**Endpoint**: `POST /api/v1/auth/register`
**Request Body**:
```json
{
  "username": "testuser",
  "password": "testpass123"
}
```
**Response**:
```json
{
  "status": "success",
  "message": "User registered successfully",
  "timestamp": "2023-08-08T12:34:56.789Z"
}
```

### Login User
**Endpoint**: `POST /api/v1/auth/login`
**Request Body**:
```json
{
  "username": "testuser",
  "password": "testpass123"
}
```
**Response**:
```json
{
  "status": "success",
  "message": "Success",
  "timestamp": "2023-08-08T12:34:56.789Z",
  "data": {
    "access_token": "your_access_token",
    "token_type": "bearer"
  }
}
```

### Get User Profile
**Endpoint**: `GET /api/v1/auth/me`
**Headers**:
- `Authorization: Bearer your_access_token`
**Response**:
```json
{
  "status": "success",
  "message": "Success",
  "timestamp": "2023-08-08T12:34:56.789Z",
  "data": {
    "username": "testuser"
  }
}
```

## Document Processing

### Analyze Document
**Endpoint**: `POST /api/v1/documents/analyze`
**Headers**:
- `Authorization: Bearer your_access_token`
**Request Body**:
- `file`: The document file to be analyzed (PDF, DOCX, XLSX, PPTX)
**Response**:
```json
{
  "status": "success",
  "message": "Success",
  "timestamp": "2023-08-08T12:34:56.789Z",
  "data": {
    "type": "pdf",
    "content": "The text content of the document...",
    "pages": 10,
    "word_count": 5000
  }
}
```

### Get Document
**Endpoint**: `GET /api/v1/documents/{doc_id}`
**Headers**:
- `Authorization: Bearer your_access_token`
**Response**:
```json
{
  "status": "success",
  "message": "Success",
  "timestamp": "2023-08-08T12:34:56.789Z",
  "data": {
    "id": "document_1",
    "name": "Document_1",
    "type": "pdf",
    "created_at": "2024-03-20T10:00:00Z",
    "status": "processed"
  }
}
```

## Text Analysis

### Analyze Sentiment
**Endpoint**: `POST /api/v1/analysis/sentiment`
**Headers**:
- `Authorization: Bearer your_access_token`
**Request Body**:
```json
{
  "text": "This is a great API service! I love using it."
}
```
**Response**:
```json
{
  "status": "success",
  "message": "Success",
  "timestamp": "2023-08-08T12:34:56.789Z",
  "data": {
    "sentiment": "positive",
    "confidence": 0.9234
  }
}
```

### Generate Summary
**Endpoint**: `POST /api/v1/analysis/summary`
**Headers**:
- `Authorization: Bearer your_access_token`
**Request Body**:
```json
{
  "text": "This is a long text that needs to be summarized. It contains many details and information that should be condensed into a shorter version."
}
```
**Response**:
```json
{
  "status": "success",
  "message": "Success",
  "timestamp": "2023-08-08T12:34:56.789Z",
  "data": {
    "summary": "This text contains many details that should be condensed into a shorter version.",
    "original_length": 50,
    "summary_length": 15
  }
}
```

### Extract Keywords
**Endpoint**: `POST /api/v1/analysis/keywords`
**Headers**:
- `Authorization: Bearer your_access_token`
**Request Body**:
```json
{
  "text": "This is a sample text with multiple keywords that should be extracted."
}
```
**Response**:
```json
{
  "status": "success",
  "message": "Success",
  "timestamp": "2023-08-08T12:34:56.789Z",
  "data": {
    "keywords": [
      {
        "word": "sample",
        "count": 1
      },
      {
        "word": "text",
        "count": 1
      },
      {
        "word": "keywords",
        "count": 1
      },
      {
        "word": "extracted",
        "count": 1
      }
    ]
  }
}
```

## Image Analysis

### Extract Text from Image
**Endpoint**: `POST /api/v1/analysis/image/text-extract`
**Headers**:
- `Authorization: Bearer your_access_token`
**Request Body**:
- `file`: The image file containing text to be extracted (PNG, JPEG)
**Response**:
```json
{
  "status": "success",
  "message": "Success",
  "timestamp": "2023-08-08T12:34:56.789Z",
  "data": {
    "text": "This is the text extracted from the image.",
    "word_count": 10,
    "language": "en"
  }
}
```

### Generate Word Cloud
**Endpoint**: `POST /api/v1/analysis/image/word-cloud`
**Headers**:
- `Authorization: Bearer your_access_token`
**Request Body**:
- `text`: The text to be used for generating the word cloud
**Response**:
```json
{
  "status": "success",
  "message": "Success",
  "timestamp": "2023-08-08T12:34:56.789Z",
  "data": {
    "image": "base64_encoded_image_data",
    "format": "PNG",
    "word_count": 50
  }
}
```

### Analyze Image
**Endpoint**: `POST /api/v1/analysis/image/analyze`
**Headers**:
- `Authorization: Bearer your_access_token`
**Request Body**:
- `file`: The image file to be analyzed (PNG, JPEG)
**Response**:
```json
{
  "status": "success",
  "message": "Success",
  "timestamp": "2023-08-08T12:34:56.789Z",
  "data": {
    "format": "PNG",
    "mode": "RGB",
    "size": [800, 600],
    "info": {}
  }
}
```

## Error Handling

The API handles various types of errors and returns appropriate HTTP status codes and error messages. Some examples:

- **400 Bad Request**: Missing required parameters, invalid input
- **401 Unauthorized**: Invalid authentication credentials
- **403 Forbidden**: Insufficient permissions
- **404 Not Found**: Requested resource not found
- **429 Too Many Requests**: Rate limit exceeded
- **500 Internal Server Error**: General server-side error

## Best Practices

1. **Security**:
   - Use HTTPS in production
   - Implement rate limiting
   - Validate all input data
   - Use secure headers
   - Implement proper authentication

2. **Performance**:
   - Implement caching
   - Use async operations where possible
   - Optimize database queries
   - Implement pagination

3. **Code Organization**:
   - Follow modular architecture
   - Use blueprints for routes
   - Implement service layer
   - Use dependency injection

4. **Error Handling**:
   - Use proper HTTP status codes
   - Return meaningful error messages
   - Log errors appropriately
   - Implement global error handling

5. **Documentation**:
   - Document all endpoints
   - Provide example requests/responses
   - Include setup instructions
   - Document environment variables

## Flutter Integration

Here's a sample API service class for integrating the Flaskie API into a Flutter app:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  static const String baseUrl = 'YOUR_RAILWAY_APP_URL';
  String? _accessToken;

  Future<String> _getAccessToken() async {
    // Implement logic to get access token
  }

  Future<Map<String, dynamic>> analyzeSentiment(String text) async {
    // Implement logic to analyze sentiment
  }

  Future<Map<String, dynamic>> analyzeDocument(List<int> fileBytes, String filename) async {
    // Implement logic to analyze document
  }
}
```

## Deployment to Railway.com

To deploy your Flask API to Railway.com, follow these steps:

1. Create a new project on Railway.com
2. Connect your GitHub repository
3. Set the following environment variables in the Railway dashboard:
   - `FLASK_APP=wsgi.py`
   - `FLASK_ENV=production`
   - `SECRET_KEY=[your-secure-secret-key]`
   - `JWT_SECRET_KEY=[your-secure-jwt-key]`
   - `RATE_LIMIT=100/hour`
4. Deploy using Git:
```bash
git add .
git commit -m "Initial commit"
git push railway main
```

Your Flask API will now be deployed and accessible at the Railway.com URL.

