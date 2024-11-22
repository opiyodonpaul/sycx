# Flaskie API Testing Guide

## Overview

This testing script provides a comprehensive solution for testing Flask-based REST APIs, allowing you to verify the functionality of your API endpoints both locally and in production environments.

## Prerequisites

- Python 3.8+
- `requests` library
- `base64` library

## Installation

1. Clone the repository:
```bash
git clone <your-repository-url>
cd <repository-directory>
```

2. Install required dependencies:
```bash
pip install requests
```

## Configuration

### Base URL Configuration

You have multiple ways to specify the API base URL:

1. **Command-line Argument**:
```bash
python test_api.py https://sycx.onrender.com
```

2. **Environment Variable**:
```bash
# For Unix/Mac
export API_BASE_URL=https://sycx.onrender.com

# For Windows
set API_BASE_URL=https://sycx.onrender.com

python test_api.py
```

3. **Default Behavior**:
- If no URL is specified, defaults to `http://localhost:5000`

## Features

The testing script supports:

- Health endpoint check
- Document summarization endpoint testing
- Feedback endpoint testing
- Flexible URL configuration
- Dynamic test file generation
- Comprehensive error handling

## Test Files Generation

The script automatically generates test files in the `test_files` directory:
- `sample.txt`: Plain text document
- `sample.json`: JSON file

## Usage

### Basic Usage
```bash
python test_api.py
```

### Testing Specific Endpoints
```bash
# Test local API
python test_api.py http://localhost:5000

# Test deployed API
python test_api.py https://sycx.onrender.com
```

## Expected Output

The script provides detailed console output including:
- API base URL
- Health check status
- Summarization endpoint results
- Feedback endpoint results
- Detailed error messages (if any)

### Sample Output
```
Testing API endpoints at: https://sycx.onrender.com

Health Check:
Status Code: 200
{
    "status": "healthy",
    "service": "document-summarizer",
    ...
}

Summarize Endpoint Test:
Status Code: 200
Summary Metadata:
{
    "execution_time": "1.23 seconds",
    "documents_processed": 2,
    "summaries_generated": 2
}

Feedback Endpoint Test:
Status Code: 200
{
    "status": "success",
    "message": "Feedback received successfully"
}
```

## Customization

### Modifying Test Files
- Edit the `create_test_files()` function to add or modify test files
- Supports various file types (txt, json, etc.)

### Adding More Tests
- Extend the `test_api_endpoints()` function to include additional endpoint tests
- Add custom payload structures as needed

## Troubleshooting

1. **Connection Errors**
   - Ensure the API is running
   - Verify the base URL is correct
   - Check network connectivity

2. **Authentication**
   - If your API requires authentication, modify the script to include:
     - Bearer tokens
     - API keys
     - Additional headers

3. **File Permissions**
   - Ensure script has permissions to create `test_files` directory

## Security Considerations

- Do not use production credentials in test scripts
- Use environment variables for sensitive information
- Limit test data to non-sensitive content

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## License

[Specify your project's license]

---

## Quick Start Checklist

- [x] Install dependencies
- [x] Configure base URL
- [x] Run basic test
- [x] Review output
- [x] Troubleshoot if needed

Happy Testing! 🚀
