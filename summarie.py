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
import matplotlib.pyplot as plt
from reportlab.lib.pagesizes import letter
from reportlab.pdfgen import canvas
from reportlab.lib.utils import ImageReader
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Image as ReportLabImage
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from cachetools import TTLCache, LRUCache
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import List, Dict, Optional
import time
import gc
import weakref
from functools import lru_cache

# Create logs directory if it doesn't exist
os.makedirs('logs', exist_ok=True)

# Configure logging with more detailed format
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - [%(filename)s:%(lineno)d] - %(message)s',
    handlers=[
        RotatingFileHandler(
            'logs/summary.log',  # Changed path to logs directory
            maxBytes=1024*1024,
            backupCount=3
        ),
        logging.StreamHandler()  # Added console output
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
MAX_CACHE_SIZE = 100  # Limit cache size
image_cache = LRUCache(maxsize=MAX_CACHE_SIZE)  # Using LRU instead of TTL for better memory management
summary_cache = TTLCache(maxsize=MAX_CACHE_SIZE, ttl=1800)

# Rate limiting with improved reset mechanism
rate_limits = {
    'unsplash': {'limit': 50, 'interval': timedelta(hours=1), 'count': 0, 'reset': datetime.now()},
    'pexels': {'limit': 200, 'interval': timedelta(hours=1), 'count': 0, 'reset': datetime.now()},
    'pixabay': {'limit': 500, 'interval': timedelta(hours=1), 'count': 0, 'reset': datetime.now()}
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

def generate_summary(model, documents, summary_depth: float = 0.3, language: str = 'english') -> List[dict]:
    try:
        total_docs = len(documents)
        if total_docs == 0:
            raise ValueError("No documents provided")

        summary = []
        # Limit concurrent threads based on CPU count
        max_workers = min(os.cpu_count() or 1, total_docs)
        
        with ThreadPoolExecutor(max_workers=max_workers) as executor:
            future_summaries = [
                executor.submit(model, doc.get('content', ''), summary_depth, 'incremental') 
                for doc in documents if doc.get('content')
            ]
            
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
                finally:
                    # Clean up completed futures
                    future.cancel()

        return summary

    except Exception as e:
        logging.error(f"Error in generate_summary: {str(e)}")
        raise
    finally:
        cleanup_resources()

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
        # Optimize tokenization with batch processing
        tokens = word_tokenize(text.lower())
        stop_words = set(stopwords.words('english') + list(string.punctuation))
        
        # Use generator expression for memory efficiency
        filtered_tokens = (word for word in tokens if word.isalnum() and word not in stop_words)
        
        # Get frequency distribution with limited size
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
            # Convert to RGB if necessary
            if img.mode in ('RGBA', 'P'):
                img = img.convert('RGB')
            
            # Resize if larger than max_size
            if max(img.size) > max_size:
                ratio = max_size / max(img.size)
                new_size = tuple(int(dim * ratio) for dim in img.size)
                img = img.resize(new_size, Image.Resampling.LANCZOS)
            
            # Optimize output
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
        'pexels': fetch_image_pexels,
        'pixabay': fetch_image_pixabay
    }

    try:
        with ThreadPoolExecutor(max_workers=3) as executor:
            futures = []
            for keyword in keywords[:1]:
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
                finally:
                    future.cancel()

        return images[:3]
    finally:
        cleanup_resources()

def fetch_images_from_cache_or_api(keyword, api_name, fetch_func):
    if not keyword:
        return []

    try:
        cache_key = f"{api_name}_{md5(keyword.encode('utf-8')).hexdigest()}"
        if cache_key in image_cache:
            return image_cache[cache_key]
        
        images = fetch_func(keyword)
        if images:
            # Limit cache size
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
        with requests.Session() as session:
            response = session.get(
                f'https://api.unsplash.com/photos/random',
                params={'query': keyword},
                headers={'Authorization': f'Client-ID {os.getenv("UNSPLASH_ACCESS_KEY")}'},
                timeout=10
            )
            response.raise_for_status()
            image_url = response.json()['urls']['small']
            image_data = session.get(image_url, timeout=10).content
            optimized_data = optimize_image(image_data)
            return [image_url]
    except Exception as e:
        logging.error(f"Error fetching image from Unsplash: {str(e)}")
        return []

def fetch_image_pexels(keyword):
    if not os.getenv("PEXELS_API_KEY"):
        return []

    try:
        with requests.Session() as session:
            response = session.get(
                f'https://api.pexels.com/v1/search',
                params={'query': keyword, 'per_page': 1},
                headers={'Authorization': os.getenv("PEXELS_API_KEY")},
                timeout=10
            )
            response.raise_for_status()
            data = response.json()
            if data.get('photos'):
                image_url = data['photos'][0]['src']['small']
                image_data = session.get(image_url, timeout=10).content
                optimized_data = optimize_image(image_data)
                return [image_url]
        return []
    except Exception as e:
        logging.error(f"Error fetching image from Pexels: {str(e)}")
        return []

def fetch_image_pixabay(keyword):
    if not os.getenv("PIXABAY_API_KEY"):
        return []

    try:
        with requests.Session() as session:
            response = session.get(
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
                image_url = data['hits'][0]['webformatURL']
                image_data = session.get(image_url, timeout=10).content
                optimized_data = optimize_image(image_data)
                return [image_url]
        return []
    except Exception as e:
        logging.error(f"Error fetching image from Pixabay: {str(e)}")
        return []

def generate_wordcloud(text):
    if not text:
        return None

    try:
        # Limit text size for wordcloud
        max_text_length = 10000
        truncated_text = text[:max_text_length] if len(text) > max_text_length else text
        
        wordcloud = WordCloud(
            width=800, 
            height=400, 
            background_color='white',
            max_words=100  # Limit number of words
        ).generate(truncated_text)
        
        plt.figure(figsize=(10, 5), dpi=100)  # Lower DPI for memory efficiency
        plt.imshow(wordcloud, interpolation='bilinear')
        plt.axis('off')
        
        img_buffer = BytesIO()
        plt.savefig(img_buffer, format='png', bbox_inches='tight', pad_inches=0, dpi=100)
        plt.close()
        
        img_buffer.seek(0)
        img_str = base64.b64encode(img_buffer.getvalue()).decode()
        return f"data:image/png;base64,{img_str}"
    except Exception as e:
        logging.error(f"Error generating word cloud: {str(e)}")
        return None
    finally:
        plt.close('all')
        cleanup_resources()

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
                            with requests.Session() as session:
                                response = session.get(img_src, stream=True, timeout=10)
                                response.raise_for_status()
                                img_data = optimize_image(response.content)
                                img = ImageReader(BytesIO(img_data))
                        
                        img_width, img_height = img.getSize()
                        aspect = img_height / float(img_width)
                        
                        # Limit maximum image size in PDF
                        max_width = 6 * inch
                        img_width = min(max_width, img_width)
                        img_height = aspect * img_width
                        
                        story.append(ReportLabImage(img, width=img_width, height=img_height))
                        # Force cleanup of image data
                        del img_data
                        gc.collect()
                else:
                    # Limit paragraph length
                    max_para_length = 5000
                    if len(para) > max_para_length:
                        para = para[:max_para_length] + "..."
                    story.append(Paragraph(para, styles['Justify']))
                story.append(Spacer(1, 12))
            except Exception as e:
                logging.error(f"Error processing paragraph in PDF conversion: {str(e)}")
                continue
            finally:
                # Clean up paragraph processing resources
                gc.collect()
        
        doc.build(story)
        buffer.seek(0)
        return buffer.getvalue()
    except Exception as e:
        logging.error(f"Error converting summary to PDF: {str(e)}")
        raise
    finally:
        # Clean up resources
        cleanup_resources()
        del story
        gc.collect()

def enrich_summary_with_visuals(summary: dict) -> dict:
    if not summary or not isinstance(summary, dict):
        return summary

    try:
        content = summary.get('content', '')
        if not content:
            return summary

        # Extract keywords with memory limit
        keywords = extract_keywords(content[:50000])  # Limit text analysis
        if not keywords:
            return summary

        # Generate word cloud
        wordcloud = None
        try:
            wordcloud = generate_wordcloud(content[:20000])  # Limit text for wordcloud
        except Exception as e:
            logging.error(f"Error generating wordcloud: {str(e)}")

        # Fetch images
        images = []
        try:
            images = fetch_images_from_multiple_sources(keywords[:3])  # Limit keywords
        except Exception as e:
            logging.error(f"Error fetching images: {str(e)}")

        # Insert visuals
        try:
            enriched_content = insert_visuals_into_summary(content, images, wordcloud)
        except Exception as e:
            logging.error(f"Error inserting visuals: {str(e)}")
            enriched_content = content

        return {
            'title': summary.get('title', ''),
            'content': enriched_content
        }
    except Exception as e:
        logging.error(f"Error in enrich_summary_with_visuals: {str(e)}")
        return summary
    finally:
        cleanup_resources()

# Initialize NLTK data on module load
download_nltk_data()