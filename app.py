from flask import Flask, request, jsonify, send_file
from pymongo import MongoClient
from dotenv import load_dotenv
import os
from summarizer import summarize_document, save_feedback, retrieve_summary, download_summary_file
import uuid

# Load environment variables
load_dotenv()

app = Flask(__name__)

# MongoDB configuration
client = MongoClient(os.getenv('MONGODB_URI'))
db = client['sycx']
summaries_collection = db['summaries']

@app.route('/summarize', methods=['POST'])
def summarize():
    document = request.files.get('document')
    user_id = request.form.get('user_id')

    if not document or not user_id:
        return jsonify({'error': 'No document or user_id provided'}), 400

    summary_id = str(uuid.uuid4())

    summary = summarize_document(document, summary_id, user_id, summaries_collection)

    return jsonify({'summary': summary, 'summary_id': summary_id})

@app.route('/feedback', methods=['POST'])
def feedback():
    summary_id = request.form.get('summary_id')
    user_id = request.form.get('user_id')
    feedback_text = request.form.get('feedback')

    if not summary_id or not user_id or not feedback_text:
        return jsonify({'error': 'Missing feedback information'}), 400

    save_feedback(summary_id, user_id, feedback_text, summaries_collection)

    return jsonify({'message': 'Feedback received and model updated'})

@app.route('/retrieve_summary', methods=['GET'])
def get_summary():
    summary_id = request.args.get('summary_id')
    if not summary_id:
        return jsonify({'error': 'No summary_id provided'}), 400

    summary = retrieve_summary(summary_id, summaries_collection)

    return jsonify({'summary': summary})

@app.route('/download_summary', methods=['GET'])
def download_summary():
    summary_id = request.args.get('summary_id')
    if not summary_id:
        return jsonify({'error': 'No summary_id provided'}), 400

    file_path = download_summary_file(summary_id, summaries_collection)
    return send_file(file_path, as_attachment=True)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
