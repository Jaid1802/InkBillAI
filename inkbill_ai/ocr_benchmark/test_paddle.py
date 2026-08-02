import os
import sys

os.environ['FLAGS_use_mkldnn'] = '0'
os.environ['FLAGS_enable_pir_api'] = '0'

from paddleocr import PaddleOCR

ocr = PaddleOCR(lang='en', device='cpu')
img_path = os.path.abspath("samples/english/english_1.png")
print("Image path:", img_path)

res = ocr.ocr(img_path)
print("Type of res:", type(res))
print("Raw res content:", res)

if isinstance(res, list) and len(res) > 0:
    print("Element 0 type:", type(res[0]))
    print("Element 0 content:", res[0])
