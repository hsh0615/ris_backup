# Use Python 3.9 slim image as base
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    sudo \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

# Create necessary groups and add user
RUN groupadd -r appuser && useradd -r -g appuser appuser \
    && groupadd -r dialout || true \
    && usermod -aG dialout appuser

# Copy requirements first to leverage Docker cache
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application
COPY . .

# Create necessary directories
RUN mkdir -p config logs RIS_BusData

# Set permissions
RUN chown -R appuser:appuser /app \
    && chmod -R 755 /app \
    && chmod 666 /dev/ttyS3 2>/dev/null || true

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 5000

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV FLASK_APP=app.py
ENV FLASK_ENV=production

# Run the application
CMD ["python", "app.py"] 