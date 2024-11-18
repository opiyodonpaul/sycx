import requests
import base64
import os
import json
from pathlib import Path

def create_test_files():
    """Create sample test files in different formats"""
    # Create test directory structure
    test_dir = Path("test_files")
    test_dir.mkdir(exist_ok=True)
    
    # Create a sample text file
    text_content = """This is a sample document for testing.
It contains multiple lines of text.
The API should process this correctly."""
    
    with open(test_dir / "sample.txt", "w") as f:
        f.write(text_content)
    
    # Create a sample JSON file
    json_content = {
        "title": "Test JSON",
        "description": "This is a test JSON file",
        "items": ["item1", "item2", "item3"]
    }
    
    with open(test_dir / "sample.json", "w") as f:
        json.dump(json_content, f, indent=2)

def encode_file(file_path):
    """Encode file content to base64"""
    with open(file_path, "rb") as f:
        return base64.b64encode(f.read()).decode('utf-8')

def test_summarize_endpoint():
    """Test the /summarize endpoint with sample files"""
    base_url = "http://localhost:5000"  # Change this if your API is hosted elsewhere
    
    # Prepare test files
    create_test_files()
    
    # Prepare the request payload
    files = []
    test_dir = Path("test_files")
    
    for file_path in test_dir.glob("*"):
        file_type = file_path.suffix.lstrip('.')
        if file_type == '':
            file_type = 'txt'
            
        files.append({
            "name": file_path.name,
            "type": file_type,
            "content": encode_file(file_path)
        })
    
    payload = {
        "documents": files,
        "merge_summaries": False,
        "summary_depth": 0.3,
        "language": "en"
    }
    
    # Make the request
    try:
        response = requests.post(
            f"{base_url}/summarize",
            json=payload,
            headers={"Content-Type": "application/json"}
        )
        
        print(f"Status Code: {response.status_code}")
        print("Response:")
        print(json.dumps(response.json(), indent=2))
        
    except Exception as e:
        print(f"Error testing API: {str(e)}")

def test_health_endpoint():
    """Test the /health endpoint"""
    base_url = "http://localhost:5000"
    
    try:
        response = requests.get(f"{base_url}/health")
        print("\nHealth Check:")
        print(f"Status Code: {response.status_code}")
        print("Response:")
        print(json.dumps(response.json(), indent=2))
        
    except Exception as e:
        print(f"Error testing health endpoint: {str(e)}")

if __name__ == "__main__":
    print("Testing API endpoints...")
    test_health_endpoint()
    print("\nTesting summarize endpoint...")
    test_summarize_endpoint()
