from flask import Flask, request, jsonify, send_file
from pymongo import MongoClient
from dotenv import load_dotenv
import os
from summarizer import summarize_document, save_feedback, retrieve_summary, download_summary_file, delete_summary
from model import get_model
from werkzeug.security import generate_password_hash, check_password_hash
from io import BytesIO
import uuid
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from flask_cors import CORS
from datetime import datetime, timedelta

# Load environment variables
load_dotenv()

app = Flask(__name__)
CORS(app, resources={r"/*": {"origins": "https://sycx.vercel.app"}}, supports_credentials=True)
app.secret_key = os.getenv('FLASK_SECRET_KEY')

# MongoDB configuration
client = MongoClient(os.getenv('MONGODB_URI'))
db = client['sycx']
users_collection = db['users']
summaries_collection = db['summaries']

# Get the summarization model
summarization_model = get_model()

# Email configuration
SMTP_SERVER = "smtp.gmail.com"
SMTP_PORT = 587
SMTP_USERNAME = os.getenv('SMTP_USERNAME')
SMTP_PASSWORD = os.getenv('SMTP_PASSWORD')
SENDER_EMAIL = os.getenv('SENDER_EMAIL')

# Set password reset token expiration time (in hours)
TOKEN_EXPIRATION_HOURS = 1

def send_reset_email(email, reset_token, expiration_time):
    msg = MIMEMultipart()
    msg['From'] = SENDER_EMAIL
    msg['To'] = email
    msg['Subject'] = "Password Reset Request"

    reset_url = f"https://sycx.vercel.app?token={reset_token}"

    body = f"""
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Reset Your Password</title>
        <link href="https://fonts.googleapis.com/css2?family=Exo+2:wght@400;500;600;700&display=swap" rel="stylesheet">
    </head>
    <body style="margin: 0; padding: 0; font-family: 'Exo 2', sans-serif; background-color: #6a11cb; background-image: linear-gradient(to right, #6a11cb, #bc4e9c, #f56565);">
        <table border="0" cellpadding="0" cellspacing="0" width="100%" style="min-width: 100%;">
            <tr>
                <td align="center" style="padding: 20px 15px;">
                    <table border="0" cellpadding="0" cellspacing="0" width="100%" style="max-width: 400px; background-color: rgba(0, 0, 0, 0.7); border-radius: 20px; box-shadow: 0 4px 10px rgba(0,0,0,0.3);">
                        <tr>
                            <td align="center" style="padding: 40px 20px;">
                                <img src="https://opiyodon.github.io/sycx/sycx_flutter_app/assets/logo/logo.png" alt="SycX Logo" width="80" style="display: block; margin-bottom: 30px; max-width: 80px; height: auto;">
                                <h1 style="color: #ffffff; font-size: 24px; font-weight: bold; margin: 0 0 30px 0; text-shadow: 2px 2px 5px rgba(0,0,0,0.3);">Reset Your Password</h1>
                                <p style="color: #d0d8e0; font-size: 16px; line-height: 24px; margin: 0 0 20px 0;">Hi dear User,</p>
                                <p style="color: #d0d8e0; font-size: 16px; line-height: 24px; margin: 0 0 30px 0;">We received a request to reset your password. Click the button below to reset it:</p>
                                <a href="{reset_url}" style="display: inline-block; padding: 12px 24px; background-color: #3498db; color: #ffffff; font-size: 16px; font-weight: 600; text-decoration: none; border-radius: 25px; margin-bottom: 30px;">Reset Password</a>
                                <p style="color: #a0aec0; font-size: 12px; line-height: 18px; margin: 0 0 20px 0;">For security reasons, this link will expire on {expiration_time.strftime('%Y-%m-%d %H:%M:%S')} UTC.</p>
                                <p style="color: #a0aec0; font-size: 12px; line-height: 18px; margin: 0 0 10px 0;">If you didn't request a password reset, you can ignore this email.</p>
                                <p style="color: #a0aec0; font-size: 12px; line-height: 18px; margin: 0;">© 2024 SycX. All rights reserved.</p>
                            </td>
                        </tr>
                    </table>
                </td>
            </tr>
        </table>
    </body>
    </html>
    """

    msg.attach(MIMEText(body, 'html'))

    try:
        with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
            server.starttls()
            server.login(SMTP_USERNAME, SMTP_PASSWORD)
            server.send_message(msg)
        print(f"Reset email sent successfully to {email}")
    except Exception as e:
        print(f"Error sending email: {e}")
        raise

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
            'profile_pic': profile_pic_base64,
            'reset_token': None,
            'reset_token_expiry': None
        })

        return jsonify({'message': 'User registered successfully', 'user_id': str(result.inserted_id)})

    except Exception as e:
        print(f"An error occurred: {e}")
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/login', methods=['POST'])
def login():
    try:
        data = request.json if request.is_json else request.form
        username = data.get('username')
        password = data.get('password')

        if not username or not password:
            return jsonify({'error': 'Missing required fields'}), 400

        user = users_collection.find_one({'username': username})
        if not user or not check_password_hash(user['password'], password):
            return jsonify({'error': 'Invalid username or password'}), 400

        return jsonify({'message': 'Login successful', 'user_id': str(user['_id'])})
    except Exception as e:
        print(f"Login error: {e}")
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/forgot_password', methods=['POST'])
def forgot_password():
    try:
        data = request.get_json()
        if not data:
            return jsonify({'error': 'No JSON data received'}), 400

        email = data.get('email')

        if not email:
            return jsonify({'error': 'Missing email'}), 400

        user = users_collection.find_one({'email': email})
        if not user:
            return jsonify({'error': 'User not found'}), 404

        reset_token = str(uuid.uuid4())
        expiration_time = datetime.utcnow() + timedelta(hours=TOKEN_EXPIRATION_HOURS)
        users_collection.update_one(
            {'_id': user['_id']},
            {
                '$set': {
                    'reset_token': reset_token,
                    'reset_token_expiry': expiration_time
                }
            }
        )

        try:
            send_reset_email(email, reset_token, expiration_time)
            return jsonify({'message': 'Password reset email sent successfully'})
        except Exception as e:
            print(f"Error sending email: {e}")
            return jsonify({'error': 'Failed to send reset email'}), 500
    except Exception as e:
        print(f"Unexpected error in forgot_password: {e}")
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/reset_password', methods=['POST'])
def reset_password():
    try:
        data = request.json
        reset_token = data.get('token')
        new_password = data.get('new_password')

        if not reset_token or not new_password:
            return jsonify({'success': False, 'error': 'Missing token or new password'}), 400

        user = users_collection.find_one({'reset_token': reset_token})
        if not user:
            return jsonify({'success': False, 'error': 'Invalid or expired token'}), 400

        if user['reset_token_expiry'] < datetime.utcnow():
            return jsonify({'success': False, 'error': 'Token has expired'}), 400

        hashed_password = generate_password_hash(new_password)
        users_collection.update_one(
            {'_id': user['_id']},
            {
                '$set': {
                    'password': hashed_password,
                    'reset_token': None,
                    'reset_token_expiry': None
                }
            }
        )

        return jsonify({'success': True, 'message': 'Password reset successful'})
    except Exception as e:
        print(f"Error in reset_password: {str(e)}")
        return jsonify({'success': False, 'error': 'An unexpected error occurred'}), 500

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