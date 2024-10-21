from transformers import pipeline, AutoTokenizer, AutoModelForSeq2SeqLM
import torch
import nltk
import logging
from typing import Optional, List, Dict, Union
import os
from dotenv import load_dotenv
import time
import re
from concurrent.futures import ThreadPoolExecutor, as_completed
from threading import Lock
from cachetools import LRUCache

# Load environment variables
load_dotenv()
HUGGINGFACE_API_KEY = os.getenv('HUGGINGFACE_API_KEY')

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Download required NLTK data
try:
    nltk.download('punkt', quiet=True)
    nltk.download('averaged_perceptron_tagger', quiet=True)
    nltk.download('stopwords', quiet=True)
    nltk.download('punkt_tab', quiet=True)
    # Verify the downloads
    nltk.data.find('tokenizers/punkt')
    nltk.data.find('tokenizers/punkt_tab')
    nltk.data.find('corpora/stopwords')
except Exception as e:
    logging.warning(f"Failed to download NLTK data: {e}")
    # Create necessary directories and retry download
    try:
        import os
        nltk_data_dir = os.path.expanduser('~/nltk_data')
        os.makedirs(nltk_data_dir, exist_ok=True)
        nltk.download('punkt', quiet=True, download_dir=nltk_data_dir)
        nltk.download('punkt_tab', quiet=True, download_dir=nltk_data_dir)
        nltk.download('stopwords', quiet=True, download_dir=nltk_data_dir)
    except Exception as e:
        logging.error(f"Failed to create NLTK data directory and download data: {e}")

class SummarizationModel:
    def __init__(self, model_name: str = "facebook/bart-large-cnn"):
        # ... (existing code)

    def clean_text(self, text: str) -> str:
        # ... (existing code)

    def preprocess_text(self, text: str) -> str:
        # ... (existing code)

    def optimize_length_params(self, text: str, summary_depth: float = 0.3) -> tuple[int, int]:
        # ... (existing code)

    def generate_summary(self, text: str, summary_depth: float = 0.3, mode: str = 'default') -> Optional[str]:
        try:
            start_time = time.time()

            # Input validation and preprocessing
            cleaned_text = self.preprocess_text(text)
            if not cleaned_text:
                return "Input text is empty after preprocessing."

            word_count = len(cleaned_text.split())
            logging.info(f"Preprocessed text word count: {word_count}")

            if word_count < self.min_chunk_size:
                logging.info(f"Text too short for summarization (word count: {word_count}). Returning as is.")
                return cleaned_text

            # Check cache first
            cache_key = f"{cleaned_text[:100]}_{summary_depth}_{mode}"
            with self.lock:
                cached_result = self.cache.get(cache_key)
                if cached_result:
                    return cached_result

            # Get optimized length parameters
            max_length, min_length = self.optimize_length_params(cleaned_text, summary_depth)
            logging.info(f"Summary parameters - max_length: {max_length}, min_length: {min_length}")

            try:
                # Generate summary with optimized parameters and error handling
                if mode == 'incremental':
                    summaries = self.summarizer(
                        cleaned_text,
                        max_length=max_length,
                        min_length=min_length,
                        do_sample=True,
                        num_beams=4,
                        temperature=0.7,
                        top_k=50,
                        top_p=0.95,
                        early_stopping=True,
                        no_repeat_ngram_size=3,
                        batch_size=self.batch_size,
                        return_text=True,
                        num_return_sequences=1
                    )
                    result = summaries[0]['summary_text']
                else:
                    summary = self.summarizer(
                        cleaned_text,
                        max_length=max_length,
                        min_length=min_length,
                        do_sample=True,
                        num_beams=4,
                        temperature=0.7,
                        top_k=50,
                        top_p=0.95,
                        early_stopping=True,
                        no_repeat_ngram_size=3,
                        batch_size=self.batch_size,
                        return_text=True
                    )
                    if isinstance(summary, list) and len(summary) > 0:
                        result = summary[0].get('summary_text', '').strip()
                    else:
                        result = cleaned_text[:max_length]

            except Exception as e:
                logging.error(f"Error in summarizer pipeline: {str(e)}")
                result = cleaned_text[:max_length]

            # Check timeout
            if time.time() - start_time > 60:  # Timeout after 1 minute
                logging.warning("Summary generation timed out")
                return cleaned_text[:max_length]

            if not result:
                logging.warning("Generated summary is empty")
                return cleaned_text[:max_length]

            # Post-process summary
            result = re.sub(r'\s+', ' ', result)
            result = result.replace(' .', '.').replace(' ,', ',')

            logging.info(f"Summary generated successfully (word count: {len(result.split())})")

            # Cache the result
            with self.lock:
                self.cache[cache_key] = result

            return result

        except Exception as e:
            logging.error(f"Error in generate_summary: {str(e)}")
            return text[:1024]

    def chunk_text(self, text: str) -> List[str]:
        # ... (existing code)

    def summarize_long_document(self, text: str, summary_depth: float = 0.3, max_time: int = 300) -> str:
        # ... (existing code)

    def __call__(self, text: str, summary_depth: float = 0.3, mode: str = 'default') -> str:
        try:
            word_count = len(text.split())
            if word_count > self.max_chunk_size:
                return self.summarize_long_document(text, summary_depth)
            return self.generate_summary(text, summary_depth, mode)
        except Exception as e:
            logging.error(f"Error in __call__ method: {str(e)}")
            return f"Error summarizing text: {str(e)}"

# Singleton instance with thread-safe lazy loading
_model_lock = Lock()
_summarization_model = None

def get_model():
    # ... (existing code)