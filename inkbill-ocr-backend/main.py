"""InkBill AI - OCR / handwriting recognition post-processing backend.

Accepts raw OCR text (from on-device ML Kit), an optional base64 bill image,
and optional stroke metadata. Calls Gemini server-side to clean up and structure
the result into bill line items. Gemini API keys stay on the server only.
"""

import base64
import json
import os
import re
from typing import Any, Dict, List, Optional

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from google import genai
from google.genai import types
from pydantic import BaseModel, ConfigDict

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "").strip()
GEMINI_MODEL = os.getenv("GEMINI_MODEL", "gemini-2.5-flash").strip()

ENABLE_SUPABASE_PERSIST = os.getenv("ENABLE_SUPABASE_PERSIST", "false").strip().lower() == "true"
SUPABASE_URL = os.getenv("SUPABASE_URL", "").strip()
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY", "").strip()

_client = genai.Client(api_key=GEMINI_API_KEY) if GEMINI_API_KEY else None

SYSTEM_PROMPT = """You are an expert AI assistant for the InkBill AI billing application.
The input is the raw OCR output from a handwritten bill. It may contain spelling errors
(e.g., 'Bred' instead of 'Bread', 'M!lk' instead of 'Milk').

Your task:
1. Parse the items into a structured list.
2. Correct spelling mistakes for common billing and grocery items.
3. Extract the item name, quantity (number), and rate (price).
4. Assign a confidence score (0.0 to 1.0) to each item. If you had to heavily correct the
   spelling or infer the numbers, lower the confidence score (e.g., 0.5 or 0.6). If it was
   perfectly clear, use 0.9 or 1.0.

Output MUST be exactly valid JSON in this format:
{
  "items": [
    {
      "name": "Bread",
      "quantity": 2,
      "rate": 10.0,
      "confidence": 0.85
    }
  ],
  "overallConfidence": 0.9
}"""

app = FastAPI(
    title="InkBill AI OCR Post-Processing Backend",
    description="Structures raw OCR text from handwritten bills into line items via Gemini.",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


class ProcessRequest(BaseModel):
    text: Optional[str] = None
    rawText: Optional[str] = None
    imageBase64: Optional[str] = None
    mimeType: str = "image/png"
    strokes: Optional[List[Dict[str, Any]]] = None

    @property
    def recognized_text(self) -> Optional[str]:
        value = (self.text or self.rawText or "").strip()
        return value or None


class LineItem(BaseModel):
    name: str
    quantity: float
    rate: float
    confidence: float

    model_config = ConfigDict(extra="ignore")


class ProcessResponse(BaseModel):
    items: List[LineItem]
    overallConfidence: float

    model_config = ConfigDict(extra="ignore")


def _extract_json(text: str) -> Dict[str, Any]:
    """Parse the first JSON object out of a Gemini response (strips markdown fences)."""
    cleaned = text.strip()
    cleaned = re.sub(r"^```(?:json)?\s*", "", cleaned, flags=re.IGNORECASE)
    cleaned = re.sub(r"\s*```$", "", cleaned)
    start = cleaned.find("{")
    end = cleaned.rfind("}")
    if start == -1 or end == -1 or end <= start:
        raise ValueError("No JSON object found in model response.")
    return json.loads(cleaned[start : end + 1])


def _to_float(value: Any, default: float) -> float:
    if isinstance(value, bool):
        return default
    try:
        return float(value)
    except (TypeError, ValueError):
        return default


def _build_parts(req: ProcessRequest) -> List[types.Part]:
    parts: List[types.Part] = [types.Part.from_text(text=SYSTEM_PROMPT)]

    recognized = req.recognized_text
    if recognized:
        parts.append(types.Part.from_text(text=f"Raw Text:\n{recognized}"))

    if req.imageBase64:
        try:
            image_data = base64.b64decode(req.imageBase64)
        except Exception as exc:  # noqa: BLE001
            raise HTTPException(status_code=422, detail="imageBase64 is not valid base64.") from exc
        parts.append(
            types.Part.from_text(
                text="Also inspect the attached bill image and include any items readable from it."
            )
        )
        parts.append(
            types.Part.from_bytes(data=image_data, mime_type=req.mimeType or "image/png")
        )

    if req.strokes:
        parts.append(
            types.Part.from_text(
                text=f"Note: {len(req.strokes)} handwriting stroke samples were provided as "
                "metadata. They are not needed for extraction."
            )
        )

    return parts


def _persist_bill(items: List[Dict[str, Any]], overall_confidence: float) -> None:
    """Best-effort write to Supabase. Only runs when explicitly enabled via env vars."""
    if not (ENABLE_SUPABASE_PERSIST and SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY):
        return

    try:
        from supabase import create_client  # lazy import so missing keys never break startup

        client = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
        client.table("bills").insert(
            {"items": items, "overall_confidence": overall_confidence}
        ).execute()
    except Exception as exc:  # noqa: BLE001
        # Never fail the request because persistence hiccuped.
        print(f"[warn] Supabase persist failed: {exc}")


@app.get("/")
def root():
    return {"service": "inkbill-ocr-backend", "status": "ok", "docs": "/docs"}


@app.get("/health")
def health():
    return {"status": "ok", "model": GEMINI_MODEL if _client else None}


async def _run_processing(req: ProcessRequest) -> ProcessResponse:
    if not req.recognized_text and not req.imageBase64:
        raise HTTPException(status_code=422, detail="Provide either 'text'/'rawText' or 'imageBase64'.")

    if _client is None:
        raise HTTPException(
            status_code=500,
            detail="GEMINI_API_KEY is not configured on the server. Set it as a Render secret.",
        )

    parts = _build_parts(req)

    try:
        response = await _client.aio.models.generate_content(
            model=GEMINI_MODEL,
            contents=parts,
            config=types.GenerateContentConfig(response_mime_type="application/json"),
        )
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(status_code=502, detail=f"Gemini request failed: {exc}") from exc

    if not response.text:
        raise HTTPException(status_code=502, detail="Gemini returned an empty response.")

    try:
        result = _extract_json(response.text)
    except (ValueError, json.JSONDecodeError) as exc:
        raise HTTPException(status_code=502, detail=f"Failed to parse model output as JSON: {exc}") from exc

    raw_items = result.get("items", [])
    if not isinstance(raw_items, list):
        raise HTTPException(status_code=502, detail="Model output 'items' is not a list.")

    items: List[LineItem] = []
    for raw in raw_items:
        if not isinstance(raw, dict):
            continue
        items.append(
            LineItem(
                name=str(raw.get("name") or "Item"),
                quantity=_to_float(raw.get("quantity"), 1.0),
                rate=_to_float(raw.get("rate"), 0.0),
                confidence=max(0.0, min(1.0, _to_float(raw.get("confidence"), 1.0))),
            )
        )

    overall = max(
        0.0,
        min(1.0, _to_float(result.get("overallConfidence"), 0.5)),
    )

    _persist_bill([item.model_dump() for item in items], overall)

    return ProcessResponse(items=items, overallConfidence=overall)


@app.post("/process", response_model=ProcessResponse)
async def process(req: ProcessRequest):
    return await _run_processing(req)


@app.post("/recognize", response_model=ProcessResponse)
async def recognize(req: ProcessRequest):
    return await _run_processing(req)