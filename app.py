from flask import Flask, request, jsonify, stream_with_context, Response
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from summarie import enrich_summary_with_visuals, convert_summary_to_pdf, generate_summary
from model import get_model
from dotenv import load_dotenv
import os
import base64
import io
from concurrent.futures import ThreadPoolExecutor, as_completed
import logging
from logging.handlers import RotatingFileHandler  #tport for logging rotation
import json
import traceback
from cachetools import TTLCache, LRUCache
import nltk
import gc
from werkzeug.contrib.fixers import ProxyFix
from functools import lru_cache
import psutil
import resource

# Set resource limits
resource.setrlimit(resource.RLIMIT_AS, (1024 * 1024 * 1024, -1))  # 1GB memory limit

# Download required NLTK data at startup only
nltk_data_path = os.path.join(os.getcwd(), 'nltk_data')
os.makedirs(nltk_data_path, exist_ok=True)
nltk.data.path.append(nltk_data_path)

def download_nltk_data():
    try:
        for package in ['punkt', 'stopwords']:
            if not nltk.data.find(f'tokenizers/{package}'):
                nltk.download(package, download_dir=nltk_data_path, quiet=True)
    except Exception as e:
        logging.warning(f"Failed to download NLTK data: {e}")

download_nltk_data()

load_dotenv()

app = Flask(__name__)
app.wsgi_app = ProxyFix(app.wsgi_app)
app.config['MAX_CONTENT_LENGTH'] = 100 * 1024 * 1024  # Reduce to 100MB max
app.config['UPLOAD_CHUNK_SIZE'] = 4 * 1024 * 1024  # 4MB chunks

# Configure logging with rotation
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.handlers.RotatingFileHandler(
            'app.log', maxBytes=10*1024*1024, backupCount=3
        ),
        logging.StreamHandler()
    ]
)

# Optimize thread pool and cache settings
executor = ThreadPoolExecutor(max_workers=3)  # Reduce workers to prevent memory overload
cache = TTLCache(maxsize=100, ttl=3600)  # Reduce cache size
file_cache = LRUCache(maxsize=50)  # Cache for processed files

# Initialize Limiter with stricter limits
limiter = Limiter(
    app=app,
    key_func=get_remote_address,
    default_limits=["100 per day", "20 per hour"],
    storage_uri="memory://"
)

@lru_cache(maxsize=32)
def get_file_processor(file_type):
    processors = {
        'pdf': ('pdfminer.high_level', 'extract_text'),
        'doc': ('docx', 'Document'),
        'docx': ('docx', 'Document'),
        'xls': ('openpyxl', 'load_workbook'),
        'xlsx': ('openpyxl', 'load_workbook'),
        'ppt': ('pptx', 'Presentation'),
        'pptx': ('pptx', 'Presentation'),
        'png': ('pytesseract', 'image_to_string'),
        'jpg': ('pytesseract', 'image_to_string'),
        'jpeg': ('pytesseract', 'image_to_string')
    }
    return processors.get(file_type)

def check_memory_usage():
    process = psutil.Process(os.getpid())
    memory_usage = process.memory_info().rss / 1024 / 1024  # Convert to MB
    if memory_usage > 900:  # 900MB threshold
        gc.collect()  # Force garbage collection
        raise Exception("Memory usage too high")

def extract_text_from_document(content, file_type):
    try:
        check_memory_usage()
        
        if isinstance(content, str):
            try:
                content = base64.b64decode(content)
            except:
                content = content.encode('utf-8')
        
        # Process in chunks for large files
        chunk_size = app.config['UPLOAD_CHUNK_SIZE']
        if len(content) > chunk_size:
            chunks = [content[i:i + chunk_size] for i in range(0, len(content), chunk_size)]
        else:
            chunks = [content]
            
        text_parts = []
        for chunk in chunks:
            processor = get_file_processor(file_type)
            if processor:
                module_name, function_name = processor
                module = __import__(module_name, fromlist=[function_name])
                processor_func = getattr(module, function_name)
                
                if file_type in ['png', 'jpg', 'jpeg']:
                    from PIL import Image
                    image = Image.open(io.BytesIO(chunk))
                    text_parts.append(processor_func(image))
                else:
                    text_parts.append(processor_func(io.BytesIO(chunk)))
            else:
                text_parts.append(chunk.decode('utf-8', errors='ignore'))
            
            gc.collect()  # Clean up after each chunk
            
        return "\n".join(text_parts)
    except Exception as e:
        logging.error(f"Error extracting text from {file_type} file: {str(e)}")
        logging.error(traceback.format_exc())
        raise Exception(f"Error extracting text from {file_type} file: {str(e)}")

def process_document_chunk(doc):
    try:
        text = extract_text_from_document(doc['content'], doc['type'])
        if text:
            return {
                'name': doc['name'],
                'content': text,
                'type': doc['type']
            }
    except Exception as e:
        logging.error(f"Error processing document {doc['name']}: {str(e)}")
        return None

@app.route('/summarize', methods=['POST'])
@limiter.limit("10 per minute")  # Stricter rate limit
def summarize():
    try:
        data = request.get_json()
        if not data:
            return jsonify({'error': 'No JSON data received'}), 400

        cache_key = json.dumps(data, sort_keys=True)
        cached_result = cache.get(cache_key)
        if cached_result:
            return jsonify(cached_result), 200

        summary_depth = min(float(data.get('summary_depth', 0.3)), 0.5)  # Limit depth
        language = data.get('language', 'en')
        documents_data = data.get('documents', [])

        if not documents_data:
            return jsonify({'error': 'No documents provided'}), 400

        try:
            # Process documents in chunks
            chunk_size = 5  # Process 5 documents at a time
            documents = []
            for i in range(0, len(documents_data), chunk_size):
                chunk = documents_data[i:i + chunk_size]
                futures = []
                with ThreadPoolExecutor(max_workers=3) as executor:
                    futures = [executor.submit(process_document_chunk, doc) for doc in chunk]
                    for future in as_completed(futures):
                        result = future.result()
                        if result:
                            documents.append(result)
                gc.collect()  # Clean up after each chunk

            if not documents:
                return jsonify({'error': 'No valid documents to process'}), 400

            def generate_summaries():
                try:
                    summarization_model = get_model()
                    summary_chunks = generate_summary(
                        summarization_model,
                        documents,
                        summary_depth,
                        language
                    )

                    for summary_chunk in summary_chunks:
                        try:
                            check_memory_usage()
                            enriched_summary = enrich_summary_with_visuals(summary_chunk)
                            pdf_content = convert_summary_to_pdf(enriched_summary['content'])
                            pdf_base64 = base64.b64encode(pdf_content).decode('utf-8')
                            yield json.dumps({
                                'title': enriched_summary['title'],
                                'content': pdf_base64
                            })
                            gc.collect()  # Clean up after each chunk
                        except Exception as e:
                            logging.error(f"Error processing summary chunk: {str(e)}")
                            continue
                finally:
                    gc.collect()  # Final cleanup

            response = Response(stream_with_context(generate_summaries()), 
                             mimetype='application/json')
            cache[cache_key] = response.get_json()
            return response, 200

        except Exception as e:
            logging.error(f"Error processing documents: {str(e)}")
            return jsonify({'error': str(e)}), 500

    except Exception as e:
        logging.error(f"Error in summarize route: {str(e)}")
        logging.error(traceback.format_exc())
        return jsonify({'error': str(e)}), 500

@app.route('/feedback', methods=['POST'])
@limiter.limit("30 per hour")
def feedback():
    data = request.json
    summary_id = data.get('summary_id')
    user_id = data.get('user_id')
    feedback_text = data.get('feedback')

    if not all([summary_id, user_id, feedback_text]):
        return jsonify({'error': 'Missing required data'}), 400

    try:
        # Process feedback asynchronously
        def process_feedback():
            # Here you would typically update the model based on the feedback
            pass
        
        executor.submit(process_feedback)
        return jsonify({'message': 'Feedback received successfully'}), 200
    except Exception as e:
        logging.error(f"Error in feedback route: {str(e)}")
        logging.error(traceback.format_exc())
        return jsonify({'error': str(e)}), 500

@app.errorhandler(500)
def handle_500_error(e):
    gc.collect()  # Force garbage collection on error
    return jsonify({'error': 'Internal server error', 'details': str(e)}), 500

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(
        debug=False,
        host='0.0.0.0',
        port=port,
        threaded=True,
        processes=1  # Limit to single process
    )