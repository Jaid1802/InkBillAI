import time

class PaddleWrapper:
    def __init__(self):
        self.is_initialized = False
        self.model = None

    def initialize(self, lang='en'):
        start_time = time.time()
        try:
            from paddleocr import PaddleOCR
            import logging
            logging.getLogger('ppocr').setLevel(logging.ERROR)
            
            # Using english and devanagari (hi)
            self.model = PaddleOCR(lang=lang, device="cpu")
            self.is_initialized = True
            return time.time() - start_time
        except ImportError as e:
            print(f"PaddleOCR error: {e}. Run: pip install paddlepaddle paddleocr")
            return -1

    def recognize(self, image_path, lang='en'):
        # Re-init if language changes or not initialized
        if not self.is_initialized:
            self.initialize(lang=lang)
            
        start_time = time.time()
        if not self.model:
            return {"text": "", "latency": 0.0, "raw": None, "error": "Model failed to load"}

        try:
            result = self.model.ocr(image_path)
            latency = time.time() - start_time
            
            texts = []
            if result:
                for res in result:
                    if isinstance(res, dict):
                        if "rec_text" in res:
                            texts.append(str(res["rec_text"]))
                        elif "rec_texts" in res:
                            texts.extend([str(t) for t in res["rec_texts"]])
                    elif isinstance(res, list):
                        for item in res:
                            if isinstance(item, list) and len(item) > 1 and isinstance(item[1], (tuple, list)):
                                texts.append(str(item[1][0]))
                            elif isinstance(item, dict) and "rec_text" in item:
                                texts.append(str(item["rec_text"]))
                            elif isinstance(item, str):
                                texts.append(item)
                    elif hasattr(res, 'get'):
                        if res.get('rec_text'):
                            texts.append(str(res.get('rec_text')))
            return {
                "text": " ".join(texts),
                "latency": latency,
                "raw": str(result)
            }
        except Exception as e:
            return {"text": "", "latency": time.time() - start_time, "error": str(e)}
