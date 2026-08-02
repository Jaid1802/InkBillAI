import time

class GOTWrapper:
    def __init__(self):
        self.is_initialized = False
        self.model = None
        self.tokenizer = None

    def initialize(self):
        start_time = time.time()
        try:
            from transformers import AutoModel, AutoTokenizer
            import warnings
            warnings.filterwarnings("ignore")

            # GOT-OCR2_0 initialization (Experimental / Fallback)
            model_name = 'stepfun-ai/GOT-OCR2_0'
            self.tokenizer = AutoTokenizer.from_pretrained(model_name, trust_remote_code=True)
            self.model = AutoModel.from_pretrained(
                model_name,
                trust_remote_code=True,
                low_cpu_mem_usage=True,
                device_map='cpu',
                use_safetensors=True,
                pad_token_id=self.tokenizer.eos_token_id
            )
            self.model = self.model.eval()
            self.is_initialized = True
            return time.time() - start_time
        except Exception as e:
            print(f"GOT-OCR2_0 error: {e}. Note: GOT model may require GPU/transformers setup.")
            return -1

    def recognize(self, image_path):
        if not self.is_initialized:
            self.initialize()

        start_time = time.time()
        if not self.model:
            return {"text": "", "latency": 0.0, "error": "Model failed to load"}

        try:
            res = self.model.chat(self.tokenizer, image_path, ocr_type='ocr')
            latency = time.time() - start_time
            return {
                "text": res,
                "latency": latency
            }
        except Exception as e:
            return {"text": "", "latency": time.time() - start_time, "error": str(e)}
