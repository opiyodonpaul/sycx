import os
import requests
from datetime import datetime, timedelta
from hashlib import md5
import nltk
from nltk.tokenize import word_tokenize, sent_tokenize
from nltk.corpus import stopwords
from nltk.probability import FreqDist
import string
import re
import markdown
from tabulate import tabulate

nltk.download('punkt')
nltk.download('stopwords')

# Cache and Rate Limiting Configurations
image_cache = {}
rate_limits = {
    'unsplash': {'limit': 50, 'interval': timedelta(hours=1), 'count': 0, 'reset': datetime.now()},
    'pexels': {'limit': 200, 'interval': timedelta(hours=1), 'count': 0, 'reset': datetime.now()},
    'pixabay': {'limit': 500, 'interval': timedelta(hours=1), 'count': 0, 'reset': datetime.now()}
}

def check_rate_limit(api_name):
    if datetime.now() >= rate_limits[api_name]['reset']:
        rate_limits[api_name]['count'] = 0
        rate_limits[api_name]['reset'] = datetime.now() + rate_limits[api_name]['interval']
    
    if rate_limits[api_name]['count'] < rate_limits[api_name]['limit']:
        rate_limits[api_name]['count'] += 1
        return True
    return False

def summarize_documents(model, documents, merge_summaries, summary_depth, language):
    if merge_summaries:
        merged_content = "\n\n".join([doc['content'] for doc in documents])
        summary = model.generate_summary(merged_content, max_length=int(len(merged_content) * summary_depth))
        formatted_summary = format_summary(summary)
        return [{'title': 'Merged Summary', 'content': formatted_summary}]
    else:
        summaries = []
        for doc in documents:
            summary = model.generate_summary(doc['content'], max_length=int(len(doc['content']) * summary_depth))
            formatted_summary = format_summary(summary)
            summaries.append({'title': doc['name'], 'content': formatted_summary})
        return summaries

def format_summary(summary):
    # Split the summary into paragraphs
    paragraphs = summary.split('\n\n')
    
    formatted_paragraphs = []
    for i, paragraph in enumerate(paragraphs):
        if i == 0:
            # First paragraph as title
            formatted_paragraphs.append(f"# {paragraph}")
        else:
            # Check if the paragraph is a list
            if re.match(r'^\d+\.', paragraph):
                # Numbered list
                formatted_paragraphs.append(re.sub(r'^(\d+\.)', r'\n\1', paragraph))
            elif re.match(r'^\*', paragraph):
                # Bullet point list
                formatted_paragraphs.append(re.sub(r'^\*', r'\n*', paragraph))
            else:
                # Regular paragraph
                formatted_paragraphs.append(f"\n## {paragraph}")
    
    # Join the formatted paragraphs
    formatted_summary = '\n\n'.join(formatted_paragraphs)
    
    # Convert potential table-like content to Markdown tables
    formatted_summary = convert_to_tables(formatted_summary)
    
    # Add some formatting for better readability
    formatted_summary = re.sub(r'(\w+):', r'**\1**:', formatted_summary)  # Bold key terms
    
    return formatted_summary

def convert_to_tables(text):
    lines = text.split('\n')
    table_lines = []
    non_table_lines = []
    
    for line in lines:
        if '|' in line and len(line.split('|')) > 2:
            table_lines.append(line)
        else:
            if table_lines:
                non_table_lines.append(tabulate([row.split('|') for row in table_lines], tablefmt="pipe"))
                table_lines = []
            non_table_lines.append(line)
    
    if table_lines:
        non_table_lines.append(tabulate([row.split('|') for row in table_lines], tablefmt="pipe"))
    
    return '\n'.join(non_table_lines)

def enrich_summary_with_visuals(summary):
    keywords = extract_keywords(summary['content'])
    images = fetch_images_from_multiple_sources(keywords)
    
    if images:
        enriched_summary = insert_visuals_into_summary(summary['content'], images)
    else:
        enriched_summary = summary['content']
    
    return {
        'title': summary['title'],
        'content': enriched_summary
    }

def extract_keywords(text):
    tokens = word_tokenize(text.lower())
    tokens = [word for word in tokens if word.isalnum()]
    stop_words = set(stopwords.words('english') + list(string.punctuation))
    filtered_tokens = [word for word in tokens if word not in stop_words]

    fdist = FreqDist(filtered_tokens)
    
    keywords = [word for word, freq in fdist.most_common(5)]
    
    return keywords

def fetch_images_from_multiple_sources(keywords):
    images = []
    for keyword in keywords:
        if check_rate_limit('unsplash'):
            images.extend(fetch_images_from_cache_or_api(keyword, 'unsplash', fetch_image_unsplash))
        if check_rate_limit('pexels'):
            images.extend(fetch_images_from_cache_or_api(keyword, 'pexels', fetch_image_pexels))
        if check_rate_limit('pixabay'):
            images.extend(fetch_images_from_cache_or_api(keyword, 'pixabay', fetch_image_pixabay))
    return images[:3]

def fetch_images_from_cache_or_api(keyword, api_name, fetch_func):
    cache_key = f"{api_name}_{md5(keyword.encode('utf-8')).hexdigest()}"
    if cache_key in image_cache:
        return image_cache[cache_key]
    images = fetch_func(keyword)
    image_cache[cache_key] = images
    return images

def fetch_image_unsplash(keyword):
    response = requests.get(f'https://api.unsplash.com/photos/random?query={keyword}&client_id={os.getenv("UNSPLASH_ACCESS_KEY")}')
    if response.status_code == 200:
        return [response.json()['urls']['small']]
    return []

def fetch_image_pexels(keyword):
    headers = {
        'Authorization': os.getenv("PEXELS_API_KEY")
    }
    response = requests.get(f'https://api.pexels.com/v1/search?query={keyword}&per_page=1', headers=headers)
    if response.status_code == 200:
        data = response.json()
        if data['photos']:
            return [data['photos'][0]['src']['small']]
    return []

def fetch_image_pixabay(keyword):
    response = requests.get(f'https://pixabay.com/api/?key={os.getenv("PIXABAY_API_KEY")}&q={keyword}&image_type=photo&per_page=1')
    if response.status_code == 200:
        data = response.json()
        if data['hits']:
            return [data['hits'][0]['webformatURL']]
    return []

def insert_visuals_into_summary(summary, images):
    paragraphs = summary.split('\n\n')
    enriched_paragraphs = []
    for i, paragraph in enumerate(paragraphs):
        enriched_paragraphs.append(paragraph)
        
        if i < len(images):
            enriched_paragraphs.append(f'\n![Image related to {paragraph[:30]}...]({images[i]})\n')
    
    return '\n\n'.join(enriched_paragraphs)