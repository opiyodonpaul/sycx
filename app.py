from flask import Flask, request, jsonify, send_file
from pymongo import MongoClient
from dotenv import load_dotenv
import os
from summarizer import summarize_document, save_feedback, retrieve_summary, download_summary_file, delete_summary
from model import get_model
import uuid
from io import BytesIO

# Load environment variables
load_dotenv()

app = Flask(__name__)
app.secret_key = os.getenv('FLASK_SECRET_KEY')

# MongoDB configuration
client = MongoClient(os.getenv('MONGODB_URI'))
db = client['sycx']
summaries_collection = db['summaries']

# Get the summarization model
summarization_model = get_model()

@app.route('/summarize', methods=['POST'])
def summarize():
    if 'document' not in request.files:
        return jsonify({'error': 'No document provided'}), 400
    
    document = request.files['document']
    user_id = request.form.get('user_id')

    if not document or not user_id:
        return jsonify({'error': 'No document or user_id provided'}), 400

    summary_id = str(uuid.uuid4())

    try:
        summary = summarize_document(document, summary_id, user_id, summaries_collection, summarization_model)
        return jsonify({'summary': summary, 'summary_id': summary_id})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/feedback', methods=['POST'])
def feedback():
    data = request.json
    summary_id = data.get('summary_id')
    user_id = data.get('user_id')
    feedback_text = data.get('feedback')

    if not summary_id or not user_id or not feedback_text:
        return jsonify({'error': 'Missing feedback information'}), 400

    save_feedback(summary_id, user_id, feedback_text, summaries_collection, summarization_model)

    return jsonify({'message': 'Feedback received and model updated'})

@app.route('/retrieve_summary', methods=['GET'])
def get_summary():
    summary_id = request.args.get('summary_id')
    if not summary_id:
        return jsonify({'error': 'No summary_id provided'}), 400

    summary = retrieve_summary(summary_id, summaries_collection)

    return jsonify({'summary': summary})

@app.route('/delete_summary', methods=['DELETE'])
def remove_summary():
    summary_id = request.args.get('summary_id')
    user_id = request.args.get('user_id')
    if not summary_id or not user_id:
        return jsonify({'error': 'No summary_id or user_id provided'}), 400

    success = delete_summary(summary_id, user_id, summaries_collection)
    if success:
        return jsonify({'message': 'Summary deleted successfully'})
    else:
        return jsonify({'error': 'Summary not found or unauthorized'}), 404

@app.route('/download_summary', methods=['GET'])
def download_summary():
    summary_id = request.args.get('summary_id')
    file_format = request.args.get('format', 'txt')
    if not summary_id:
        return jsonify({'error': 'No summary_id provided'}), 400

    content, mime_type = download_summary_file(summary_id, file_format, summaries_collection)
    
    if content == "Summary not found":
        return jsonify({'error': 'Summary not found'}), 404
    
    if content == "Unsupported format":
        return jsonify({'error': 'Unsupported format'}), 400
    
    buffer = BytesIO(content.encode('utf-8'))
    buffer.seek(0)
    return send_file(buffer, mimetype=mime_type, as_attachment=True, download_name=f'summary.{file_format}')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)