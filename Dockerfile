# Build stage
FROM python:3.11-slim as builder

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# Runtime stage
FROM python:3.11-slim

WORKDIR /app

# Install netcat for health checks
RUN apt-get update && apt-get install -y netcat-openbsd && rm -rf /var/lib/apt/lists/*

# Copy Python dependencies from builder
COPY --from=builder /root/.local /root/.local
ENV PATH=/root/.local/bin:$PATH

# Copy application code
COPY . .

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
  CMD nc -z localhost 8000 || exit 1

# Run the application - wait for MySQL then start uvicorn
CMD bash -c "while ! nc -z mysql 3306; do echo 'Waiting for MySQL...'; sleep 1; done && echo 'MySQL is ready!' && sleep 2 && uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload"
