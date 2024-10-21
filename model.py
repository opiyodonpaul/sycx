from transformers import pipeline, AutoTokenizer, AutoModelForSeq2SeqLM
import torch
import nltk
import logging
from typing import Optional, List, Dict, Union
import os
from python_dotenv import load_dotenv
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
    nltk.download('punkt_tab', quiet=True)  # Add this line
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
        """Initialize the summarization model with specified parameters."""
        try:
            # Set Hugging Face API token
            if HUGGINGFACE_API_KEY:
                os.environ["TRANSFORMERS_TOKEN"] = HUGGINGFACE_API_KEY
            
            # Check for CUDA availability and set appropriate device
            self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
            
            # Load tokenizer and model
            self.tokenizer = AutoTokenizer.from_pretrained(model_name)
            self.model = AutoModelForSeq2SeqLM.from_pretrained(model_name)
            
            # Move model to appropriate device
            self.model.to(self.device)
            
            # Create pipeline with optimized settings
            self.summarizer = pipeline(
                "summarization",
                model=self.model,
                tokenizer=self.tokenizer,
                device=0 if torch.cuda.is_available() else -1,
                framework="pt",
                torch_dtype=torch.float16 if torch.cuda.is_available() else torch.float32
            )
            
            # Enhanced settings for better performance
            self.max_chunk_size = 1024
            self.min_chunk_size = 10  # Lowered to handle very short texts
            self.batch_size = 4 if torch.cuda.is_available() else 1
            self.max_length_ratio = 0.4
            self.min_length_ratio = 0.1
            
            # Thread safety
            self.lock = Lock()
            self.executor = ThreadPoolExecutor(max_workers=3)
            
            # Caching
            self.cache = LRUCache(maxsize=1000)
            
            logging.info(f"Summarization model initialized successfully on {self.device}")
            
        except Exception as e:
            logging.error(f"Error initializing SummarizationModel: {str(e)}")
            raise

    def clean_text(self, text: str) -> str:
        """Enhanced text cleaning with advanced filtering."""
        if not isinstance(text, str):
            return ""
        
        # Remove special characters and normalize whitespace
        text = re.sub(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\xFF]', '', text)
        text = re.sub(r'\s+', ' ', text)
        
        # Remove very long strings that are likely garbage
        text = ' '.join(word for word in text.split() if len(word) < 45)
        
        # Remove repeated punctuation
        text = re.sub(r'([!?,.])\1+', r'\1', text)
        
        # Remove extra whitespace
        text = text.strip()
        
        return text

    def preprocess_text(self, text: str) -> str:
        """Comprehensive text preprocessing pipeline."""
        try:
            # Basic cleaning
            text = self.clean_text(text)
            
            # Remove unnecessary line breaks while preserving paragraph structure
            text = re.sub(r'\n+', '\n', text)
            text = re.sub(r'([.!?])\n', r'\1 ', text)
            
            # Handle common PDF artifacts
            text = re.sub(r'(\w)-\n(\w)', r'\1\2', text)  # Fix hyphenation
            text = re.sub(r'(?<=[.!?])\s*(?=[A-Z])', ' ', text)  # Fix sentence spacing
            
            # Remove redundant information
            text = re.sub(r'Page \d+( of \d+)?', '', text)
            text = re.sub(r'^\s*Table of Contents\s*$', '', text, flags=re.MULTILINE)
            
            return text
            
        except Exception as e:
            logging.error(f"Error in preprocess_text: {str(e)}")
            return text

    def optimize_length_params(self, text: str, summary_depth: float = 0.3) -> tuple[int, int]:
        """Dynamically optimize summary length parameters based on input characteristics."""
        input_length = len(text.split())
        
        # Calculate base lengths using summary_depth
        max_length = int(input_length * min(summary_depth, self.max_length_ratio))
        min_length = int(input_length * max(summary_depth * 0.3, self.min_length_ratio))
        
        # Apply constraints
        max_length = min(max(max_length, 20), 1024)  # Ensure reasonable bounds
        min_length = min(max(min_length, 5), max_length - 5)
        
        return max_length, min_length

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
        """Improved text chunking with sentence boundary preservation."""
        try:
            sentences = nltk.sent_tokenize(text)
            chunks = []
            current_chunk = []
            current_length = 0
            
            for sentence in sentences:
                sentence_length = len(self.tokenizer.encode(sentence))
                
                if current_length + sentence_length > self.max_chunk_size:
                    if current_chunk:
                        chunks.append(' '.join(current_chunk))
                        current_chunk = []
                        current_length = 0
                
                current_chunk.append(sentence)
                current_length += sentence_length
            
            if current_chunk:
                chunks.append(' '.join(current_chunk))
            
            return chunks
            
        except Exception as e:
            logging.error(f"Error in chunk_text: {str(e)}")
            return [text]

    def summarize_long_document(self, text: str, summary_depth: float = 0.3, max_time: int = 300) -> str:
        """Handle long documents with improved chunking and multi-stage summarization."""
        try:
            start_time = time.time()
            
            # Preprocess the entire document
            cleaned_text = self.preprocess_text(text)
            if not cleaned_text:
                return "Empty or invalid document"

            # For shorter texts, summarize directly
            if len(cleaned_text.split()) <= self.max_chunk_size:
                return self.generate_summary(cleaned_text, summary_depth)

            # For long texts, use multi-stage summarization
            chunks = self.chunk_text(cleaned_text)
            if not chunks:
                return "Unable to process document"

            # First stage: Summarize each chunk
            chunk_summaries = []
            futures = []
            
            with ThreadPoolExecutor() as executor:
                for chunk in chunks:
                    if time.time() - start_time > max_time:
                        logging.warning("Document summarization timed out")
                        break
                    
                    future = executor.submit(self.generate_summary, chunk, summary_depth)
                    futures.append(future)
                
                # Collect results
                for future in as_completed(futures):
                    if time.time() - start_time > max_time:
                        break
                    try:
                        summary = future.result(timeout=30)
                        if summary and not summary.startswith("Error"):
                            chunk_summaries.append(summary)
                    except Exception as e:
                        logging.error(f"Error processing chunk: {str(e)}")

            # Second stage: Combine and summarize again if needed
            if len(chunk_summaries) > 1:
                combined_text = " ".join(chunk_summaries)
                return self.generate_summary(combined_text, summary_depth)
            elif chunk_summaries:
                return chunk_summaries[0]
            else:
                return "Unable to generate summary"

        except Exception as e:
            logging.error(f"Error in summarize_long_document: {str(e)}")
            return f"Error summarizing document: {str(e)}"

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
    """Get or create singleton instance of SummarizationModel with thread safety."""
    global _summarization_model
    with _model_lock:
        if _summarization_model is None:
            _summarization_model = SummarizationModel()
        return _summarization_model

if __name__ == "__main__":
    # Test the model with sample texts of varying lengths
    model = get_model()
    
    sample_texts = [
        "This is a very short text.",
        """
        Artificial intelligence (AI) is intelligence demonstrated by machines, as opposed to natural intelligence displayed by 
        animals including humans. AI research has been defined as the field of study of intelligent agents, which refers to any 
        system that perceives its environment and takes actions that maximize its chance of achieving its goals.
        """,
        # Add a long text here for testing
        """
        Artificial intelligence (AI) is intelligence demonstrated by machines, as opposed to natural intelligence displayed by 
        animals including humans. AI research has been defined as the field of study of intelligent agents, which refers to any 
        system that perceives its environment and takes actions that maximize its chance of achieving its goals.
        """ * 8  # Repeat the text 8 times to create a long document
    ]
    
    for i, text in enumerate(sample_texts, 1):
        try:
            print(f"\nTest {i}: {'Short' if len(text.split()) < 50 else 'Medium' if len(text.split()) < 200 else 'Long'} Text")
            print("Input text:")
            print(text[:100] + "..." if len(text) > 100 else text)
            print("\nGenerating summary...")
            summary = model(text)
            print("Generated summary:")
            print(summary)
        except Exception as e:
            print(f"Error during summarization: {str(e)}")