# SycX API Documentation

This document provides detailed information about the SycX API endpoints, request/response formats, and usage examples.

## Base URL

All API requests should be made to:

```
https://sycx-production.up.railway.app/
```

## Endpoints

### 1. Upload Document

Upload a document for summarization.

- **URL**: `/upload`
- **Method**: POST
- **Content-Type**: multipart/form-data

#### Request Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| file | File | The document file to be summarized (PDF, DOCX, TXT, JPG, JPEG, PNG) |
| language | String | (Optional) The language of the document. Default is 'en' for English |

#### Response

```json
{
  "document_id": "abc123",
  "status": "processing",
  "estimated_time": 60
}
```

### 2. Get Summary

Retrieve the summary of an uploaded document.

- **URL**: `/summary/{document_id}`
- **Method**: GET

#### Response

```json
{
  "document_id": "abc123",
  "summary": "This is a concise summary of the uploaded document...",
  "visual_aids": [
    {
      "type": "chart",
      "data": "..."
    },
    {
      "type": "diagram",
      "data": "..."
    }
  ]
}
```

### 3. Submit Feedback

Submit feedback on a generated summary.

- **URL**: `/feedback`
- **Method**: POST
- **Content-Type**: application/json

#### Request Body

```json
{
  "document_id": "abc123",
  "rating": 4,
  "comments": "The summary was helpful, but could use more detail in section 2."
}
```

#### Response

```json
{
  "status": "success",
  "message": "Feedback submitted successfully"
}
```

## Error Handling

The API uses standard HTTP response codes to indicate the success or failure of requests. In case of an error, the response body will contain more details about the error.

Example error response:

```json
{
  "error": {
    "code": "invalid_file_type",
    "message": "The uploaded file type is not supported. Please upload PDF, DOCX, or TXT files."
  }
}
```

## Changelog

- v1.0.0 (2024-03-01): Initial release of the API
- v1.1.0 (2024-06-15): Added support for visual aids in summaries

For any questions or issues, please contact our support team at api-support@sycx.com.
