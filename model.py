from transformers import pipeline, AutoTokenizer, AutoModelForSeq2SeqLM
import torch
import nltk
import logging
from logging.handlers import RotatingFileHandler  # Add this import for logging rotation
from typing import Optional, List, Dict, Union
import os
from dotenv import load_dotenv
import time
import re
from concurrent.futures import ThreadPoolExecutor, as_completed
from threading import Lock
from cachetools import LRUCache
import gc

# Load environment variables
load_dotenv()
HUGGINGFACE_API_KEY = os.getenv('HUGGINGFACE_API_KEY')

# Configure logging with rotation - Fixed configuration
os.makedirs('logs', exist_ok=True)  # Create logs directory if it doesn't exist
logging.basicConfig(level=logging.INFO,
                   format='%(asctime)s - %(levelname)s - %(message)s')

# Add file handler with rotation
file_handler = RotatingFileHandler(
    'logs/summarization.log',
    maxBytes=10485760,  # 10MB
    backupCount=3
)
file_handler.setFormatter(logging.Formatter('%(asctime)s - %(levelname)s - %(message)s'))
logging.getLogger().addHandler(file_handler)

# Memory-efficient NLTK data loading
def load_nltk_data():
    required_data = ['punkt', 'averaged_perceptron_tagger', 'stopwords']
    nltk_data_dir = os.path.expanduser('~/nltk_data')
    os.makedirs(nltk_data_dir, exist_ok=True)
    
    for data in required_data:
        try:
            nltk.data.find(f'tokenizers/{data}')
        except LookupError:
            try:
                nltk.download(data, quiet=True, download_dir=nltk_data_dir)
            except Exception as e:
                logging.error(f"Failed to download NLTK data {data}: {e}")

load_nltk_data()

class SummarizationModel:
    def __init__(self, model_name: str = "facebook/bart-large-cnn"):
        """Initialize the summarization model with memory-optimized parameters."""
        try:
            if HUGGINGFACE_API_KEY:
                os.environ["TRANSFORMERS_TOKEN"] = HUGGINGFACE_API_KEY
            
            self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
            
            # Load tokenizer with optimized settings
            self.tokenizer = AutoTokenizer.from_pretrained(
                model_name,
                model_max_length=1024,
                cache_dir='./model_cache'
            )
            
            # Load model with memory optimizations
            self.model = AutoModelForSeq2SeqLM.from_pretrained(
                model_name,
                torch_dtype=torch.float16 if torch.cuda.is_available() else torch.float32,
                low_cpu_mem_usage=True,
                cache_dir='./model_cache'
            )
            
            # Move model to device and optimize memory
            self.model.to(self.device)
            if torch.cuda.is_available():
                torch.cuda.empty_cache()
            
            # Create pipeline with optimized batch processing
            self.summarizer = pipeline(
                "summarization",
                model=self.model,
                tokenizer=self.tokenizer,
                device=0 if torch.cuda.is_available() else -1,
                framework="pt",
                torch_dtype=torch.float16 if torch.cuda.is_available() else torch.float32,
                batch_size=2  # Reduced batch size for better memory management
            )
            
            # Optimized parameters
            self.max_chunk_size = 512  # Reduced for better memory management
            self.min_chunk_size = 10
            self.batch_size = 2  # Reduced batch size
            self.max_length_ratio = 0.4
            self.min_length_ratio = 0.1
            
            # Thread safety with bounded executor
            self.lock = Lock()
            self.executor = ThreadPoolExecutor(max_workers=2)  # Reduced workers
            
            # Memory-efficient cache with smaller size
            self.cache = LRUCache(maxsize=100)  # Reduced cache size
            
            logging.info(f"Summarization model initialized successfully on {self.device}")
            
        except Exception as e:
            logging.error(f"Error initializing SummarizationModel: {str(e)}")
            raise

    def __del__(self):
        """Cleanup resources properly."""
        try:
            self.executor.shutdown(wait=False)
            if hasattr(self, 'model'):
                del self.model
            if hasattr(self, 'tokenizer'):
                del self.tokenizer
            if hasattr(self, 'summarizer'):
                del self.summarizer
            if torch.cuda.is_available():
                torch.cuda.empty_cache()
            gc.collect()
        except Exception as e:
            logging.error(f"Error in cleanup: {str(e)}")

    def clean_text(self, text: str) -> str:
        """Memory-efficient text cleaning."""
        if not isinstance(text, str):
            return ""
        
        # Process text in chunks for large inputs
        chunk_size = 10000
        if len(text) > chunk_size:
            chunks = [text[i:i+chunk_size] for i in range(0, len(text), chunk_size)]
            cleaned_chunks = []
            for chunk in chunks:
                cleaned_chunk = re.sub(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\xFF]', '', chunk)
                cleaned_chunk = re.sub(r'\s+', ' ', cleaned_chunk)
                cleaned_chunk = ' '.join(word for word in cleaned_chunk.split() if len(word) < 45)
                cleaned_chunk = re.sub(r'([!?,.])\1+', r'\1', cleaned_chunk)
                cleaned_chunks.append(cleaned_chunk.strip())
            return ' '.join(cleaned_chunks)
        
        # Original cleaning for smaller texts
        text = re.sub(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\xFF]', '', text)
        text = re.sub(r'\s+', ' ', text)
        text = ' '.join(word for word in text.split() if len(word) < 45)
        text = re.sub(r'([!?,.])\1+', r'\1', text)
        return text.strip()

    def preprocess_text(self, text: str) -> str:
        """Memory-efficient text preprocessing."""
        try:
            # Process in chunks for very large texts
            if len(text) > 50000:
                chunks = [text[i:i+50000] for i in range(0, len(text), 50000)]
                processed_chunks = []
                for chunk in chunks:
                    processed_chunk = self.clean_text(chunk)
                    processed_chunk = re.sub(r'\n+', '\n', processed_chunk)
                    processed_chunk = re.sub(r'([.!?])\n', r'\1 ', processed_chunk)
                    processed_chunk = re.sub(r'(\w)-\n(\w)', r'\1\2', processed_chunk)
                    processed_chunks.append(processed_chunk)
                return ' '.join(processed_chunks)
            
            # Original preprocessing for smaller texts
            text = self.clean_text(text)
            text = re.sub(r'\n+', '\n', text)
            text = re.sub(r'([.!?])\n', r'\1 ', text)
            text = re.sub(r'(\w)-\n(\w)', r'\1\2', text)
            text = re.sub(r'(?<=[.!?])\s*(?=[A-Z])', ' ', text)
            text = re.sub(r'Page \d+( of \d+)?', '', text)
            text = re.sub(r'^\s*Table of Contents\s*$', '', text, flags=re.MULTILINE)
            
            return text
            
        except Exception as e:
            logging.error(f"Error in preprocess_text: {str(e)}")
            return text

    def optimize_length_params(self, text: str, summary_depth: float = 0.3) -> tuple[int, int]:
        """Memory-efficient parameter optimization."""
        input_length = len(text.split())
        
        # Calculate lengths with memory constraints
        max_length = min(int(input_length * min(summary_depth, self.max_length_ratio)), 512)
        min_length = int(input_length * max(summary_depth * 0.3, self.min_length_ratio))
        
        # Apply stricter bounds
        max_length = min(max(max_length, 20), 512)
        min_length = min(max(min_length, 5), max_length - 5)
        
        return max_length, min_length

    def generate_summary(self, text: str, summary_depth: float = 0.3, mode: str = 'default') -> Optional[str]:
        try:
            start_time = time.time()

            # Memory-efficient preprocessing
            cleaned_text = self.preprocess_text(text)
            if not cleaned_text:
                return "Input text is empty after preprocessing."

            word_count = len(cleaned_text.split())
            if word_count < self.min_chunk_size:
                return cleaned_text

            # Check cache with memory-efficient key
            cache_key = hash(f"{cleaned_text[:50]}_{summary_depth}_{mode}")
            with self.lock:
                cached_result = self.cache.get(cache_key)
                if cached_result:
                    return cached_result

            max_length, min_length = self.optimize_length_params(cleaned_text, summary_depth)

            try:
                # Memory-efficient summary generation
                if mode == 'incremental':
                    with torch.no_grad():
                        summaries = self.summarizer(
                            cleaned_text,
                            max_length=max_length,
                            min_length=min_length,
                            do_sample=True,
                            num_beams=2,  # Reduced for memory
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
                    with torch.no_grad():
                        summary = self.summarizer(
                            cleaned_text,
                            max_length=max_length,
                            min_length=min_length,
                            do_sample=True,
                            num_beams=2,  # Reduced for memory
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

                # Clear CUDA cache after generation
                if torch.cuda.is_available():
                    torch.cuda.empty_cache()

            except Exception as e:
                logging.error(f"Error in summarizer pipeline: {str(e)}")
                result = cleaned_text[:max_length]

            if time.time() - start_time > 60:
                return cleaned_text[:max_length]

            if not result:
                return cleaned_text[:max_length]

            # Memory-efficient post-processing
            result = ' '.join(result.split())
            result = result.replace(' .', '.').replace(' ,', ',')

            # Cache with memory limit
            if len(result) < 10000:  # Only cache reasonably sized results
                with self.lock:
                    self.cache[cache_key] = result

            return result

        except Exception as e:
            logging.error(f"Error in generate_summary: {str(e)}")
            return text[:512]  # Reduced from 1024 for memory
    
    def chunk_text(self, text: str) -> List[str]:
        """Memory-efficient text chunking."""
        try:
            # Process text in smaller batches
            max_text_length = 100000  # Process 100K characters at a time
            if len(text) > max_text_length:
                text_chunks = [text[i:i+max_text_length] for i in range(0, len(text), max_text_length)]
                all_chunks = []
                for text_chunk in text_chunks:
                    chunks = self._process_chunk(text_chunk)
                    all_chunks.extend(chunks)
                return all_chunks
            
            return self._process_chunk(text)
            
        except Exception as e:
            logging.error(f"Error in chunk_text: {str(e)}")
            return [text]

    def _process_chunk(self, text: str) -> List[str]:
        """Helper method for chunk_text to process individual chunks."""
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

    def summarize_long_document(self, text: str, summary_depth: float = 0.3, max_time: int = 300) -> str:
        """Memory-efficient long document summarization."""
        try:
            start_time = time.time()
            
            cleaned_text = self.preprocess_text(text)
            if not cleaned_text:
                return "Empty or invalid document"

            if len(cleaned_text.split()) <= self.max_chunk_size:
                return self.generate_summary(cleaned_text, summary_depth)

            chunks = self.chunk_text(cleaned_text)
            if not chunks:
                return "Unable to process document"

            # Process chunks with memory management
            chunk_summaries = []
            
            with ThreadPoolExecutor(max_workers=2) as executor:  # Reduced workers
                futures = []
                
                for i, chunk in enumerate(chunks):
                    if time.time() - start_time > max_time:
                        break
                    
                    # Process chunks in smaller batches
                    if i > 0 and i % 3 == 0:  # Process 3 chunks at a time
                        torch.cuda.empty_cache() if torch.cuda.is_available() else None
                        gc.collect()
                    
                    future = executor.submit(self.generate_summary, chunk, summary_depth)
                    futures.append(future)
                
                for future in as_completed(futures):
                    if time.time() - start_time > max_time:
                        break
                    try:
                        summary = future.result(timeout=30)
                        if summary and not summary.startswith("Error"):
                            chunk_summaries.append(summary)
                    except Exception as e:
                        logging.error(f"Error processing chunk: {str(e)}")

            # Clear memory after processing
            torch.cuda.empty_cache() if torch.cuda.is_available() else None
            gc.collect()

            # Combine summaries with memory efficiency
            if len(chunk_summaries) > 1:
                combined_text = " ".join(chunk_summaries[:10])  # Limit number of chunks combined
                return self.generate_summary(combined_text, summary_depth)
            elif chunk_summaries:
                return chunk_summaries[0]
            else:
                return "Unable to generate summary"

        except Exception as e:
            logging.error(f"Error in summarize_long_document: {str(e)}")
            return f"Error summarizing document: {str(e)}"
        finally:
            # Ensure memory cleanup
            torch.cuda.empty_cache() if torch.cuda.is_available() else None
            gc.collect()

    def __call__(self, text: str, summary_depth: float = 0.3, mode: str = 'default') -> str:
        """Memory-efficient call method."""
        try:
            # Limit input text size
            max_input_length = 100000  # ~100KB text limit
            if len(text) > max_input_length:
                text = text[:max_input_length]
                logging.warning(f"Input text truncated to {max_input_length} characters")

            word_count = len(text.split())
            if word_count > self.max_chunk_size:
                return self.summarize_long_document(text, summary_depth)
            return self.generate_summary(text, summary_depth, mode)
        except Exception as e:
            logging.error(f"Error in __call__ method: {str(e)}")
            return f"Error summarizing text: {str(e)}"
        finally:
            # Ensure memory cleanup
            torch.cuda.empty_cache() if torch.cuda.is_available() else None
            gc.collect()

# Optimized singleton pattern with proper cleanup
class ModelManager:
    _instance = None
    _lock = Lock()
    
    @classmethod
    def get_model(cls):
        with cls._lock:
            if cls._instance is None:
                cls._instance = SummarizationModel()
            return cls._instance
    
    @classmethod
    def cleanup(cls):
        with cls._lock:
            if cls._instance is not None:
                del cls._instance
                cls._instance = None
                torch.cuda.empty_cache() if torch.cuda.is_available() else None
                gc.collect()

def get_model():
    """Get or create singleton instance with memory management."""
    return ModelManager.get_model()

if __name__ == "__main__":
    try:
        # Test the model with memory monitoring
        model = get_model()
        
        # Monitor initial memory usage
        initial_memory = torch.cuda.memory_allocated() if torch.cuda.is_available() else 0
        logging.info(f"Initial GPU memory usage: {initial_memory / 1024**2:.2f} MB")
        
        sample_texts = [
            "This is a very short text.",
            """
            Artificial intelligence (AI) is intelligence demonstrated by machines, as opposed to natural intelligence displayed by 
            animals including humans. AI research has been defined as the field of study of intelligent agents, which refers to any 
            system that perceives its environment and takes actions that maximize its chance of achieving its goals.
            """,
            # Add a long text here for testing (limited size)
            """
            Artificial intelligence (AI) is intelligence demonstrated by machines, as opposed to natural intelligence displayed by 
            animals including humans. AI research has been defined as the field of study of intelligent agents, which refers to any 
            system that perceives its environment and takes actions that maximize its chance of achieving its goals.
            """ * 4  # Reduced repetitions for memory efficiency
        ]
        
        for i, text in enumerate(sample_texts, 1):
            try:
                print(f"\nTest {i}: {'Short' if len(text.split()) < 50 else 'Medium' if len(text.split()) < 200 else 'Long'} Text")
                print("Input text:")
                print(text[:100] + "..." if len(text) > 100 else text)
                print("\nGenerating summary...")
                
                # Monitor memory before summary
                before_memory = torch.cuda.memory_allocated() if torch.cuda.is_available() else 0
                
                summary = model(text)
                
                # Monitor memory after summary
                after_memory = torch.cuda.memory_allocated() if torch.cuda.is_available() else 0
                
                print("Generated summary:")
                print(summary)
                
                # Log memory usage
                logging.info(f"Memory usage for test {i}: {(after_memory - before_memory) / 1024**2:.2f} MB")
                
                # Clear memory after each test
                torch.cuda.empty_cache() if torch.cuda.is_available() else None
                gc.collect()
                
            except Exception as e:
                print(f"Error during summarization: {str(e)}")
                
    except Exception as e:
        logging.error(f"Error in main: {str(e)}")
    finally:
        # Cleanup resources
        ModelManager.cleanup()