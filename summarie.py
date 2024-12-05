import os
import logging
from logging.handlers import RotatingFileHandler
import nltk
from nltk.tokenize import word_tokenize
from nltk.corpus import stopwords
from nltk.probability import FreqDist
import string
import re
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import List, Dict, Optional
import time
import gc

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
        nltk.download('punkt', quiet=True)
        nltk.download('stopwords', quiet=True)
    except Exception as e:
        logging.warning(f"Failed to download NLTK data: {e}")

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
                        summary.append({
                            'title': metadata['title'],
                            'content': doc_summary
                        })
                except Exception as e:
                    logging.error(f"Error processing document: {str(e)}")

        return summary

    except Exception as e:
        logging.error(f"Error in generate_summary: {str(e)}")
        return []
    finally:
        gc.collect()

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
