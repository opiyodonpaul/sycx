import openai
import os
import requests
from datetime import datetime, timedelta
from hashlib import md5
from functools import lru_cache

# Cache and Rate Limiting Configurations
image_cache = {}
rate_limits = {
    'unsplash': {'limit': 50, 'interval': timedelta(hours=1), 'count': 0, 'reset': datetime.now()},
    'pexels': {'limit': 200, 'interval': timedelta(hours=1), 'count': 0, 'reset': datetime.now()},
    'pixabay': {'limit': 500, 'interval': timedelta(hours=1), 'count': 0, 'reset': datetime.now()}
}

def check_rate_limit(api_name):
    """ Check if API usage is within the allowed rate limits """
    if datetime.now() >= rate_limits[api_name]['reset']:
        rate_limits[api_name]['count'] = 0
        rate_limits[api_name]['reset'] = datetime.now() + rate_limits[api_name]['interval']
    
    if rate_limits[api_name]['count'] < rate_limits[api_name]['limit']:
        rate_limits[api_name]['count'] += 1
        return True
    return False

def summarize_document(document, summary_id, user_id, summaries_collection):
    content = document.read().decode('utf-8')  # Assuming text-based files
    
    summary_response = openai.Completion.create(
        engine="davinci-codex",
        prompt=f"Summarize the following document in a visually rich format with headings, subheadings, images, and links:\n\n{content}",
        max_tokens=1024,
        n=1,
        stop=None,
        temperature=0.5
    )
    summary = summary_response.choices[0].text.strip()
    
    enriched_summary = enrich_summary_with_visuals(summary)
    
    summary_data = {
        "_id": summary_id,
        "user_id": user_id,
        "document_content": content,
        "summary": enriched_summary,
        "feedback": []
    }
    summaries_collection.insert_one(summary_data)
    
    return enriched_summary

def enrich_summary_with_visuals(summary):
    keywords = extract_keywords(summary)
    images = fetch_images_from_multiple_sources(keywords)
    enriched_summary = insert_visuals_into_summary(summary, images)
    
    return enriched_summary

def extract_keywords(text):
    keywords = text.split()[:5]  # Simplified example
    return keywords

def fetch_images_from_multiple_sources(keywords):
    """ Fetch images from Unsplash, Pexels, and Pixabay """
    images = []
    for keyword in keywords:
        if check_rate_limit('unsplash'):
            images.extend(fetch_images_from_cache_or_api(keyword, 'unsplash', fetch_image_unsplash))
        if check_rate_limit('pexels'):
            images.extend(fetch_images_from_cache_or_api(keyword, 'pexels', fetch_image_pexels))
        if check_rate_limit('pixabay'):
            images.extend(fetch_images_from_cache_or_api(keyword, 'pixabay', fetch_image_pixabay))
    return images

def fetch_images_from_cache_or_api(keyword, api_name, fetch_func):
    cache_key = f"{api_name}_{md5(keyword.encode('utf-8')).hexdigest()}"
    if cache_key in image_cache:
        return image_cache[cache_key]
    images = fetch_func(keyword)
    image_cache[cache_key] = images
    return images

def fetch_image_unsplash(keyword):
    """ Fetch images from Unsplash """
    response = requests.get(f'https://api.unsplash.com/photos/random?query={keyword}&client_id={os.getenv("UNSPLASH_ACCESS_KEY")}')
    if response.status_code == 200:
        return [response.json()['urls']['regular']]
    return []

def fetch_image_pexels(keyword):
    """ Fetch images from Pexels """
    headers = {
        'Authorization': os.getenv("PEXELS_API_KEY")
    }
    response = requests.get(f'https://api.pexels.com/v1/search?query={keyword}&per_page=1', headers=headers)
    if response.status_code == 200:
        data = response.json()
        if data['photos']:
            return [data['photos'][0]['src']['medium']]
    return []

def fetch_image_pixabay(keyword):
    """ Fetch images from Pixabay """
    response = requests.get(f'https://pixabay.com/api/?key={os.getenv("PIXABAY_API_KEY")}&q={keyword}&image_type=photo&per_page=1')
    if response.status_code == 200:
        data = response.json()
        if data['hits']:
            return [data['hits'][0]['webformatURL']]
    return []

def insert_visuals_into_summary(summary, images):
    for image in images:
        summary += f'\n![Image]({image})\n'
    return summary

def save_feedback(summary_id, user_id, feedback_text, summaries_collection):
    summaries_collection.update_one(
        {"_id": summary_id, "user_id": user_id},
        {"$push": {"feedback": feedback_text}}
    )
    pass

def retrieve_summary(summary_id, summaries_collection):
    summary_data = summaries_collection.find_one({"_id": summary_id})
    if summary_data:
        return summary_data['summary']
    else:
        return "Summary not found"

def download_summary_file(summary_id, summaries_collection):
    summary_data = summaries_collection.find_one({"_id": summary_id})
    if summary_data:
        file_path = f"summaries/{summary_id}.txt"
        with open(file_path, 'w') as f:
            f.write(summary_data['summary'])
        return file_path
    else:
        return "Summary not found"
