# Multi-stage build — minimal final image for AWS Batch Fargate
FROM python:3.12-slim AS builder

WORKDIR /install

COPY requirements.txt .

RUN pip install --no-cache-dir --upgrade pip \
 && pip install --no-cache-dir --target=/install/deps -r requirements.txt

# ── Runtime stage ─────────────────────────────────────────────────────────────
FROM python:3.12-slim

# Security: non-root user
RUN groupadd -r batchuser && useradd -r -g batchuser batchuser

WORKDIR /app

# Only the installed dependencies
COPY --from=builder /install/deps /app/deps

# Application code
COPY processor.py /app/

ENV PYTHONPATH=/app/deps \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

USER batchuser

ENTRYPOINT ["python", "-u", "/app/processor.py"]
