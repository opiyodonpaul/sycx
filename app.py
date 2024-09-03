from flask import Flask, request, jsonify, send_file
from pymongo import MongoClient
from dotenv import load_dotenv
import os
from summarizer import summarize_document, save_feedback, retrieve_summary, download_summary_file, delete_summary
from model import get_model
from werkzeug.security import generate_password_hash, check_password_hash
from io import BytesIO

# Load environment variables
load_dotenv()

app = Flask(__name__)
app.secret_key = os.getenv('FLASK_SECRET_KEY')

# MongoDB configuration
print("MONGODB_URI:", os.getenv('MONGODB_URI'))
client = MongoClient(os.getenv('MONGODB_URI'))
db = client['sycx']
users_collection = db['users']
summaries_collection = db['summaries']

# Get the summarization model
summarization_model = get_model()

@app.route('/register', methods=['POST'])
def register():
    try:
        if 'profile_pic' not in request.form or not request.form:
            return jsonify({'error': 'Missing profile picture or form data'}), 400

        email = request.form.get('email')
        username = request.form.get('username')
        password = request.form.get('password')
        profile_pic_base64 = request.form.get('profile_pic')

        if not email or not username or not password or not profile_pic_base64:
            return jsonify({'error': 'Missing required fields'}), 400

        # Try to find the user in the database
        try:
            user = users_collection.find_one({'email': email})
        except Exception as e:
            print(f"MongoDB access error: {e}")
            return jsonify({'error': 'Database connection error'}), 500

        if user:
            return jsonify({'error': 'User already exists'}), 400

        hashed_password = generate_password_hash(password)

        result = users_collection.insert_one({
            'username': username,
            'email': email,
            'password': hashed_password,
            'profile_pic': profile_pic_base64
        })

        return jsonify({'message': 'User registered successfully', 'user_id': str(result.inserted_id)})

    except Exception as e:
        print(f"An error occurred: {e}")
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/login', methods=['POST'])
def login():
    data = request.json
    username = data.get('username')
    password = data.get('password')

    if not username or not password:
        return jsonify({'error': 'Missing required fields'}), 400

    user = users_collection.find_one({'username': username})
    if not user or not check_password_hash(user['password'], password):
        return jsonify({'error': 'Invalid username or password'}), 400

    return jsonify({'message': 'Login successful', 'user_id': str(user['_id'])})

@app.route('/reset_password', methods=['POST'])
def reset_password():
    data = request.json
    email = data.get('email')

    if not email:
        return jsonify({'error': 'Missing email'}), 400

    user = users_collection.find_one({'email': email})
    if not user:
        return jsonify({'error': 'User not found'}), 404

    # In a real application, this token should be sent via email
    reset_token = str(uuid.uuid4())
    users_collection.update_one({'_id': user['_id']}, {'$set': {'reset_token': reset_token}})

    return jsonify({'message': 'Password reset token generated', 'reset_token': reset_token})

@app.route('/confirm_reset_password', methods=['POST'])
def confirm_reset_password():
    data = request.json
    reset_token = data.get('token')
    new_password = data.get('new_password')

    user = users_collection.find_one({'reset_token': reset_token})
    if not user:
        return jsonify({'error': 'Invalid or expired token'}), 400

    hashed_password = generate_password_hash(new_password)
    users_collection.update_one({'_id': user['_id']}, {'$set': {'password': hashed_password, 'reset_token': None}})

    return jsonify({'message': 'Password reset successful'})

@app.route('/update_profile', methods=['PUT'])
def update_profile():
    data = request.json
    user_id = data.get('user_id')
    username = data.get('username')
    email = data.get('email')
    profile_pic = data.get('profile_pic')

    if not user_id:
        return jsonify({'error': 'User ID is required'}), 400

    users_collection.update_one(
        {'_id': user_id},
        {'$set': {'username': username, 'email': email, 'profile_pic': profile_pic}}
    )

    return jsonify({'message': 'Profile updated successfully'})

@app.route('/delete_account', methods=['DELETE'])
def delete_account():
    user_id = request.args.get('user_id')
    if not user_id:
        return jsonify({'error': 'User ID is required'}), 400

    summaries_collection.delete_many({'user_id': user_id})
    users_collection.delete_one({'_id': user_id})

    return jsonify({'message': 'Account and all associated data deleted successfully'})

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
