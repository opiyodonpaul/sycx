import os
import requests
from datetime import datetime, timedelta
from hashlib import md5
import nltk
from nltk.tokenize import word_tokenize
from nltk.corpus import stopwords
from nltk.probability import FreqDist
import string
import re
import markdown
import logging
from io import BytesIO
from PIL import Image
import base64
from wordcloud import WordCloud
import matplotlib.pyplot as plt
from reportlab.lib.pagesizes import letter
from reportlab.pdfgen import canvas
from reportlab.lib.utils import ImageReader
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Image as ReportLabImage
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from cachetools import TTLCache
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import List, Dict, Optional
import time

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Ensure NLTK data is downloaded
try:
    nltk.download('punkt', quiet=True)
    nltk.download('stopwords', quiet=True)
except Exception as e:
    logging.warning(f"Failed to download NLTK data: {e}")

# Cache and Rate Limiting Configurations
image_cache = TTLCache(maxsize=1000, ttl=3600)  # Cache images for 1 hour
summary_cache = TTLCache(maxsize=500, ttl=1800)  # Cache summaries for 30 minutes
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

def generate_summary(model, documents, summary_depth: float = 0.3, language: str = 'english') -> List[dict]:
    try:
        total_docs = len(documents)
        if total_docs == 0:
            raise ValueError("No documents provided")

        summary = []
        with ThreadPoolExecutor() as executor:
            future_summaries = [executor.submit(model, doc.get('content', ''), summary_depth, 'incremental') 
                              for doc in documents if doc.get('content')]
            for i, future in enumerate(as_completed(future_summaries)):
                try:
                    doc_summary = future.result()
                    if doc_summary:
                        summary.append({
                            'title': documents[i].get('name', f'Document {i+1}'),
                            'content': doc_summary
                        })
                except Exception as e:
                    logging.error(f"Error processing document {i}: {str(e)}")

        return summary

    except Exception as e:
        logging.error(f"Error in generate_summary: {str(e)}")
        raise

def format_summary(summary):
    if not summary:
        return ""
        
    try:
        paragraphs = summary.split('\n\n')
        formatted_paragraphs = []
        
        for i, paragraph in enumerate(paragraphs):
            if not paragraph.strip():
                continue
                
            if i == 0:
                formatted_paragraphs.append(f"# {paragraph}")
            else:
                if re.match(r'^\d+\.', paragraph):
                    formatted_paragraphs.append(re.sub(r'^(\d+\.)', r'\n\1', paragraph))
                elif re.match(r'^\*', paragraph):
                    formatted_paragraphs.append(re.sub(r'^\*', r'\n*', paragraph))
                else:
                    formatted_paragraphs.append(f"\n## {paragraph}")
        
        formatted_summary = '\n\n'.join(formatted_paragraphs)
        return re.sub(r'(\w+):', r'**\1**:', formatted_summary)
    except Exception as e:
        logging.error(f"Error in format_summary: {str(e)}")
        return summary

def extract_keywords(text):
    if not text:
        return []
        
    try:
        # Tokenize and clean text
        tokens = word_tokenize(text.lower())
        tokens = [word for word in tokens if word.isalnum()]
        
        # Remove stopwords
        stop_words = set(stopwords.words('english') + list(string.punctuation))
        filtered_tokens = [word for word in tokens if word not in stop_words]
        
        # Get frequency distribution
        fdist = FreqDist(filtered_tokens)
        
        # Return top keywords
        return [word for word, freq in fdist.most_common(5)]
    except Exception as e:
        logging.error(f"Error in extract_keywords: {str(e)}")
        return []

def enrich_summary_with_visuals(summary: dict) -> dict:
    if not summary or not isinstance(summary, dict):
        return summary

    try:
        content = summary.get('content', '')
        if not content:
            return summary

        keywords = extract_keywords(content)
        if not keywords:
            return summary

        # Try generating word cloud
        wordcloud = None
        try:
            wordcloud = generate_wordcloud(content)
        except Exception as e:
            logging.error(f"Error generating wordcloud: {str(e)}")

        # Try fetching images
        images = []
        try:
            images = fetch_images_from_multiple_sources(keywords, max_images=1)
        except Exception as e:
            logging.error(f"Error fetching images: {str(e)}")

        # Try inserting visuals into summary
        enriched_content = content
        try:
            enriched_content = insert_visuals_into_summary(content, images, wordcloud)
        except Exception as e:
            logging.error(f"Error inserting visuals: {str(e)}")

        return {
            'title': summary.get('title', ''),
            'content': enriched_content
        }
    except Exception as e:
        logging.error(f"Error in enrich_summary_with_visuals: {str(e)}")
        return summary

def fetch_images_from_multiple_sources(keywords):
    if not keywords:
        return []

    images = []
    apis = {
        'unsplash': fetch_image_unsplash,
        'pexels': fetch_image_pexels,
        'pixabay': fetch_image_pixabay
    }

    with ThreadPoolExecutor() as executor:
        futures = []
        for keyword in keywords[:1]:  # Limit to first keyword to avoid rate limits
            for api_name, fetch_func in apis.items():
                if check_rate_limit(api_name):
                    futures.append(
                        executor.submit(fetch_images_from_cache_or_api, 
                                      keyword, api_name, fetch_func)
                    )
        
        for future in as_completed(futures):
            try:
                result = future.result()
                if result:
                    images.extend(result)
            except Exception as e:
                logging.error(f"Error fetching images: {str(e)}")

    return images[:3]

def fetch_images_from_cache_or_api(keyword, api_name, fetch_func):
    if not keyword:
        return []

    try:
        cache_key = f"{api_name}_{md5(keyword.encode('utf-8')).hexdigest()}"
        if cache_key in image_cache:
            return image_cache[cache_key]
        
        images = fetch_func(keyword)
        if images:
            image_cache[cache_key] = images
        return images
    except Exception as e:
        logging.error(f"Error in fetch_images_from_cache_or_api: {str(e)}")
        return []

def fetch_image_unsplash(keyword):
    if not os.getenv("UNSPLASH_ACCESS_KEY"):
        return []

    try:
        response = requests.get(
            f'https://api.unsplash.com/photos/random',
            params={'query': keyword},
            headers={'Authorization': f'Client-ID {os.getenv("UNSPLASH_ACCESS_KEY")}'},
            timeout=10
        )
        response.raise_for_status()
        return [response.json()['urls']['small']]
    except Exception as e:
        logging.error(f"Error fetching image from Unsplash: {str(e)}")
        return []

def fetch_image_pexels(keyword):
    if not os.getenv("PEXELS_API_KEY"):
        return []

    try:
        response = requests.get(
            f'https://api.pexels.com/v1/search',
            params={'query': keyword, 'per_page': 1},
            headers={'Authorization': os.getenv("PEXELS_API_KEY")},
            timeout=10
        )
        response.raise_for_status()
        data = response.json()
        if data.get('photos'):
            return [data['photos'][0]['src']['small']]
        return []
    except Exception as e:
        logging.error(f"Error fetching image from Pexels: {str(e)}")
        return []

def fetch_image_pixabay(keyword):
    if not os.getenv("PIXABAY_API_KEY"):
        return []

    try:
        response = requests.get(
            'https://pixabay.com/api/',
            params={
                'key': os.getenv("PIXABAY_API_KEY"),
                'q': keyword,
                'image_type': 'photo',
                'per_page': 1
            },
            timeout=10
        )
        response.raise_for_status()
        data = response.json()
        if data.get('hits'):
            return [data['hits'][0]['webformatURL']]
        return []
    except Exception as e:
        logging.error(f"Error fetching image from Pixabay: {str(e)}")
        return []

def generate_wordcloud(text):
    if not text:
        return None

    try:
        wordcloud = WordCloud(width=800, height=400, background_color='white').generate(text)
        plt.figure(figsize=(10, 5))
        plt.imshow(wordcloud, interpolation='bilinear')
        plt.axis('off')
        img_buffer = BytesIO()
        plt.savefig(img_buffer, format='png', bbox_inches='tight', pad_inches=0)
        plt.close()
        img_buffer.seek(0)
        img_str = base64.b64encode(img_buffer.getvalue()).decode()
        return f"data:image/png;base64,{img_str}"
    except Exception as e:
        logging.error(f"Error generating word cloud: {str(e)}")
        return None

def insert_visuals_into_summary(summary, images, wordcloud):
    if not summary:
        return summary

    try:
        paragraphs = summary.split('\n\n')
        enriched_paragraphs = []
        
        if wordcloud:
            enriched_paragraphs.append(f'![Word Cloud]({wordcloud})')
        
        for i, paragraph in enumerate(paragraphs):
            if paragraph.strip():
                enriched_paragraphs.append(paragraph)
                
                if i < len(images) and images[i]:
                    enriched_paragraphs.append(
                        f'\n![Image related to {paragraph[:30].replace("[", "").replace("]", "")}...]({images[i]})\n'
                    )
        
        return '\n\n'.join(enriched_paragraphs)
    except Exception as e:
        logging.error(f"Error in insert_visuals_into_summary: {str(e)}")
        return summary

def convert_summary_to_pdf(summary_content):
    if not summary_content:
        raise ValueError("No content provided for PDF conversion")

    try:
        buffer = BytesIO()
        doc = SimpleDocTemplate(
            buffer, 
            pagesize=letter,
            rightMargin=72, 
            leftMargin=72,
            topMargin=72, 
            bottomMargin=18
        )
        
        styles = getSampleStyleSheet()
        styles.add(ParagraphStyle(name='Justify', alignment=4))
        
        story = []
        
        html = markdown.markdown(summary_content)
        
        paragraphs = re.split('<h[1-6]>|</h[1-6]>|<p>|</p>', html)
        paragraphs = [p.strip() for p in paragraphs if p.strip()]
        
        for para in paragraphs:
            try:
                if para.startswith('!['):
                    img_match = re.search(r'\((.*?)\)', para)
                    if img_match:
                        img_src = img_match.group(1)
                        if img_src.startswith('data:image/png;base64,'):
                            img_data = base64.b64decode(img_src.split(',')[1])
                            img = ImageReader(BytesIO(img_data))
                        else:
                            response = requests.get(img_src, stream=True, timeout=10)
                            response.raise_for_status()
                            img = ImageReader(BytesIO(response.content))
                        
                        img_width, img_height = img.getSize()
                        aspect = img_height / float(img_width)
                        img_width = 6 * inch
                        img_height = aspect * img_width
                        story.append(ReportLabImage(img, width=img_width, height=img_height))
                else:
                    story.append(Paragraph(para, styles['Justify']))
                story.append(Spacer(1, 12))
            except Exception as e:
                logging.error(f"Error processing paragraph in PDF conversion: {str(e)}")
                continue
        
        doc.build(story)
        buffer.seek(0)
        return buffer.getvalue()
    except Exception as e:
        logging.error(f"Error converting summary to PDF: {str(e)}")
        raise