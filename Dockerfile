# Use Python 3.9 slim image
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Install system dependencies including USB/IP
RUN apt-get update && apt-get install -y \
    gcc \
    usbip \
    linux-tools-generic \
    linux-modules-extra-$(uname -r) \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first to leverage Docker cache
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application
COPY . .

# Make init script executable
RUN chmod +x init_usbip.sh

# Create a non-root user
RUN useradd -m risuser && chown -R risuser:risuser /app

# Add user to necessary groups and sudoers
RUN usermod -a -G dialout,sudo risuser && \
    echo "risuser ALL=(ALL) NOPASSWD: /sbin/modprobe" >> /etc/sudoers

# Switch to non-root user
USER risuser

# Expose port
EXPOSE 5000

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV FLASK_APP=app.py
ENV FLASK_ENV=production

# Create entrypoint script
RUN echo '#!/bin/bash\n\
# Load required kernel modules\n\
sudo modprobe usbip_host || echo "Warning: Failed to load usbip_host module"\n\
sudo modprobe vhci-hcd || echo "Warning: Failed to load vhci-hcd module"\n\
\n\
# Initialize USB/IP connection\n\
./init_usbip.sh\n\
\n\
# Start the application\n\
exec python -m waitress --host=0.0.0.0 --port=5000 app:app\n\
' > /app/entrypoint.sh && chmod +x /app/entrypoint.sh

# Use the entrypoint script
ENTRYPOINT ["/app/entrypoint.sh"] 