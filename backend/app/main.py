import base64
import io
import os
from contextlib import asynccontextmanager
from typing import List, Optional

import cv2
import numpy as np
from fastapi import FastAPI, File, Header, HTTPException, Request, UploadFile, status
from fastapi.middleware.cors import CORSMiddleware
from paddleocr import PaddleOCR
from PIL import Image
from pydantic import BaseModel, Field

OCR_API_KEY = os.getenv("OCR_API_KEY", "").strip()
OCR_MODEL_TYPE = os.getenv("OCR_MODEL_TYPE", "server").lower().strip()
MAX_IMAGE_SIZE = 2000
MAX_CONTENT_LENGTH = 15 * 1024 * 1024  # 15 MB

ocr_engine: Optional[PaddleOCR] = None


def init_ocr_engine() -> PaddleOCR:
    """Initialize PaddleOCR model once based on configuration."""
    print(f"Initializing PaddleOCR engine with model type: {OCR_MODEL_TYPE}...")

    server_det_dir = "/app/models/server_det"
    server_rec_dir = "/app/models/server_rec"

    use_server_models = (
        OCR_MODEL_TYPE == "server"
        and os.path.isdir(server_det_dir)
        and os.path.isdir(server_rec_dir)
    )

    if use_server_models:
        print("Loading PP-OCRv4 Server det and rec models...")
        return PaddleOCR(
            use_angle_cls=False,
            lang="en",
            det_model_dir=server_det_dir,
            rec_model_dir=server_rec_dir,
            show_log=False,
        )
    else:
        print("Loading PP-OCRv4 Standard/Mobile det and rec models...")
        return PaddleOCR(
            use_angle_cls=False,
            lang="en",
            ocr_version="PP-OCRv4",
            show_log=False,
        )


@asynccontextmanager
async def lifespan(app: FastAPI):
    global ocr_engine
    ocr_engine = init_ocr_engine()
    print("PaddleOCR engine initialized and ready.")
    yield
    print("Shutting down PaddleOCR engine.")


app = FastAPI(
    title="InkBill OCR Backend",
    version="1.0.0",
    description="High accuracy handwriting and printed receipt OCR powered by PaddleOCR.",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class OcrLine(BaseModel):
    text: str
    confidence: float
    x: float
    y: float
    w: float
    h: float
    row: int
    column: int


class OcrResponse(BaseModel):
    lines: List[OcrLine]
    raw_text: str
    image_width: int
    image_height: int
    model_type: str


class OcrBase64Request(BaseModel):
    image: str = Field(..., description="Base64 encoded image string or data URI")


def verify_api_key(x_api_key: Optional[str] = Header(None, alias="X-API-Key")) -> None:
    if OCR_API_KEY:
        if not x_api_key or x_api_key.strip() != OCR_API_KEY:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid or missing X-API-Key header",
            )


def decode_and_preprocess_image(image_bytes: bytes) -> np.ndarray:
    """Decode raw image bytes, handle alpha channels, and resize large images."""
    if len(image_bytes) > MAX_CONTENT_LENGTH:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail="Payload exceeds 15 MB limit",
        )

    try:
        pil_img = Image.open(io.BytesIO(image_bytes))
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Unable to parse image data: {e}",
        )

    # Convert transparent RGBA / LA to solid white background
    if pil_img.mode in ("RGBA", "LA") or (
        pil_img.mode == "P" and "transparency" in pil_img.info
    ):
        alpha_img = pil_img.convert("RGBA")
        background = Image.new("RGB", alpha_img.size, (255, 255, 255))
        background.paste(alpha_img, mask=alpha_img.split()[3])
        pil_img = background
    elif pil_img.mode != "RGB":
        pil_img = pil_img.convert("RGB")

    width, height = pil_img.size

    # Resize if max side > 2000px
    max_side = max(width, height)
    if max_side > MAX_IMAGE_SIZE:
        scale = MAX_IMAGE_SIZE / float(max_side)
        new_w = max(1, int(round(width * scale)))
        new_h = max(1, int(round(height * scale)))
        pil_img = pil_img.resize((new_w, new_h), Image.Resampling.LANCZOS)

    return np.array(pil_img)


def cluster_lines_into_rows_and_cols(boxes_with_text: list) -> List[OcrLine]:
    """Group bounding boxes into rows by vertical alignment, then sort columns."""
    if not boxes_with_text:
        return []

    # Calculate median height to form dynamic row clustering threshold
    heights = [item["h"] for item in boxes_with_text if item["h"] > 0]
    median_h = float(np.median(heights)) if heights else 25.0
    row_threshold = max(15.0, median_h * 0.6)

    # Sort primarily by vertical position
    sorted_items = sorted(boxes_with_text, key=lambda it: it["y"])

    # Cluster rows
    rows: List[List[dict]] = []
    for item in sorted_items:
        placed = False
        item_cy = item["y"] + (item["h"] / 2.0)

        for row in rows:
            row_avg_cy = sum(r["y"] + (r["h"] / 2.0) for r in row) / float(len(row))
            if abs(item_cy - row_avg_cy) <= row_threshold:
                row.append(item)
                placed = True
                break

        if not placed:
            rows.append([item])

    # Sort rows from top to bottom
    rows.sort(key=lambda r: sum(it["y"] for it in r) / float(len(r)))

    result_lines: List[OcrLine] = []
    for row_idx, row in enumerate(rows):
        # Sort items in row horizontally from left to right
        sorted_cols = sorted(row, key=lambda it: it["x"])
        for col_idx, item in enumerate(sorted_cols):
            result_lines.append(
                OcrLine(
                    text=item["text"],
                    confidence=item["confidence"],
                    x=round(item["x"], 2),
                    y=round(item["y"], 2),
                    w=round(item["w"], 2),
                    h=round(item["h"], 2),
                    row=row_idx,
                    column=col_idx,
                )
            )

    return result_lines


@app.get("/health")
def health():
    return {
        "status": "ok",
        "service": "inkbill-ocr-backend",
        "model_type": OCR_MODEL_TYPE,
        "engine_ready": ocr_engine is not None,
    }


@app.post("/ocr", response_model=OcrResponse)
async def perform_ocr(
    request: Request,
    payload: Optional[OcrBase64Request] = None,
    file: Optional[UploadFile] = File(None),
    x_api_key: Optional[str] = Header(None, alias="X-API-Key"),
):
    verify_api_key(x_api_key)

    if ocr_engine is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="OCR Engine is still initializing",
        )

    raw_bytes: Optional[bytes] = None

    if file is not None:
        raw_bytes = await file.read()
    elif payload is not None and payload.image:
        img_str = payload.image.strip()
        if "," in img_str and img_str.startswith("data:"):
            img_str = img_str.split(",", 1)[1]
        try:
            raw_bytes = base64.b64decode(img_str)
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid base64 encoding: {e}",
            )
    else:
        # Check if raw JSON body has "image"
        try:
            body = await request.json()
            if isinstance(body, dict) and "image" in body:
                img_str = body["image"].strip()
                if "," in img_str and img_str.startswith("data:"):
                    img_str = img_str.split(",", 1)[1]
                raw_bytes = base64.b64decode(img_str)
        except Exception:
            pass

    if not raw_bytes:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No image data provided. Provide multipart file or JSON with base64 'image'.",
        )

    img_rgb = decode_and_preprocess_image(raw_bytes)
    img_h, img_w, _ = img_rgb.shape

    # PaddleOCR expects BGR format when passed as numpy array
    img_bgr = cv2.cvtColor(img_rgb, cv2.COLOR_RGB2BGR)

    ocr_results = ocr_engine.ocr(img_bgr, cls=False)

    boxes_with_text = []
    if ocr_results and len(ocr_results) > 0 and ocr_results[0] is not None:
        for item in ocr_results[0]:
            box_points = item[0]
            text, score = item[1]

            xs = [pt[0] for pt in box_points]
            ys = [pt[1] for pt in box_points]

            min_x = max(0.0, float(min(xs)))
            max_x = min(float(img_w), float(max(xs)))
            min_y = max(0.0, float(min(ys)))
            max_y = min(float(img_h), float(max(ys)))

            boxes_with_text.append(
                {
                    "text": str(text).strip(),
                    "confidence": float(round(score, 4)),
                    "x": min_x,
                    "y": min_y,
                    "w": max(1.0, max_x - min_x),
                    "h": max(1.0, max_y - min_y),
                }
            )

    structured_lines = cluster_lines_into_rows_and_cols(boxes_with_text)

    # Build plain text representation grouped by rows
    rows_dict: dict = {}
    for line in structured_lines:
        rows_dict.setdefault(line.row, []).append(line.text)

    raw_text_lines = [
        "  ".join(cols) for row_idx, cols in sorted(rows_dict.items())
    ]
    raw_text = "\n".join(raw_text_lines)

    return OcrResponse(
        lines=structured_lines,
        raw_text=raw_text,
        image_width=img_w,
        image_height=img_h,
        model_type=OCR_MODEL_TYPE,
    )
