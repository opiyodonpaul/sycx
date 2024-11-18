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
            'logs/summary.log',
            maxBytes=1024 * 1024,
            backupCount=3
        ),
        logging.StreamHandler()
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
                f"Start: {start_mem / 1024 / 1024:.2f}MB, "
                f"End: {end_mem / 1024 / 1024:.2f}MB, "
                f"Diff: {diff_mem / 1024 / 1024:.2f}MB"
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
            self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

            self.tokenizer = AutoTokenizer.from_pretrained(model_name, token=HUGGINGFACE_API_KEY)
            self.model = AutoModelForSeq2SeqLM.from_pretrained(model_name, token=HUGGINGFACE_API_KEY)
            self.model.to(self.device)

            self.summarizer = pipeline(
                "summarization",
                model=self.model,
                tokenizer=self.tokenizer,
                device=0 if torch.cuda.is_available() else -1,
                framework="pt",
                torch_dtype=torch.float16 if torch.cuda.is_available() else torch.float32
            )

            self.max_chunk_size = 1024
            self.min_chunk_size = 10
            self.batch_size = 4 if torch.cuda.is_available() else 1
            self.max_length_ratio = 0.4
            self.min_length_ratio = 0.1
            self.lock = Lock()
            self.executor = ThreadPoolExecutor(max_workers=3)

            nltk.download('punkt', quiet=True)
            nltk.download('averaged_perceptron_tagger', quiet=True)
            nltk.download('stopwords', quiet=True)
            
            logging.info(f"Summarization model initialized successfully on {self.device}")
        except Exception as e:
            logging.error(f"Error initializing SummarizationModel: {str(e)}")
            raise

    def clean_text(self, text: str) -> str:
        """Enhanced text cleaning with advanced filtering."""
        if not isinstance(text, str):
            return ""
        text = re.sub(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\xFF]', '', text)
        text = re.sub(r'\s+', ' ', text)
        text = ' '.join(word for word in text.split() if len(word) < 45)
        text = re.sub(r'([!?,.])\1+', r'\1', text)
        text = text.strip()
        return text

    def preprocess_text(self, text: str) -> str:
        """Comprehensive text preprocessing pipeline."""
        try:
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
        """Dynamically optimize summary length parameters based on input characteristics."""
        input_length = len(text.split())
        max_length = int(input_length * min(summary_depth, self.max_length_ratio))
        min_length = int(input_length * max(summary_depth * 0.3, self.min_length_ratio))
        max_length = min(max(max_length, 20), 1024)
        min_length = min(max(min_length, 5), max_length - 5)
        return max_length, min_length

    def generate_summary(self, text: str, summary_depth: float = 0.3, timeout: int = 30) -> Optional[str]:
        """Generate a summary with enhanced error handling and timeout protection."""
        try:
            start_time = time.time()
            with self.lock:
                cleaned_text = self.preprocess_text(text)
                if not cleaned_text:
                    return "Input text is empty after preprocessing."
                word_count = len(cleaned_text.split())
                if word_count < self.min_chunk_size:
                    return cleaned_text
                max_length, min_length = self.optimize_length_params(cleaned_text, summary_depth)
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
                    batch_size=self.batch_size
                )
                if time.time() - start_time > timeout:
                    return cleaned_text[:max_length]
                result = summary[0]['summary_text'].strip()
                return re.sub(r'\s+', ' ', result).replace(' .', '.').replace(' ,', ',')
        except Exception as e:
            logging.error(f"Error in generate_summary: {str(e)}")
            return f"Error generating summary: {str(e)}"

    def chunk_text(self, text: str) -> List[str]:
        """Improved text chunking with sentence boundary preservation."""
        try:
            sentences = nltk.sent_tokenize(text)
            chunks, current_chunk, current_length = [], [], 0
            for sentence in sentences:
                sentence_length = len(self.tokenizer.encode(sentence))
                if current_length + sentence_length > self.max_chunk_size:
                    if current_chunk:
                        chunks.append(' '.join(current_chunk))
                        current_chunk, current_length = [], 0
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
            cleaned_text = self.preprocess_text(text)
            if not cleaned_text:
                return "Empty or invalid document"
            if len(cleaned_text.split()) <= self.max_chunk_size:
                return self.generate_summary(cleaned_text, summary_depth)
            chunks = self.chunk_text(cleaned_text)
            if not chunks:
                return "Unable to process document"
            chunk_summaries = []
            with ThreadPoolExecutor() as executor:
                futures = [executor.submit(self.generate_summary, chunk, summary_depth) for chunk in chunks]
                for future in as_completed(futures):
                    if time.time() - start_time > max_time:
                        break
                    summary = future.result(timeout=30)
                    if summary and not summary.startswith("Error"):
                        chunk_summaries.append(summary)
            if len(chunk_summaries) > 1:
                return self.generate_summary(" ".join(chunk_summaries), summary_depth)
            elif chunk_summaries:
                return chunk_summaries[0]
            else:
                return "Unable to generate summary"
        except Exception as e:
            logging.error(f"Error in summarize_long_document: {str(e)}")
            return f"Error summarizing document: {str(e)}"

    def __call__(self, text: str, summary_depth: float = 0.3) -> str:
        """Enhanced call method with automatic handling of document length."""
        word_count = len(text.split())
        if word_count > self.max_chunk_size:
            return self.summarize_long_document(text, summary_depth)
        return self.generate_summary(text, summary_depth)

# Singleton instance creation
_model_lock = Lock()
_summarization_model = None

def get_model():
    """Get or create singleton instance of SummarizationModel."""
    global _summarization_model
    with _model_lock:
        if _summarization_model is None:
            _summarization_model = SummarizationModel()
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
            # Add a more substantial long text for testing
            """
            Artificial intelligence (AI) is a rapidly evolving field of computer science that aims to create intelligent machines 
            that can perform tasks that typically require human intelligence. These tasks include learning, problem-solving, 
            perception, language understanding, and decision-making. AI has numerous applications across various domains, 
            from healthcare and finance to transportation and entertainment.

            Machine learning, a subset of AI, focuses on developing algorithms that can learn from and make predictions or decisions 
            based on data. Deep learning, a more advanced approach within machine learning, uses artificial neural networks inspired 
            by the human brain's structure. These networks can process complex patterns and make sophisticated predictions.

            In recent years, AI has made significant breakthroughs in areas like natural language processing, computer vision, 
            and robotics. Technologies like ChatGPT demonstrate the potential of large language models to generate human-like text, 
            while AI-powered image recognition systems can identify objects and faces with remarkable accuracy.

            However, the rapid advancement of AI also raises important ethical and societal questions. Concerns about privacy, 
            job displacement, bias in AI algorithms, and the potential long-term implications of artificial general intelligence 
            are topics of ongoing debate among researchers, policymakers, and the public.
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