from transformers import pipeline, AutoTokenizer, AutoModelForSeq2SeqLM, AutoModel
import torch
import nltk
import logging
from logging.handlers import RotatingFileHandler  # Added this import
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

# Rest of the code remains exactly the same
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

    # Rest of the methods remain exactly the same

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
    # Test code remains the same