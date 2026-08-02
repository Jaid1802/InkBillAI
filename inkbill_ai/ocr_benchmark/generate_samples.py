import os
import json
from PIL import Image, ImageDraw, ImageFont

def create_image_with_text(text, filename):
    # Create a high-res white image
    img = Image.new('RGB', (800, 200), color=(255, 255, 255))
    d = ImageDraw.Draw(img)
    
    font = None
    # Try system fonts
    font_paths = [
        "C:\\Windows\\Fonts\\arial.ttf",
        "C:\\Windows\\Fonts\\calibri.ttf",
        "C:\\Windows\\Fonts\\seguiemj.ttf",
        "C:\\Windows\\Fonts\\Nirmala.ttf" # Nirmala UI supports Devanagari!
    ]
    for path in font_paths:
        if os.path.exists(path):
            try:
                font = ImageFont.truetype(path, 40)
                break
            except Exception:
                pass
                
    if font is None:
        font = ImageFont.load_default()
        
    # Draw text with dark gray/black color
    d.text((40, 60), text, fill=(10, 10, 10), font=font)
    img.save(filename)
    print(f"Created high-res sample: {filename}")

def main():
    expected_file = "expected_results.json"
    if not os.path.exists(expected_file):
        print(f"Error: {expected_file} not found.")
        return

    with open(expected_file, "r", encoding="utf-8") as f:
        data = json.load(f)

    samples_dir = "samples"
    for sample_name, sample_data in data.get("samples", {}).items():
        lang = sample_data.get("language", "mixed")
        lines = sample_data.get("lines", [])
        
        # Combine all lines text into one string separated by newline
        full_text = "\n".join([line["text"] for line in lines])
        
        # Determine path based on language
        output_dir = os.path.join(samples_dir, lang)
        os.makedirs(output_dir, exist_ok=True)
        
        output_path = os.path.join(output_dir, sample_name)
        create_image_with_text(full_text, output_path)

if __name__ == "__main__":
    main()
