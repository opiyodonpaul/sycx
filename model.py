import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
from transformers import T5Tokenizer, T5ForConditionalGeneration
import torch
from nltk.tokenize import sent_tokenize
import nltk
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Ensure NLTK data is downloaded
try:
    nltk.data.find('tokenizers/punkt')
except LookupError:
    nltk.download('punkt', quiet=True)

class SummarizationModel:
    def __init__(self):
        try:
            self.tokenizer = T5Tokenizer.from_pretrained('t5-small')
            self.model = T5ForConditionalGeneration.from_pretrained('t5-small')
            self.device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
            self.model.to(self.device)
            self.vectorizer = TfidfVectorizer()
        except Exception as e:
            logging.error(f"Error initializing SummarizationModel: {str(e)}")
            raise

    def generate_summary(self, text, max_length=150, min_length=40):
        try:
            inputs = self.tokenizer.encode("summarize: " + text, return_tensors='pt', max_length=512, truncation=True)
            inputs = inputs.to(self.device)
            
            summary_ids = self.model.generate(inputs, max_length=max_length, min_length=min_length, length_penalty=2.0, num_beams=4, early_stopping=True)
            summary = self.tokenizer.decode(summary_ids[0], skip_special_tokens=True)
            
            return summary
        except Exception as e:
            logging.error(f"Error in generate_summary: {str(e)}")
            return "Error generating summary"

    def improve_model(self, original_text, original_summary, feedback):
        try:
            # Tokenize the original text and summary
            original_sentences = sent_tokenize(original_text)
            summary_sentences = sent_tokenize(original_summary)
            
            # Vectorize sentences
            all_sentences = original_sentences + summary_sentences
            sentence_vectors = self.vectorizer.fit_transform(all_sentences)
            
            # Calculate similarity between each original sentence and the summary
            similarities = cosine_similarity(sentence_vectors[:len(original_sentences)], sentence_vectors[len(original_sentences):])
            
            # Find sentences that were not well represented in the summary
            underrepresented_sentences = [sent for i, sent in enumerate(original_sentences) if np.max(similarities[i]) < 0.3]
            
            # Create a new training example
            new_input = "summarize: " + " ".join(underrepresented_sentences)
            new_target = feedback
            
            # Fine-tune the model on this new example
            inputs = self.tokenizer(new_input, return_tensors="pt", max_length=512, truncation=True)
            targets = self.tokenizer(new_target, return_tensors="pt", max_length=150, truncation=True)
            
            inputs = inputs.to(self.device)
            targets = targets.to(self.device)
            
            self.model.train()
            outputs = self.model(**inputs, labels=targets["input_ids"])
            loss = outputs.loss
            loss.backward()
            
            # Update model parameters
            optimizer = torch.optim.Adam(self.model.parameters(), lr=1e-5)
            optimizer.step()
            
            logging.info(f"Model improved based on feedback. Loss: {loss.item()}")
        except Exception as e:
            logging.error(f"Error in improve_model: {str(e)}")

summarization_model = SummarizationModel()

def get_model():
    return summarization_model