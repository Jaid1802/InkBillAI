import os
import sys
from PIL import Image
from transformers import TrOCRProcessor, VisionEncoderDecoderModel

processor = TrOCRProcessor.from_pretrained('microsoft/trocr-small-handwritten', use_fast=False)
model = VisionEncoderDecoderModel.from_pretrained('microsoft/trocr-small-handwritten')

img_path = os.path.abspath("samples/english/english_1.png")
image = Image.open(img_path).convert("RGB")

pixel_values = processor(images=image, return_tensors="pt").pixel_values
print("Pixel values shape:", pixel_values.shape)

generated_ids = model.generate(pixel_values, max_new_tokens=30)
print("Generated IDs:", generated_ids)

print("Recognized text:", repr(processor.batch_decode(generated_ids, skip_special_tokens=True)[0]))
