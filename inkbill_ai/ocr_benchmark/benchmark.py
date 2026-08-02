import os
import json
import time
import argparse
import sys

# Reconfigure stdout/stderr for Unicode UTF-8 on Windows
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')
if hasattr(sys.stderr, 'reconfigure'):
    sys.stderr.reconfigure(encoding='utf-8')

# Add subdirs to path
sys.path.append(os.path.abspath(os.path.dirname(__file__)))

from paddle_wrapper.wrapper import PaddleWrapper
from trocr.wrapper import TrOCRWrapper
from got.wrapper import GOTWrapper

def calculate_cer(reference, hypothesis):
    """Character Error Rate calculation using Levenshtein distance."""
    ref_chars = list(reference.strip())
    hyp_chars = list(hypothesis.strip())
    
    if not ref_chars:
        return 0.0 if not hyp_chars else 1.0
        
    d = [[0] * (len(hyp_chars) + 1) for _ in range(len(ref_chars) + 1)]
    for i in range(len(ref_chars) + 1):
        d[i][0] = i
    for j in range(len(hyp_chars) + 1):
        d[0][j] = j

    for i in range(1, len(ref_chars) + 1):
        for j in range(1, len(hyp_chars) + 1):
            if ref_chars[i - 1] == hyp_chars[j - 1]:
                d[i][j] = d[i - 1][j - 1]
            else:
                d[i][j] = min(
                    d[i - 1][j] + 1,      # deletion
                    d[i][j - 1] + 1,      # insertion
                    d[i - 1][j - 1] + 1   # substitution
                )
    return float(d[len(ref_chars)][len(hyp_chars)]) / len(ref_chars)

def calculate_wer(reference, hypothesis):
    """Word Error Rate calculation."""
    ref_words = reference.strip().split()
    hyp_words = hypothesis.strip().split()
    
    if not ref_words:
        return 0.0 if not hyp_words else 1.0

    d = [[0] * (len(hyp_words) + 1) for _ in range(len(ref_words) + 1)]
    for i in range(len(ref_words) + 1):
        d[i][0] = i
    for j in range(len(hyp_words) + 1):
        d[0][j] = j

    for i in range(1, len(ref_words) + 1):
        for j in range(1, len(hyp_words) + 1):
            if ref_words[i - 1] == hyp_words[j - 1]:
                d[i][j] = d[i - 1][j - 1]
            else:
                d[i][j] = min(
                    d[i - 1][j] + 1,
                    d[i][j - 1] + 1,
                    d[i - 1][j - 1] + 1
                )
    return float(d[len(ref_words)][len(hyp_words)]) / len(ref_words)

def evaluate_model(model_name, wrapper, data, samples_dir):
    print(f"\n==========================================")
    print(f" Initializing {model_name}...")
    print(f"==========================================")
    
    init_time = wrapper.initialize()
    if init_time < 0:
        print(f"Skipping {model_name}: dependencies/models not loaded.")
        return None

    print(f"{model_name} Initialized in {init_time:.3f}s")
    
    results = {
        "model_name": model_name,
        "init_time_sec": init_time,
        "samples": []
    }

    for sample_name, sample_info in data.get("samples", {}).items():
        lang = sample_info.get("language", "mixed")
        img_path = os.path.join(samples_dir, lang, sample_name)
        
        if not os.path.exists(img_path):
            # Fallback check directly in samples
            img_path = os.path.join(samples_dir, sample_name)

        if not os.path.exists(img_path):
            print(f"Sample image not found: {img_path}")
            continue

        expected_text = " ".join([line["text"] for line in sample_info.get("lines", [])])
        
        # Run recognition
        try:
            rec_res = wrapper.recognize(img_path, lang=lang)
        except TypeError:
            rec_res = wrapper.recognize(img_path)
        pred_text = rec_res.get("text", "")
        latency = rec_res.get("latency", 0.0)
        
        cer = calculate_cer(expected_text, pred_text)
        wer = calculate_wer(expected_text, pred_text)
        
        print(f"Sample [{lang}] {sample_name}:")
        print(f"  Expected   : '{expected_text}'")
        print(f"  Recognized : '{pred_text}'")
        print(f"  CER: {cer:.2f} | WER: {wer:.2f} | Latency: {latency:.3f}s")
        
        results["samples"].append({
            "sample_name": sample_name,
            "language": lang,
            "expected": expected_text,
            "predicted": pred_text,
            "cer": cer,
            "wer": wer,
            "latency_sec": latency
        })

    return results

def main():
    parser = argparse.ArgumentParser(description="OCR/HTR Benchmark Suite")
    parser.add_argument("--model", type=str, choices=["paddle", "trocr", "got", "all"], default="all")
    args = parser.parse_args()

    expected_file = os.path.join(os.path.dirname(__file__), "expected_results.json")
    samples_dir = os.path.join(os.path.dirname(__file__), "samples")
    results_dir = os.path.join(os.path.dirname(__file__), "results")
    os.makedirs(results_dir, exist_ok=True)

    if not os.path.exists(expected_file):
        print(f"Error: {expected_file} not found.")
        return

    with open(expected_file, "r", encoding="utf-8") as f:
        data = json.load(f)

    models_to_run = []
    if args.model in ["paddle", "all"]:
        models_to_run.append(("PaddleOCR PP-OCRv4", PaddleWrapper()))
    if args.model in ["trocr", "all"]:
        models_to_run.append(("Microsoft TrOCR Small", TrOCRWrapper()))
    if args.model in ["got", "all"]:
        models_to_run.append(("GOT-OCR2_0 (Experimental)", GOTWrapper()))

    all_results = []
    for model_name, wrapper in models_to_run:
        res = evaluate_model(model_name, wrapper, data, samples_dir)
        if res:
            all_results.append(res)

    report_path = os.path.join(results_dir, "benchmark_report.json")
    with open(report_path, "w", encoding="utf-8") as f:
        json.dump(all_results, f, indent=2, ensure_ascii=False)
    print(f"\nBenchmark completed! Full report saved to {report_path}")

if __name__ == "__main__":
    main()
