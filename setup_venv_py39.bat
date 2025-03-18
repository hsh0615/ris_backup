@echo off
chcp 65001 > nul
echo.
echo ===================================================
echo      Setup Python 3.9 Virtual Environment
echo ===================================================
echo.

REM Check if Python 3.9 is installed
echo Checking Python 3.9...
py -3.9 --version >nul 2>&1
if errorlevel 1 (
    echo Error: Python 3.9 not found
    echo Please install Python 3.9 from:
    echo https://www.python.org/downloads/release/python-390/
    pause
    exit /b 1
)

REM Show Python version
echo Found Python version:
py -3.9 --version

REM Check if virtual environment exists
if exist .venv (
    echo.
    echo Removing existing virtual environment...
    rmdir /s /q .venv
)

REM Create new Python 3.9 virtual environment
echo.
echo Creating new Python 3.9 virtual environment...
py -3.9 -m venv .venv
if errorlevel 1 (
    echo Error: Failed to create virtual environment.
    pause
    exit /b 1
)

REM Activate virtual environment
echo.
echo Activating virtual environment...
call .venv\Scripts\activate.bat

REM Verify Python version
python --version
if errorlevel 1 (
    echo Error: Failed to verify Python version.
    pause
    exit /b 1
)

REM Upgrade pip
echo.
echo Upgrading pip...
python -m pip install --upgrade pip

REM Install dependencies
echo.
echo Installing required dependencies...
pip install flask==2.0.3 pyserial==3.5 waitress==2.1.2 python-dotenv==0.21.1 requests==2.27.1 werkzeug==2.3.8
pip install numpy matplotlib flask-cors

REM Create startup script
echo @echo off > start_ris_server.bat
echo chcp 65001 ^> nul >> start_ris_server.bat
echo echo. >> start_ris_server.bat
echo echo =================================================== >> start_ris_server.bat
echo echo                 Start RIS Server >> start_ris_server.bat
echo echo =================================================== >> start_ris_server.bat
echo echo. >> start_ris_server.bat
echo call .venv\Scripts\activate.bat >> start_ris_server.bat
echo python -m waitress --port=5000 app:app >> start_ris_server.bat
echo if errorlevel 1 pause >> start_ris_server.bat
echo call .venv\Scripts\deactivate.bat >> start_ris_server.bat

echo.
echo ===================================================
echo                   Setup Complete!
echo ===================================================
echo.
echo Virtual environment has been set up successfully.
echo You can start the server using:
echo 1. Run start_ris_server.bat
echo 2. Or manually execute:
echo    - call .venv\Scripts\activate.bat
echo    - python -m waitress --port=5000 app:app
echo.
echo Press any key to exit...
pause 