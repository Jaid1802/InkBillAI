import time

class TrOCRWrapper:
    def __init__(self):
        self.is_initialized = False
        self.processor = None
        self.model = None

    def initialize(self):
        start_time = time.time()
        try:
            from transformers import TrOCRProcessor, ViTImageProcessor, RobertaTokenizer, VisionEncoderDecoderModel
            import warnings
            warnings.filterwarnings("ignore")
            
            # Load small handwritten model with explicit sub-processors
            image_processor = ViTImageProcessor.from_pretrained('microsoft/trocr-small-handwritten')
            self.tokenizer = RobertaTokenizer.from_pretrained('microsoft/trocr-small-handwritten')
            self.processor = TrOCRProcessor(image_processor=image_processor, tokenizer=self.tokenizer)
            self.model = VisionEncoderDecoderModel.from_pretrained('microsoft/trocr-small-handwritten')
            self.is_initialized = True
            return time.time() - start_time
        except Exception as e:
            print(f"TrOCR error: {e}. Run: pip install transformers torch torchvision Pillow")
            return -1

    def recognize(self, image_path):
        if not self.is_initialized:
            self.initialize()
            
        start_time = time.time()
        if not self.model:
            return {"text": "", "latency": 0.0, "error": "Model failed to load"}

        try:
            from PIL import Image
            image = Image.open(image_path).convert("RGB")
            pixel_values = self.processor(images=image, return_tensors="pt").pixel_values
            
            generated_ids = self.model.generate(pixel_values, max_new_tokens=50)
            generated_text = self.processor.batch_decode(generated_ids, skip_special_tokens=True)[0]
            
            latency = time.time() - start_time
            return {
                "text": generated_text,
                "latency": latency
            }
        except Exception as e:
            return {"text": "", "latency": time.time() - start_time, "error": str(e)}
