from flask import Flask, request, jsonify, stream_with_context, Response
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from summarie import enrich_summary_with_visuals, convert_summary_to_pdf, generate_summary
from model import get_model
from python_dotenv import load_dotenv
import os
import base64
import io
from concurrent.futures import ThreadPoolExecutor, as_completed
import logging
import json
import traceback
from cachetools import TTLCache
import nltk

# Download required NLTK data
try:
    nltk.download('punkt', quiet=True)
    nltk.download('stopwords', quiet=True)
except Exception as e:
    logging.warning(f"Failed to download NLTK data: {e}")

load_dotenv()

app = Flask(__name__)
app.config['MAX_CONTENT_LENGTH'] = 1024 * 1024 * 1024
summarization_model = get_model()

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

executor = ThreadPoolExecutor(max_workers=10)
cache = TTLCache(maxsize=1000, ttl=3600)  # Cache summaries for 1 hour

# Initialize Limiter correctly
limiter = Limiter(
    app=app,
    key_func=get_remote_address,
    default_limits=["150 per day", "30 per hour"]
)

def extract_text_from_document(content, file_type):
    try:
        if isinstance(content, str):
            try:
                content = base64.b64decode(content)
            except:
                content = content.encode('utf-8')
        
        if file_type == 'pdf':
            from pdfminer.high_level import extract_text
            return extract_text(io.BytesIO(content))
        elif file_type in ['doc', 'docx']:
            from docx import Document
            doc = Document(io.BytesIO(content))
            return "\n".join([para.text for para in doc.paragraphs])
        elif file_type in ['xls', 'xlsx']:
            from openpyxl import load_workbook
            wb = load_workbook(io.BytesIO(content))
            text = ""
            for sheet in wb:
                for row in sheet.iter_rows(values_only=True):
                    text += " | ".join([str(cell) for cell in row if cell]) + "\n"
            return text
        elif file_type in ['ppt', 'pptx']:
            from pptx import Presentation
            prs = Presentation(io.BytesIO(content))
            text = ""
            for slide in prs.slides:
                for shape in slide.shapes:
                    if hasattr(shape, 'text'):
                        text += shape.text + "\n"
            return text
        elif file_type in ['png', 'jpg', 'jpeg']:
            import pytesseract
            from PIL import Image
            image = Image.open(io.BytesIO(content))
            return pytesseract.image_to_string(image)
        else:
            return content.decode('utf-8', errors='ignore')
    except Exception as e:
        logging.error(f"Error extracting text from {file_type} file: {str(e)}")
        logging.error(traceback.format_exc())
        raise Exception(f"Error extracting text from {file_type} file: {str(e)}")

@app.route('/summarize', methods=['POST'])
@limiter.limit("20 per minute")
def summarize():
    try:
        data = request.get_json()
        if not data:
            return jsonify({'error': 'No JSON data received'}), 400

        cache_key = json.dumps(data, sort_keys=True)
        cached_result = cache.get(cache_key)
        if cached_result:
            return jsonify(cached_result), 200

        summary_depth = float(data.get('summary_depth', 0.3))
        language = data.get('language', 'en')
        documents_data = data.get('documents', [])

        if not documents_data:
            return jsonify({'error': 'No documents provided'}), 400

        try:
            documents = []
            for doc in documents_data:
                try:
                    text = extract_text_from_document(doc['content'], doc['type'])
                    if text:
                        documents.append({
                            'name': doc['name'],
                            'content': text,
                            'type': doc['type']
                        })
                except Exception as e:
                    logging.error(f"Error processing document {doc['name']}: {str(e)}")
                    continue

            if not documents:
                return jsonify({'error': 'No valid documents to process'}), 400

            summarization_model = get_model()
            summary_chunks = generate_summary(
                summarization_model,
                documents,
                summary_depth,
                language
            )

            def generate_summaries():
                for summary_chunk in summary_chunks:
                    try:
                        enriched_summary = enrich_summary_with_visuals(summary_chunk)
                        pdf_content = convert_summary_to_pdf(enriched_summary['content'])
                        pdf_base64 = base64.b64encode(pdf_content).decode('utf-8')
                        yield json.dumps({
                            'title': enriched_summary['title'],
                            'content': pdf_base64
                        })
                    except Exception as e:
                        logging.error(f"Error processing summary chunk: {str(e)}")

            response = Response(stream_with_context(generate_summaries()), mimetype='application/json')
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
def feedback():
    data = request.json
    summary_id = data.get('summary_id')
    user_id = data.get('user_id')
    feedback_text = data.get('feedback')

    if not all([summary_id, user_id, feedback_text]):
        return jsonify({'error': 'Missing required data'}), 400

    try:
        # Here you would typically update the model based on the feedback
        return jsonify({'message': 'Feedback received successfully'}), 200
    except Exception as e:
        logging.error(f"Error in feedback route: {str(e)}")
        logging.error(traceback.format_exc())
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(debug=False, host='0.0.0.0', port=int(os.environ.get('PORT', 5000)))