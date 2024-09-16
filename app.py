from flask import Flask, request, jsonify
from pymongo import MongoClient
from dotenv import load_dotenv
import os
from summarizer import summarize_document
from model import get_model
import uuid

# Load environment variables
load_dotenv()

app = Flask(__name__)
app.secret_key = os.getenv('FLASK_SECRET_KEY')

# MongoDB configuration
client = MongoClient(os.getenv('MONGODB_URI'))
db = client['sycx']
users_collection = db['users']
summaries_collection = db['summaries']

# Get the summarization model
summarization_model = get_model()

@app.route('/summarize', methods=['POST'])
def summarize():
    if 'document' not in request.files:
        return jsonify({'error': 'No document provided'}), 400
    
    document = request.files['document']
    data = request.form.to_dict()
    user_id = data.get('user_id')

    if not document or not user_id:
        return jsonify({'error': 'No document or user_id provided'}), 400

    summary_id = str(uuid.uuid4())

    try:
        summary = summarize_document(document, summary_id, user_id, summaries_collection, summarization_model)
        return jsonify({'summary': summary, 'summary_id': summary_id})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)