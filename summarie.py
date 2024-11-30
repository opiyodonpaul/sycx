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
from logging.handlers import RotatingFileHandler
from io import BytesIO
from PIL import Image
import base64
from wordcloud import WordCloud
import matplotlib
# Force matplotlib to use non-interactive backend
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from cachetools import TTLCache, LRUCache
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import List, Dict, Optional
import time
import gc
import weakref
from functools import lru_cache
import tempfile
import atexit
from reportlab.platypus import Paragraph, Spacer, Image as ReportLabImage
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.lib.pagesizes import letter
from reportlab.platypus import SimpleDocTemplate
from reportlab.lib.utils import ImageReader

# Create logs directory if it doesn't exist
os.makedirs('logs', exist_ok=True)

# Configure logging with more detailed format
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - [%(filename)s:%(lineno)d] - %(message)s',
    handlers=[
        RotatingFileHandler(
            'logs/summary.log',
            maxBytes=1024*1024,
            backupCount=3
        ),
        logging.StreamHandler()
    ]
)

# NLTK data download with error handling and timeout
def download_nltk_data(timeout=30):
    try:
        with ThreadPoolExecutor() as executor:
            futures = [
                executor.submit(nltk.download, dataset, quiet=True)
                for dataset in ['punkt', 'stopwords']
            ]
            for future in as_completed(futures, timeout=timeout):
                future.result()
    except Exception as e:
        logging.warning(f"Failed to download NLTK data: {e}")

# Improved cache configuration with size limits
MAX_CACHE_SIZE = 100
image_cache = LRUCache(maxsize=MAX_CACHE_SIZE)
summary_cache = TTLCache(maxsize=MAX_CACHE_SIZE, ttl=1800)

# Rate limiting with improved reset mechanism
rate_limits = {
    'unsplash': {'limit': 50, 'interval': timedelta(hours=1), 'count': 0, 'reset': datetime.now()},
    'pexels': {'limit': 200, 'interval': timedelta(hours=1), 'count': 0, 'reset': datetime.now()}
}

def cleanup_resources():
    """Clean up resources and force garbage collection"""
    plt.close('all')
    gc.collect()

@lru_cache(maxsize=128)
def check_rate_limit(api_name):
    current_time = datetime.now()
    if current_time >= rate_limits[api_name]['reset']:
        rate_limits[api_name]['count'] = 0
        rate_limits[api_name]['reset'] = current_time + rate_limits[api_name]['interval']
    
    if rate_limits[api_name]['count'] < rate_limits[api_name]['limit']:
        rate_limits[api_name]['count'] += 1
        return True
    return False

def fetch_with_retries(fetch_func, retries=3, delay=2, *args, **kwargs):
    for attempt in range(retries):
        try:
            return fetch_func(*args, **kwargs)
        except Exception as e:
            logging.warning(f"Attempt {attempt + 1} failed: {e}")
            time.sleep(delay)
    logging.error("All retry attempts failed.")
    return []

def generate_summary(model, documents, summary_depth: float = 0.3, language: str = 'english') -> List[dict]:
    """
    Enhanced summary generation with robust error handling and flexible processing.
    
    Args:
        model: Summarization model instance
        documents (list): List of document dictionaries
        summary_depth (float): Depth of summarization
        language (str): Language of summarization
    
    Returns:
        List of summary dictionaries
    """
    if not documents:
        return []

    try:
        total_docs = len(documents)
        if total_docs == 0:
            raise ValueError("No valid documents provided")

        summary = []
        max_workers = min(os.cpu_count() or 1, total_docs)

        # Improved error handling in ThreadPoolExecutor
        with ThreadPoolExecutor(max_workers=max_workers) as executor:
            future_summaries = {}
            for i, doc in enumerate(documents):
                # Ensure content is not None and has sufficient length
                content = doc.get('content', '').strip()
                if content:
                    future = executor.submit(
                        _safe_generate_summary, 
                        model, 
                        content, 
                        summary_depth
                    )
                    future_summaries[future] = {
                        'title': doc.get('name', f'Document {i+1}'),
                        'index': i
                    }

            # Process completed futures
            for future in as_completed(future_summaries):
                try:
                    doc_summary = future.result()
                    metadata = future_summaries[future]
                    
                    if doc_summary:
                        summary_data = {
                            'title': metadata['title'],
                            'content': doc_summary
                        }
                        try:
                            enriched_summary = enrich_summary_with_visuals(summary_data)
                            summary.append(enriched_summary)
                        except Exception as visual_error:
                            logging.warning(f"Visual enhancement failed: {str(visual_error)}")
                            summary.append(summary_data)
                except Exception as e:
                    logging.error(f"Error processing document: {str(e)}")

        return summary

    except Exception as e:
        logging.error(f"Error in generate_summary: {str(e)}")
        return []
    finally:
        cleanup_resources()

def _safe_generate_summary(model, content, summary_depth):
    """
    Safely generate summary with fallback mechanisms.
    
    Args:
        model: Summarization model
        content (str): Document content
        summary_depth (float): Summarization depth
    
    Returns:
        str: Generated summary or original content if summarization fails
    """
    try:
        # Limit content length to prevent excessive processing
        max_content_length = 100000
        truncated_content = content[:max_content_length]
        
        # Attempt summarization with fallback
        summary = model.generate_summary(truncated_content, summary_depth)
        
        return summary if summary and len(summary) > 10 else truncated_content
    except Exception as e:
        logging.error(f"Summary generation error: {str(e)}")
        return content  # Return original content if summarization fails

def format_summary(summary):
    if not summary:
        return ""
        
    try:
        paragraphs = summary.split('\n\n')
        formatted_paragraphs = []
        
        for i, paragraph in enumerate(paragraphs):
            paragraph = paragraph.strip()
            if not paragraph:
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
        tokens = word_tokenize(text.lower())
        stop_words = set(stopwords.words('english') + list(string.punctuation))
        
        filtered_tokens = (word for word in tokens if word.isalnum() and word not in stop_words)
        
        fdist = FreqDist(filtered_tokens)
        
        return [word for word, _ in fdist.most_common(5)]
    except Exception as e:
        logging.error(f"Error in extract_keywords: {str(e)}")
        return []
    finally:
        del tokens
        cleanup_resources()

def optimize_image(image_data: bytes, max_size: int = 800) -> bytes:
    """Optimize image size while maintaining quality"""
    try:
        with Image.open(BytesIO(image_data)) as img:
            if img.mode in ('RGBA', 'P'):
                img = img.convert('RGB')
            
            if max(img.size) > max_size:
                ratio = max_size / max(img.size)
                new_size = tuple(int(dim * ratio) for dim in img.size)
                img = img.resize(new_size, Image.Resampling.LANCZOS)
            
            output = BytesIO()
            img.save(output, format='JPEG', optimize=True, quality=85)
            return output.getvalue()
    except Exception as e:
        logging.error(f"Error optimizing image: {str(e)}")
        return image_data

def fetch_images_from_multiple_sources(keywords):
    if not keywords:
        return []

    images = []
    apis = {
        'unsplash': fetch_image_unsplash,
        'pexels': fetch_image_pexels
    }

    try:
        with ThreadPoolExecutor(max_workers=2) as executor:
            futures = []
            for keyword in keywords:
                for api_name, fetch_func in apis.items():
                    if check_rate_limit(api_name):
                        futures.append(
                            executor.submit(fetch_images_from_cache_or_api, 
                                          keyword, api_name, fetch_func)
                        )

            for future in as_completed(futures, timeout=30):
                try:
                    result = future.result()
                    if result:
                        # Validate and download images immediately
                        valid_images = download_and_validate_images(result)
                        images.extend(valid_images)
                except Exception as e:
                    logging.error(f"Failed to fetch images: {str(e)}")
                finally:
                    future.cancel()

        return images
    except Exception as e:
        logging.error(f"Error in fetch_images_from_multiple_sources: {str(e)}")
        return []
    finally:
        cleanup_resources()

def download_and_validate_images(image_urls):
    valid_images = []
    for url in image_urls:
        try:
            if url.startswith('data:image'):
                # Handle base64 encoded images
                img_data = base64.b64decode(url.split(',')[1])
                valid_images.append(url)
            else:
                # Download and validate external images
                response = requests.get(url, timeout=10)
                response.raise_for_status()
                img = Image.open(BytesIO(response.content))
                img.verify()  # Verify image integrity
                valid_images.append(url)
        except Exception as e:
            logging.error(f"Invalid image URL {url}: {str(e)}")
            continue
    return valid_images

def fetch_images_from_cache_or_api(keyword, api_name, fetch_func):
    if not keyword:
        return []

    try:
        cache_key = f"{api_name}_{md5(keyword.encode('utf-8')).hexdigest()}"
        if cache_key in image_cache:
            return image_cache[cache_key]
        
        images = fetch_func(keyword)
        if images:
            if len(image_cache) >= MAX_CACHE_SIZE:
                image_cache.pop(next(iter(image_cache)))
            image_cache[cache_key] = images
        return images
    except Exception as e:
        logging.error(f"Error in fetch_images_from_cache_or_api: {str(e)}")
        return []

def fetch_image_unsplash(keyword):
    if not os.getenv("UNSPLASH_ACCESS_KEY"):
        return []
    
    try:
        headers = {
            'Authorization': f'Client-ID {os.getenv("UNSPLASH_ACCESS_KEY")}',
            'Accept-Version': 'v1'
        }
        
        with requests.Session() as session:
            response = session.get(
                'https://api.unsplash.com/photos/random',
                params={'query': keyword, 'orientation': 'landscape'},
                headers=headers,
                timeout=10
            )
            response.raise_for_status()
            data = response.json()
            
            # Get the small version of the image
            image_url = data['urls']['small']
            
            # Validate the URL
            test_response = session.head(image_url, timeout=5)
            test_response.raise_for_status()
            
            return [image_url]
    except Exception as e:
        logging.error(f"Error fetching image from Unsplash: {str(e)}")
        return []

def fetch_image_pexels(keyword):
    if not os.getenv("PEXELS_API_KEY"):
        return []
    
    try:
        headers = {
            'Authorization': os.getenv("PEXELS_API_KEY")
        }
        
        with requests.Session() as session:
            response = session.get(
                'https://api.pexels.com/v1/search',
                params={'query': keyword, 'per_page': 1, 'orientation': 'landscape'},
                headers=headers,
                timeout=10
            )
            response.raise_for_status()
            data = response.json()
            
            if data.get('photos'):
                image_url = data['photos'][0]['src']['medium']
                
                # Validate the URL
                test_response = session.head(image_url, timeout=5)
                test_response.raise_for_status()
                
                return [image_url]
            return []
    except Exception as e:
        logging.error(f"Error fetching image from Pexels: {str(e)}")
        return []

def generate_wordcloud(text):
    if not text:
        return None

    try:
        max_text_length = 10000
        truncated_text = text[:max_text_length] if len(text) > max_text_length else text
        
        # Create word cloud
        wordcloud = WordCloud(
            width=800, 
            height=400, 
            background_color='white',
            max_words=100
        ).generate(truncated_text)
        
        # Save to BytesIO buffer
        img_buffer = BytesIO()
        wordcloud.to_image().save(img_buffer, format='PNG')
        img_buffer.seek(0)
        
        # Convert to base64
        img_str = base64.b64encode(img_buffer.getvalue()).decode()
        return f"data:image/png;base64,{img_str}"
    except Exception as e:
        logging.error(f"Error generating word cloud: {str(e)}")
        return None
    finally:
        cleanup_resources()

def insert_visuals_into_summary(summary, images, wordcloud):
    if not summary:
        return summary

    try:
        paragraphs = summary.split('\n\n')
        enriched_paragraphs = []
        
        # Add wordcloud at the top if available
        if wordcloud:
            enriched_paragraphs.append(f'![Word Cloud]({wordcloud})')
        
        # Process paragraphs and images
        for i, paragraph in enumerate(paragraphs):
            if paragraph.strip():
                enriched_paragraphs.append(paragraph)
                
                # Add image if available
                if i < len(images) and images[i]:
                    try:
                        # Validate image URL or data URI
                        image_url = images[i]
                        if image_url.startswith(('http://', 'https://', 'data:image')):
                            enriched_paragraphs.append(
                                f'\n![Image {i+1}]({image_url})\n'
                            )
                    except Exception as e:
                        logging.error(f"Error inserting image {i}: {str(e)}")
                        continue
        
        return '\n\n'.join(enriched_paragraphs)
    except Exception as e:
        logging.error(f"Error in insert_visuals_into_summary: {str(e)}")
        return summary

def enrich_summary_with_visuals(summary: dict) -> dict:
    if not summary or not isinstance(summary, dict):
        return summary

    try:
        content = summary.get('content', '')
        if not content:
            return summary

        # Extract keywords from the first part of content
        keywords = extract_keywords(content[:50000])
        if not keywords:
            return summary

        # Generate word cloud first
        wordcloud = None
        try:
            wordcloud = generate_wordcloud(content[:20000])
        except Exception as e:
            logging.error(f"Error generating wordcloud: {str(e)}")

        # Fetch and validate images
        images = []
        try:
            images = fetch_images_from_multiple_sources(keywords[:3])
        except Exception as e:
            logging.error(f"Error fetching images: {str(e)}")

        # Insert visuals into content
        try:
            enriched_content = insert_visuals_into_summary(content, images, wordcloud)
        except Exception as e:
            logging.error(f"Error inserting visuals: {str(e)}")
            enriched_content = content

        # Apply custom formatting and styling
        formatted_summary = format_enriched_summary(enriched_content)

        return {
            'title': summary.get('title', ''),
            'content': formatted_summary
        }
    except Exception as e:
        logging.error(f"Error in enrich_summary_with_visuals: {str(e)}")
        return summary
    finally:
        cleanup_resources()

def format_enriched_summary(summary: str) -> str:
    """
    Apply custom formatting and styling to the enriched summary.
    """
    try:
        # Use a playful, youthful font
        font_family = '"Architects Daughter", cursive'

        # Create a structured layout with headings, subheadings, and paragraphs
        formatted_paragraphs = []
        for paragraph in summary.split('\n\n'):
            paragraph = paragraph.strip()
            if not paragraph:
                continue

            if paragraph.startswith('# '):
                formatted_paragraphs.append(
                    f'<h1 style="font-family: {font_family}; font-size: 32px; margin-bottom: 24px;">{paragraph[2:]}</h1>'
                )
            elif paragraph.startswith('## '):
                formatted_paragraphs.append(
                    f'<h2 style="font-family: {font_family}; font-size: 24px; margin-bottom: 18px;">{paragraph[3:]}</h2>'
                )
            else:
                formatted_paragraphs.append(
                    f'<p style="font-family: {font_family}; font-size: 16px; line-height: 1.5; margin-bottom: 12px;">{paragraph}</p>'
                )

        # Arrange the formatted paragraphs in a non-linear layout
        formatted_summary = '<div style="display: flex; flex-wrap: wrap; justify-content: space-between; align-items: flex-start;">'
        for i, para in enumerate(formatted_paragraphs):
            if i % 2 == 0:
                formatted_summary += f'<div style="width: 48%; margin-bottom: 24px;">{para}</div>'
            else:
                formatted_summary += f'<div style="width: 48%; margin-bottom: 24px; transform: translateY(-12px);">{para}</div>'
        formatted_summary += '</div>'

        return formatted_summary
    except Exception as e:
        logging.error(f"Error in format_enriched_summary: {str(e)}")
        return summary