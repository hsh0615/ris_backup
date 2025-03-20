# RIS Control Server

This is a Docker-based RIS (Reconfigurable Intelligent Surface) control server that provides a REST API for controlling RIS devices.

## Prerequisites

- Ubuntu 20.04 or later
- Docker and Docker Compose installed
- USB/IP support in the kernel
- Docker Hub account (for deployment)

### Installing Docker and Docker Compose

```bash
# Update package list
sudo apt-get update

# Install required packages
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Set up the stable repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Add your user to the docker group
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### Setting up USB/IP

```bash
# Install USB/IP tools
sudo apt-get install -y linux-tools-generic linux-modules-extra-$(uname -r)

# Load required kernel modules
sudo modprobe usbip_host
sudo modprobe vhci-hcd

# Start USB/IP server
sudo usbipd -D
```

## Deployment

### Building and Pushing to Docker Hub

1. Create a Docker Hub account at https://hub.docker.com/

2. Login to Docker Hub:
```bash
docker login
```

3. Build the image:
```bash
# Replace your-username with your Docker Hub username
docker build -t your-username/ris-server:latest .
```

4. Push the image:
```bash
docker push your-username/ris-server:latest
```

### Quick Start for Users

1. Create a new directory and download the configuration files:
```bash
mkdir ris-control && cd ris-control
curl -O https://raw.githubusercontent.com/your-username/ris-control/main/docker-compose.yml
curl -O https://raw.githubusercontent.com/your-username/ris-control/main/.env.example
```

2. Create your environment file:
```bash
cp .env.example .env
```

3. Edit the `.env` file with your settings:
```bash
nano .env
```
Make sure to set:
- `DOCKER_USERNAME`: Your Docker Hub username
- `RIS_COM_PORT`: Your RIS device's COM port number
- `USBIP_DEVICE_BUSID`: Your USB device's bus ID (optional)

4. Create necessary directories:
```bash
mkdir -p config logs
```

5. Start the server:
```bash
docker-compose up -d
```

6. Check the server status:
```bash
curl http://localhost:5000/health
```

## API Usage

### List Available USB/IP Devices
```bash
curl http://localhost:5000/usbip/devices
```

### Attach a USB/IP Device
```bash
curl -X POST http://localhost:5000/usbip/attach \
  -H "Content-Type: application/json" \
  -d '{"busid": "1-1"}'
```

### Check USB/IP Status
```bash
curl http://localhost:5000/usbip/status
```

### Control RIS Device
```bash
curl -X POST http://localhost:5000/set_ris \
  -H "Content-Type: application/json" \
  -d '{
    "xr": 15.7,
    "yr": 8.9,
    "zr": 3.1
  }'
```

## Configuration

The server can be configured through the `.env` file. Here are the main settings:

- `DOCKER_USERNAME`: Your Docker Hub username
- `SERVER_PORT`: Port to expose the API (default: 5000)
- `USBIP_HOST`: USB/IP server host (default: host.docker.internal)
- `USBIP_PORT`: USB/IP server port (default: 3240)
- `USBIP_DEVICE_BUSID`: USB device bus ID to automatically attach
- `RIS_COM_PORT`: COM port number for the RIS device
- `RIS_DEFAULT_PARAMS`: Default parameters for RIS control

## Troubleshooting

1. If the server fails to start, check the logs:
```bash
docker-compose logs -f
```

2. If USB/IP connection fails:
- Ensure USB/IP server is running: `sudo usbipd -D`
- Check kernel modules are loaded: `lsmod | grep usbip`
- Verify USB device is available: `usbip list -r localhost`

3. If you get permission errors:
- Ensure your user is in the docker group: `groups`
- If not, add your user: `sudo usermod -aG docker $USER`
- Log out and back in for changes to take effect

## Development

To build the image locally:
```bash
docker build -t ris-server:latest .
```

To run tests:
```bash
docker-compose run --rm ris_server python -m pytest
``` 