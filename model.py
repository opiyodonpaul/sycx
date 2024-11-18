from transformers import pipeline, AutoTokenizer, AutoModelForSeq2SeqLM, AutoModel
import torch
import nltk
import logging
from logging.handlers import RotatingFileHandler
from typing import Optional, List, Dict, Union
import os
from dotenv import load_dotenv
import time
import re
import psutil
import gc
from concurrent.futures import ThreadPoolExecutor, as_completed
from threading import Lock
from contextlib import contextmanager

# Load environment variables
load_dotenv()
HUGGINGFACE_API_KEY = os.getenv('HUGGINGFACE_API_KEY')
MAX_MEMORY_MB = int(os.getenv('MAX_MEMORY_MB', '512'))

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

class MemoryManager:
    """Manages memory usage and cleanup for the application."""
    
    def __init__(self, threshold_percent: float = 90.0):
        self.threshold_percent = threshold_percent
        self.memory_threshold = (MAX_MEMORY_MB * 1024 * 1024 * threshold_percent) / 100.0
        
    def get_memory_usage(self) -> float:
        """Get current memory usage in bytes."""
        process = psutil.Process(os.getpid())
        return process.memory_info().rss
    
    def check_memory(self) -> bool:
        """Check if memory usage is below threshold."""
        return self.get_memory_usage() < self.memory_threshold
    
    @contextmanager
    def monitor_memory(self, operation_name: str):
        """Context manager to monitor memory usage during operations."""
        start_mem = self.get_memory_usage()
        try:
            yield
        finally:
            end_mem = self.get_memory_usage()
            diff_mem = end_mem - start_mem
            logging.info(
                f"Memory usage for {operation_name}: "
                f"Start: {start_mem/1024/1024:.2f}MB, "
                f"End: {end_mem/1024/1024:.2f}MB, "
                f"Diff: {diff_mem/1024/1024:.2f}MB"
            )
    
    def cleanup(self):
        """Perform memory cleanup operations."""
        gc.collect()
        if torch.cuda.is_available():
            torch.cuda.empty_cache()
            
class ModelCache:
    """Manages model caching and cleanup."""
    
    def __init__(self):
        self.model = None
        self.tokenizer = None
        self.last_used = 0
        self.lock = Lock()
        self.cache_timeout = 300  # 5 minutes
        
    def cleanup_if_stale(self):
        """Clean up model if it hasn't been used recently."""
        if (time.time() - self.last_used) > self.cache_timeout:
            with self.lock:
                if self.model is not None:
                    del self.model
                    del self.tokenizer
                    self.model = None
                    self.tokenizer = None
                    gc.collect()
                    if torch.cuda.is_available():
                        torch.cuda.empty_cache()

class SummarizationModel:
    def __init__(self, model_name: str = "facebook/bart-large-cnn"):
        """Initialize the summarization model with optimized parameters."""
        try:
            self.model_name = model_name
            self.memory_manager = MemoryManager()
            self.model_cache = ModelCache()
            
            # Set device with memory optimization
            if torch.cuda.is_available():
                # Get GPU memory info
                gpu_memory = torch.cuda.get_device_properties(0).total_memory
                if gpu_memory < 4 * 1024 * 1024 * 1024:  # Less than 4GB
                    self.device = torch.device("cpu")
                    logging.info("Using CPU due to limited GPU memory")
                else:
                    self.device = torch.device("cuda")
            else:
                self.device = torch.device("cpu")
            
            # Optimize chunk sizes based on available memory
            self.max_chunk_size = min(1024, MAX_MEMORY_MB // 2)
            self.min_chunk_size = 10
            self.batch_size = 2 if torch.cuda.is_available() else 1
            
            # Initialize NLTK data with error handling and cleanup
            with self.memory_manager.monitor_memory("NLTK Download"):
                for resource in ['punkt', 'averaged_perceptron_tagger', 'stopwords']:
                    try:
                        nltk.download(resource, quiet=True)
                    except Exception as e:
                        logging.warning(f"Failed to download NLTK resource {resource}: {e}")
            
            self.lock = Lock()
            self.executor = ThreadPoolExecutor(max_workers=2)  # Reduced workers
            
            logging.info(f"Summarization model initialized on {self.device}")
            
        except Exception as e:
            logging.error(f"Error initializing SummarizationModel: {str(e)}")
            raise

    def _load_model(self):
        """Lazy load model with memory optimization."""
        if self.model_cache.model is None:
            with self.memory_manager.monitor_memory("Model Loading"):
                # Set Hugging Face token
                if HUGGINGFACE_API_KEY:
                    os.environ["TRANSFORMERS_TOKEN"] = HUGGINGFACE_API_KEY
                
                # Load with optimized settings
                self.model_cache.tokenizer = AutoTokenizer.from_pretrained(
                    self.model_name,
                    token=HUGGINGFACE_API_KEY,
                    model_max_length=self.max_chunk_size
                )
                
                self.model_cache.model = AutoModelForSeq2SeqLM.from_pretrained(
                    self.model_name,
                    token=HUGGINGFACE_API_KEY,
                    torch_dtype=torch.float16 if torch.cuda.is_available() else torch.float32,
                    low_cpu_mem_usage=True
                ).to(self.device)
                
                # Create pipeline with memory optimizations
                self.summarizer = pipeline(
                    "summarization",
                    model=self.model_cache.model,
                    tokenizer=self.model_cache.tokenizer,
                    device=0 if torch.cuda.is_available() else -1,
                    framework="pt",
                    torch_dtype=torch.float16 if torch.cuda.is_available() else torch.float32,
                    batch_size=self.batch_size
                )
                
                self.model_cache.last_used = time.time()

    def clean_text(self, text: str) -> str:
        """Memory-efficient text cleaning."""
        if not isinstance(text, str):
            return ""
        
        with self.memory_manager.monitor_memory("Text Cleaning"):
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
        """Memory-efficient text preprocessing."""
        try:
            with self.memory_manager.monitor_memory("Text Preprocessing"):
                # Basic cleaning
                text = self.clean_text(text)
                
                # Remove unnecessary line breaks while preserving paragraph structure
                text = re.sub(r'\n+', '\n', text)
                text = re.sub(r'([.!?])\n', r'\1 ', text)
                
                # Handle common PDF artifacts
                text = re.sub(r'(\w)-\n(\w)', r'\1\2', text)
                text = re.sub(r'(?<=[.!?])\s*(?=[A-Z])', ' ', text)
                
                # Remove redundant information
                text = re.sub(r'Page \d+( of \d+)?', '', text)
                text = re.sub(r'^\s*Table of Contents\s*$', '', text, flags=re.MULTILINE)
                
                return text
                
        except Exception as e:
            logging.error(f"Error in preprocess_text: {str(e)}")
            return text

    def optimize_length_params(self, text: str, summary_depth: float = 0.3) -> tuple[int, int]:
        """Memory-aware parameter optimization."""
        with self.memory_manager.monitor_memory("Length Parameter Optimization"):
            input_length = len(text.split())
            
            # Calculate base lengths using summary_depth
            max_length = min(
                int(input_length * min(summary_depth, 0.4)),
                self.max_chunk_size
            )
            min_length = int(max_length * 0.3)
            
            # Apply constraints
            max_length = min(max(max_length, 20), self.max_chunk_size)
            min_length = min(max(min_length, 5), max_length - 5)
            
            return max_length, min_length

    def generate_summary(self, text: str, summary_depth: float = 0.3, timeout: int = 30) -> Optional[str]:
        """Generate summary with memory management and optimization."""
        try:
            start_time = time.time()
            
            with self.lock:
                with self.memory_manager.monitor_memory("Summary Generation"):
                    # Load model if needed
                    self._load_model()
                    
                    # Input validation and preprocessing
                    cleaned_text = self.preprocess_text(text)
                    if not cleaned_text:
                        return "Input text is empty after preprocessing."
                    
                    word_count = len(cleaned_text.split())
                    if word_count < self.min_chunk_size:
                        return cleaned_text
                    
                    # Get optimized length parameters
                    max_length, min_length = self.optimize_length_params(cleaned_text, summary_depth)
                    
                    # Generate summary with optimized parameters
                    summary = self.summarizer(
                        cleaned_text,
                        max_length=max_length,
                        min_length=min_length,
                        do_sample=True,
                        num_beams=2,  # Reduced for memory optimization
                        temperature=0.7,
                        top_k=50,
                        top_p=0.95,
                        early_stopping=True,
                        no_repeat_ngram_size=3,
                        batch_size=self.batch_size
                    )
                    
                    # Check timeout
                    if time.time() - start_time > timeout:
                        return cleaned_text[:max_length]
                    
                    result = summary[0]['summary_text'].strip()
                    
                    # Clean up memory
                    self.memory_manager.cleanup()
                    
                    return result if result else cleaned_text[:max_length]

        except Exception as e:
            logging.error(f"Error in generate_summary: {str(e)}")
            return f"Error generating summary: {str(e)}"

    def chunk_text(self, text: str) -> List[str]:
        """Memory-efficient text chunking."""
        try:
            with self.memory_manager.monitor_memory("Text Chunking"):
                sentences = nltk.sent_tokenize(text)
                chunks = []
                current_chunk = []
                current_length = 0
                
                for sentence in sentences:
                    sentence_length = len(self.model_cache.tokenizer.encode(sentence))
                    
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
        """Handle long documents with memory optimization."""
        try:
            start_time = time.time()
            
            with self.memory_manager.monitor_memory("Long Document Summarization"):
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
                
                with ThreadPoolExecutor(max_workers=2) as executor:
                    for chunk in chunks:
                        if time.time() - start_time > max_time:
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

                # Clean up between stages
                self.memory_manager.cleanup()

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

    def __call__(self, text: str, summary_depth: float = 0.3) -> str:
        """Memory-optimized call method."""
        try:
            with self.memory_manager.monitor_memory("Model Call"):
                word_count = len(text.split())
                if word_count > self.max_chunk_size:
                    return self.summarize_long_document(text, summary_depth)
                return self.generate_summary(text, summary_depth)
        finally:
            # Cleanup stale model cache
            self.model_cache.cleanup_if_stale()

# Singleton instance with memory-aware lazy loading
_model_lock = Lock()
_summarization_model = None

def get_model():
    """Get or create singleton instance of SummarizationModel with memory optimization."""
    global _summarization_model
    with _model_lock:
        if _summarization_model is None:
            try:
                _summarization_model = SummarizationModel()
            except Exception as e:
                logging.error(f"Error creating summarization model: {str(e)}")
                raise
        return _summarization_model

if __name__ == "__main__":
    # Test the model with sample texts of varying lengths
    try:
        model = get_model()
        memory_manager = MemoryManager()
        
        sample_texts = [
            "This is a very short text.",
            """
            Artificial intelligence (AI) is intelligence demonstrated by machines, as opposed to natural intelligence displayed by 
            animals including humans. AI research has been defined as the field of study of intelligent agents, which refers to any 
            system that perceives its environment and takes actions that maximize its chance of achieving its goals.
            """,
            # Add a long text here for testing, e.g., a few paragraphs or more
            "This is a very long text.",
            """
            Artificial intelligence (AI) is intelligence demonstrated by machines, as opposed to natural intelligence displayed by 
            animals including humans. AI research has been defined as the field of study of intelligent agents, which refers to any 
            system that perceives its environment and takes actions that maximize its chance of achieving its goals.
            Artificial intelligence (AI) is intelligence demonstrated by machines, as opposed to natural intelligence displayed by 
            animals including humans. AI research has been defined as the field of study of intelligent agents, which refers to any 
            system that perceives its environment and takes actions that maximize its chance of achieving its goals.
            Artificial intelligence (AI) is intelligence demonstrated by machines, as opposed to natural intelligence displayed by 
            animals including humans. AI research has been defined as the field of study of intelligent agents, which refers to any 
            system that perceives its environment and takes actions that maximize its chance of achieving its goals.
            Artificial intelligence (AI) is intelligence demonstrated by machines, as opposed to natural intelligence displayed by 
            animals including humans. AI research has been defined as the field of study of intelligent agents, which refers to any 
            system that perceives its environment and takes actions that maximize its chance of achieving its goals.
            Artificial intelligence (AI) is intelligence demonstrated by machines, as opposed to natural intelligence displayed by 
            animals including humans. AI research has been defined as the field of study of intelligent agents, which refers to any 
            system that perceives its environment and takes actions that maximize its chance of achieving its goals.
            Artificial intelligence (AI) is intelligence demonstrated by machines, as opposed to natural intelligence displayed by 
            animals including humans. AI research has been defined as the field of study of intelligent agents, which refers to any 
            system that perceives its environment and takes actions that maximize its chance of achieving its goals.
            Artificial intelligence (AI) is intelligence demonstrated by machines, as opposed to natural intelligence displayed by 
            animals including humans. AI research has been defined as the field of study of intelligent agents, which refers to any 
            system that perceives its environment and takes actions that maximize its chance of achieving its goals.
            Artificial intelligence (AI) is intelligence demonstrated by machines, as opposed to natural intelligence displayed by 
            animals including humans. AI research has been defined as the field of study of intelligent agents, which refers to any 
            system that perceives its environment and takes actions that maximize its chance of achieving its goals.
            """,
        ]
        
        for i, text in enumerate(sample_texts, 1):
            try:
                print(f"\nTest {i}: {'Short' if len(text.split()) < 50 else 'Medium' if len(text.split()) < 200 else 'Long'} Text")
                print("Input text:")
                print(text[:100] + "..." if len(text) > 100 else text)
                print("\nGenerating summary...")
                
                # Monitor memory during summary generation
                with memory_manager.monitor_memory(f"Test {i} Summary"):
                    summary = model(text)
                    print("Generated summary:")
                    print(summary)
                    
                # Clean up after each test
                memory_manager.cleanup()
                
            except Exception as e:
                print(f"Error during summarization test {i}: {str(e)}")
                continue
            
    except Exception as e:
        print(f"Error during testing: {str(e)}")
    finally:
        # Final cleanup
        if 'model' in locals():
            model.memory_manager.cleanup()