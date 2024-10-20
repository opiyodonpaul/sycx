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

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Ensure NLTK data is downloaded
try:
    nltk.data.find('tokenizers/punkt')
    nltk.data.find('corpora/stopwords')
except LookupError:
    try:
        nltk.download('punkt', quiet=True)
        nltk.download('stopwords', quiet=True)
    except Exception as e:
        logging.warning(f"Failed to download NLTK data: {e}")

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

def summarize_documents(model, documents, merge_summaries, summary_depth, language, progress_callback):
    try:
        total_docs = len(documents)
        if total_docs == 0:
            raise ValueError("No documents provided")

        progress_per_doc = 100 / total_docs if not merge_summaries else 100

        if merge_summaries:
            merged_content = "\n\n".join([doc['content'] for doc in documents])
            summary = model(merged_content, summary_depth)
            progress_callback(100)
            return [{'title': 'Merged Summary', 'content': format_summary(summary)}]
        else:
            summaries = []
            for doc_index, doc in enumerate(documents):
                doc_summary = model(doc['content'], summary_depth)
                summaries.append({
                    'title': doc['name'],
                    'content': format_summary(doc_summary)
                })
                progress = min(100, ((doc_index + 1) / total_docs) * 100)
                progress_callback(progress)
            
            return summaries

    except Exception as e:
        logging.error(f"Error in summarize_documents: {str(e)}")
        raise

def format_summary(summary):
    try:
        paragraphs = summary.split('\n\n')
        formatted_paragraphs = []
        
        for i, paragraph in enumerate(paragraphs):
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
        raise

def extract_keywords(text):
    try:
        tokens = word_tokenize(text.lower())
        tokens = [word for word in tokens if word.isalnum()]
        stop_words = set(stopwords.words('english') + list(string.punctuation))
        filtered_tokens = [word for word in tokens if word not in stop_words]

        fdist = FreqDist(filtered_tokens)
        
        keywords = [word for word, freq in fdist.most_common(5)]
        
        return keywords
    except Exception as e:
        logging.error(f"Error in extract_keywords: {str(e)}")
        return []

def enrich_summary_with_visuals(summary):
    try:
        keywords = extract_keywords(summary['content'])
        images = fetch_images_from_multiple_sources(keywords)
        wordcloud = generate_wordcloud(summary['content'])
        
        enriched_summary = insert_visuals_into_summary(summary['content'], images, wordcloud)
        
        return {
            'title': summary['title'],
            'content': enriched_summary
        }
    except Exception as e:
        logging.error(f"Error in enrich_summary_with_visuals: {str(e)}")
        return summary

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
    try:
        response = requests.get(f'https://api.unsplash.com/photos/random?query={keyword}&client_id={os.getenv("UNSPLASH_ACCESS_KEY")}')
        if response.status_code == 200:
            return [response.json()['urls']['small']]
        return []
    except Exception as e:
        logging.error(f"Error fetching image from Unsplash: {str(e)}")
        return []

def fetch_image_pexels(keyword):
    try:
        headers = {
            'Authorization': os.getenv("PEXELS_API_KEY")
        }
        response = requests.get(f'https://api.pexels.com/v1/search?query={keyword}&per_page=1', headers=headers)
        if response.status_code == 200:
            data = response.json()
            if data['photos']:
                return [data['photos'][0]['src']['small']]
        return []
    except Exception as e:
        logging.error(f"Error fetching image from Pexels: {str(e)}")
        return []

def fetch_image_pixabay(keyword):
    try:
        response = requests.get(f'https://pixabay.com/api/?key={os.getenv("PIXABAY_API_KEY")}&q={keyword}&image_type=photo&per_page=1')
        if response.status_code == 200:
            data = response.json()
            if data['hits']:
                return [data['hits'][0]['webformatURL']]
        return []
    except Exception as e:
        logging.error(f"Error fetching image from Pixabay: {str(e)}")
        return []

def generate_wordcloud(text):
    try:
        wordcloud = WordCloud(width=800, height=400, background_color='white').generate(text)
        plt.figure(figsize=(10, 5))
        plt.imshow(wordcloud, interpolation='bilinear')
        plt.axis('off')
        img_buffer = BytesIO()
        plt.savefig(img_buffer, format='png')
        plt.close()
        img_buffer.seek(0)
        img_str = base64.b64encode(img_buffer.getvalue()).decode()
        return f"data:image/png;base64,{img_str}"
    except Exception as e:
        logging.error(f"Error generating word cloud: {str(e)}")
        return None

def insert_visuals_into_summary(summary, images, wordcloud):
    try:
        paragraphs = summary.split('\n\n')
        enriched_paragraphs = []
        
        if wordcloud:
            enriched_paragraphs.append(f'![Word Cloud]({wordcloud})')
        
        for i, paragraph in enumerate(paragraphs):
            enriched_paragraphs.append(paragraph)
            
            if i < len(images):
                enriched_paragraphs.append(f'\n![Image related to {paragraph[:30]}...]({images[i]})\n')
        
        return '\n\n'.join(enriched_paragraphs)
    except Exception as e:
        logging.error(f"Error in insert_visuals_into_summary: {str(e)}")
        raise

def convert_summary_to_pdf(summary_content):
    try:
        buffer = BytesIO()
        doc = SimpleDocTemplate(buffer, pagesize=letter,
                                rightMargin=72, leftMargin=72,
                                topMargin=72, bottomMargin=18)
        
        styles = getSampleStyleSheet()
        styles.add(ParagraphStyle(name='Justify', alignment=4))
        
        story = []
        
        html = markdown.markdown(summary_content)
        
        paragraphs = re.split('<h[1-6]>|</h[1-6]>|<p>|</p>', html)
        paragraphs = [p.strip() for p in paragraphs if p.strip()]
        
        for para in paragraphs:
            if para.startswith('!['):
                img_src = re.search(r'\((.*?)\)', para).group(1)
                if img_src.startswith('data:image/png;base64,'):
                    img_data = base64.b64decode(img_src.split(',')[1])
                    img = ImageReader(BytesIO(img_data))
                else:
                    img = ImageReader(requests.get(img_src, stream=True).raw)
                img_width, img_height = img.getSize()
                aspect = img_height / float(img_width)
                img_width = 6 * inch
                img_height = aspect * img_width
                story.append(ReportLabImage(img, width=img_width, height=img_height))
            else:
                story.append(Paragraph(para, styles['Justify']))
            story.append(Spacer(1, 12))
        
        doc.build(story)
        buffer.seek(0)
        return buffer.getvalue()
    except Exception as e:
        logging.error(f"Error converting summary to PDF: {str(e)}")
        raise