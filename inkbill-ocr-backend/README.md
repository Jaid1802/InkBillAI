# inkbill-ocr-backend

Server-side post-processing backend for the InkBill AI Flutter app.

Raw OCR text from on-device ML Kit (or a base64 bill image, plus optional stroke
metadata) is sent here. The service calls Gemini server-side to clean up spelling
and structure the result into bill line items. The Gemini API key never leaves
the server.

## Endpoints

| Method | Path      | Description                                                                 |
| ------ | --------- | --------------------------------------------------------------------------- |
| GET    | `/health` | Health check. Returns `{"status": "ok"}`.                                    |
| GET    | `/docs`   | Swagger UI for the API.                                                      |
| POST   | `/process`| Structure OCR text/image into bill line items.                               |

## POST /process

Request body (`application/json`):

```json
{
  "text": "2 Bred 10.0\n1 M!lk 25.0",
  "imageBase64": "<optional base64 string>",
  "mimeType": "image/png",
  "strokes": [ { "x": 0.1, "y": 0.2, "t": 0.0 } ]
}
```

- `text`: raw OCR text from ML Kit (recommended input path).
- `imageBase64`: optional base64-encoded bill image, sent to Gemini as an inline image.
- `strokes`: optional handwriting stroke metadata (accepted, not required for extraction).
- At least one of `text` or `imageBase64` must be provided.

Response:

```json
{
  "items": [
    { "name": "Bread", "quantity": 2, "rate": 10.0, "confidence": 0.85 }
  ],
  "overallConfidence": 0.9
}
```

## Local development

```bash
pip install -r requirements.txt
set GEMINI_API_KEY=your-key
uvicorn main:app --reload --port 8000
```

## Deployment (Render)

The service deploys from this repo's `main` branch via Render.

### Option A - Blueprint (render.yaml at repo root)

```yaml
services:
  - type: web
    name: inkbill-ocr-backend
    runtime: python
    rootDir: inkbill-ocr-backend
    buildCommand: pip install -r requirements.txt
    startCommand: uvicorn main:app --host 0.0.0.0 --port $PORT
    plan: free
    autoDeploy: true
    healthCheckPath: /health
```

### Option B - Created via Render MCP (no rootDir support)

The MCP `create_web_service` tool does not expose a `rootDir` option, so prefix the
commands with `cd` to run inside the backend folder:

- Runtime: `python`
- Build command: `cd inkbill-ocr-backend && pip install -r requirements.txt`
- Start command: `cd inkbill-ocr-backend && uvicorn main:app --host 0.0.0.0 --port $PORT`
- Auto-deploy: `yes` (on push to the configured branch)
- Health check: the default `/` endpoint returns 200 (or set `/health` in the dashboard)

Required secrets (set in Render, never in code):

- `GEMINI_API_KEY`
- `SUPABASE_URL` (only if writing bills to Supabase)
- `SUPABASE_SERVICE_ROLE_KEY` (only if writing bills to Supabase)
- `ENABLE_SUPABASE_PERSIST` (`true` only if writing bills to Supabase)

See `render.yaml` at the repo root for the blueprint definition.