#!/bin/bash

echo
echo "==================================================="
echo "      Setup Python 3.9 Virtual Environment"
echo "==================================================="
echo

# Check if Python 3.9 is installed
echo "Checking Python 3.9..."
if ! command -v python3.9 &> /dev/null; then
    echo "Error: Python 3.9 not found"
    echo "Please install Python 3.9 using:"
    echo "sudo apt update"
    echo "sudo apt install python3.9 python3.9-venv"
    exit 1
fi

# Show Python version
echo "Found Python version:"
python3.9 --version

# Check if virtual environment exists
if [ -d ".venv" ]; then
    echo
    echo "Removing existing virtual environment..."
    rm -rf .venv
fi

# Create new Python 3.9 virtual environment
echo
echo "Creating new Python 3.9 virtual environment..."
python3.9 -m venv .venv
if [ $? -ne 0 ]; then
    echo "Error: Failed to create virtual environment."
    exit 1
fi

# Activate virtual environment
echo
echo "Activating virtual environment..."
source .venv/bin/activate

# Verify Python version
python --version
if [ $? -ne 0 ]; then
    echo "Error: Failed to verify Python version."
    exit 1
fi

# Upgrade pip
echo
echo "Upgrading pip..."
python -m pip install --upgrade pip

# Install dependencies
echo
echo "Installing required dependencies..."
pip install flask==2.0.3 pyserial==3.5 waitress==2.1.2 python-dotenv==0.21.1 requests==2.27.1 werkzeug==2.3.8
pip install numpy matplotlib flask-cors

# Create startup script
cat > start_ris_server.sh << 'EOL'
#!/bin/bash
echo
echo "==================================================="
echo "                 Start RIS Server"
echo "==================================================="
echo
source .venv/bin/activate
python -m waitress --port=5000 app:app
deactivate
EOL

chmod +x start_ris_server.sh

echo
echo "==================================================="
echo "                   Setup Complete!"
echo "==================================================="
echo
echo "Virtual environment has been set up successfully."
echo "You can start the server using:"
echo "1. Run ./start_ris_server.sh"
echo "2. Or manually execute:"
echo "   - source .venv/bin/activate"
echo "   - python -m waitress --port=5000 app:app"
echo 