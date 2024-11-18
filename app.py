from flask import Flask, request, jsonify
from dotenv import load_dotenv
import os
import base64
import io
from concurrent.futures import ThreadPoolExecutor
import logging
from logging.handlers import RotatingFileHandler
import json
import traceback
import gc
import time

# Create Flask application factory
def create_app():
    # Create logs directory if it doesn't exist
    os.makedirs('logs', exist_ok=True)

    # Configure logging
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - [%(filename)s:%(lineno)d] - %(message)s',
        handlers=[
            RotatingFileHandler(
                'logs/app.log',
                maxBytes=1024*1024,
                backupCount=3
            ),
            logging.StreamHandler()
        ]
    )

    app = Flask(__name__)
    app.config['MAX_CONTENT_LENGTH'] = 1024 * 1024 * 1024  # 1GB max-limit

    # Initialize resources
    executor = ThreadPoolExecutor(max_workers=10)
    from model import get_model
    summarization_model = get_model()

    def cleanup_resources():
        """Clean up resources and force garbage collection"""
        gc.collect()

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
        finally:
            cleanup_resources()

    @app.route('/summarize', methods=['POST'])
    def summarize():
        start_time = time.time()
        try:
            data = request.get_json()
            if not data:
                return jsonify({'error': 'No JSON data received'}), 400

            merge_summaries = data.get('merge_summaries', False)
            summary_depth = float(data.get('summary_depth', 0.3))
            language = data.get('language', 'en')
            documents_data = data.get('documents', [])

            if not documents_data:
                return jsonify({'error': 'No documents provided'}), 400

            documents = []
            try:
                for doc in documents_data:
                    text = extract_text_from_document(doc['content'], doc['type'])
                    documents.append({
                        'name': doc['name'],
                        'content': text,
                        'type': doc['type']
                    })
            except Exception as e:
                logging.error(f"Error processing documents: {str(e)}")
                logging.error(traceback.format_exc())
                return jsonify({'error': f"Error processing documents: {str(e)}"}), 400

            # Generate summaries
            try:
                from summarie import generate_summary, enrich_summary_with_visuals, convert_summary_to_pdf
                
                summaries = generate_summary(
                    summarization_model,
                    documents,
                    summary_depth,
                    language
                )
                
                # Enrich summaries with visuals
                enriched_summaries = []
                for summary in summaries:
                    try:
                        enriched_summary = enrich_summary_with_visuals(summary)
                        enriched_summaries.append(enriched_summary)
                    except Exception as e:
                        logging.error(f"Error enriching summary: {str(e)}")
                        enriched_summaries.append(summary)
                    finally:
                        cleanup_resources()
                
                # Convert to PDF
                pdf_summaries = []
                for summary in enriched_summaries:
                    try:
                        pdf_content = convert_summary_to_pdf(summary['content'])
                        pdf_base64 = base64.b64encode(pdf_content).decode('utf-8')
                        pdf_summaries.append({
                            'title': summary['title'],
                            'content': pdf_base64,
                            'original_content': summary['content']
                        })
                    except Exception as e:
                        logging.error(f"Error converting to PDF: {str(e)}")
                        pdf_summaries.append({
                            'title': summary['title'],
                            'content': summary['content'],
                            'error': 'PDF conversion failed'
                        })
                    finally:
                        cleanup_resources()

                execution_time = time.time() - start_time
                return jsonify({
                    'status': 'success',
                    'summaries': pdf_summaries,
                    'metadata': {
                        'execution_time': f"{execution_time:.2f} seconds",
                        'documents_processed': len(documents),
                        'summaries_generated': len(pdf_summaries)
                    }
                }), 200

            except Exception as e:
                logging.error(f"Error in summary generation: {str(e)}")
                logging.error(traceback.format_exc())
                return jsonify({'error': str(e)}), 500

        except Exception as e:
            logging.error(f"Error in summarize route: {str(e)}")
            logging.error(traceback.format_exc())
            return jsonify({'error': str(e)}), 500
        finally:
            cleanup_resources()

    @app.route('/feedback', methods=['POST'])
    def feedback():
        try:
            data = request.json
            required_fields = ['summary_id', 'user_id', 'feedback', 'summary_content']
            
            if not all(field in data for field in required_fields):
                return jsonify({'error': 'Missing required fields'}), 400

            feedback_data = {
                'summary_id': data['summary_id'],
                'user_id': data['user_id'],
                'feedback': data['feedback'],
                'summary_content': data['summary_content'],
                'timestamp': time.strftime('%Y-%m-%d %H:%M:%S')
            }

            logging.info(f"Feedback received: {json.dumps(feedback_data, indent=2)}")

            return jsonify({
                'status': 'success',
                'message': 'Feedback received successfully',
                'feedback_id': hash(str(feedback_data))
            }), 200

        except Exception as e:
            logging.error(f"Error in feedback route: {str(e)}")
            logging.error(traceback.format_exc())
            return jsonify({'error': str(e)}), 500

    @app.route('/health', methods=['GET'])
    def health_check():
        try:
            model_status = 'healthy' if summarization_model else 'unavailable'
            
            return jsonify({
                'status': 'healthy',
                'service': 'document-summarizer',
                'version': os.environ.get('APP_VERSION', '1.0.0'),
                'model_status': model_status,
                'timestamp': time.strftime('%Y-%m-%d %H:%M:%S')
            }), 200
        except Exception as e:
            logging.error(f"Error in health check: {str(e)}")
            return jsonify({
                'status': 'unhealthy',
                'error': str(e)
            }), 500

    return app

# Create the application instance
app = create_app()

if __name__ == '__main__':
    # Load environment variables
    load_dotenv()
    
    # Run the application
    app.run(
        debug=False,
        host='0.0.0.0',
        port=int(os.environ.get('PORT', 5000)),
        threaded=True
    )