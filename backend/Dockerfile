FROM python:3.10-slim

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PORT=8000 \
    OCR_MODEL_TYPE=server

# Install OS libraries required by PaddlePaddle, OpenCV, and curl
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgomp1 \
    libgl1 \
    libglib2.0-0 \
    curl \
    tar \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy and install python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Pre-download PP-OCRv4 Server Detection and Recognition models at build time
RUN mkdir -p /app/models/server_det /app/models/server_rec && \
    curl -sSL https://paddleocr.bj.bcebos.com/PP-OCRv4/chinese/ch_PP-OCRv4_det_server_infer.tar | tar -x -C /app/models/server_det --strip-components=1 && \
    curl -sSL https://paddleocr.bj.bcebos.com/PP-OCRv4/chinese/ch_PP-OCRv4_rec_server_infer.tar | tar -x -C /app/models/server_rec --strip-components=1

# Pre-warm PaddleOCR mobile / standard weights and fonts into ~/.paddleocr
RUN python -c "from paddleocr import PaddleOCR; PaddleOCR(use_angle_cls=False, lang='en', ocr_version='PP-OCRv4', show_log=False)"

# Copy application source code
COPY app /app/app

EXPOSE 8000

CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000} --workers 1"]
