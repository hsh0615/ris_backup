# RIS Control Server

This is a Docker-based RIS (Reconfigurable Intelligent Surface) control server that provides a REST API for controlling RIS devices.

## Prerequisites

- Ubuntu (with direct USB access support)
- Docker and Docker Compose installed

## Quick Setup

1. Clone this repository:
```bash
git clone <repository-url>
cd ris_backup
```

2. Give execution permission to the setup script:
```bash
chmod +x setup_docker.sh
```

3. Run the setup script:
```bash
./setup_docker.sh
```

The script will automatically:
- Install necessary dependencies
- Build the Docker image
- Start the RIS server container
- Configure proper permissions

## Configuration

All configuration parameters can be modified in the `.env` file:

```bash
# Main parameters
FLASK_APP=app.py
FLASK_ENV=production
COM_PORT=/dev/ttyUSB1  # Change this to match your USB device

# RIS default parameters
RIS_DEFAULT_FREQ=28.0
RIS_DEFAULT_XI=10.5
# ... other parameters
```

## API Usage

### Check Server Health
```bash
curl http://localhost:5000/health
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

## Troubleshooting

1. If the server fails to start, check the logs:
```bash
docker logs ris-server
```

2. If you get permission errors:
- Ensure your user is in the docker group: `groups`
- If not, add your user: `sudo usermod -aG docker $USER`
- Log out and back in for changes to take effect

3. If USB device is not accessible:
- Check if the device is properly connected
- Verify the COM_PORT in .env matches your device
- Ensure you have proper permissions to access the USB device

## Development

To build the image locally:
```bash
docker build -t ris-server:latest .
```

To view logs in real-time:
```bash
tail -f logs/ris_server.log
``` 