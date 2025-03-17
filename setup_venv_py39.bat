@echo off
echo.
echo ===================================================
echo     設置Python 3.9虛擬環境並安裝MATLAB Engine API
echo ===================================================
echo.

REM 檢查Python 3.9是否已安裝
echo 檢查Python 3.9...
py -3.9 --version >nul 2>&1
if errorlevel 1 (
    echo 錯誤: 未找到Python 3.9
    echo 請先安裝Python 3.9，可以從以下網址下載：
    echo https://www.python.org/downloads/release/python-390/
    pause
    exit /b 1
)

REM 顯示找到的Python版本
echo 找到的Python版本:
py -3.9 --version

REM 檢查虛擬環境是否已存在
if exist .venv (
    echo.
    echo 發現已存在的虛擬環境，正在移除...
    rmdir /s /q .venv
)

REM 創建新的Python 3.9虛擬環境
echo.
echo 創建新的Python 3.9虛擬環境...
py -3.9 -m venv .venv
if errorlevel 1 (
    echo 錯誤: 無法創建虛擬環境。
    pause
    exit /b 1
)

REM 激活虛擬環境
echo.
echo 激活虛擬環境...
call .venv\Scripts\activate.bat

REM 確認Python版本
python --version
if errorlevel 1 (
    echo 錯誤: 無法確認Python版本。
    pause
    exit /b 1
)

REM 升級pip
echo.
echo 升級pip...
python -m pip install --upgrade pip

REM 安裝依賴
echo.
echo 安裝必要的依賴...
pip install flask==2.0.3 pyserial==3.5 waitress==2.1.2 python-dotenv==0.21.1 requests==2.27.1 werkzeug==2.3.8
pip install numpy matplotlib flask-cors

REM 安裝MATLAB Engine API
echo.
echo ===================================================
echo          安裝 MATLAB Engine API for Python
echo ===================================================
echo.

REM 嘗試查找MATLAB安裝路徑
set MATLAB_FOUND=0
set MATLAB_ROOT=

REM 檢查常見的MATLAB安裝路徑
for %%v in (R2024a R2023b R2023a R2022b R2022a R2021b R2021a R2020b) do (
    if exist "C:\Program Files\MATLAB\%%v" (
        set MATLAB_ROOT=C:\Program Files\MATLAB\%%v
        set MATLAB_FOUND=1
        echo 找到MATLAB安裝路徑: !MATLAB_ROOT!
        goto :matlab_found
    )
)

:matlab_not_found
echo 無法自動找到MATLAB安裝路徑。
set /p MATLAB_ROOT="請輸入MATLAB安裝路徑 (例如: C:\Program Files\MATLAB\R2022b): "

if not exist "%MATLAB_ROOT%" (
    echo 錯誤: 提供的路徑不存在
    goto :matlab_not_found
)

:matlab_found
echo 使用MATLAB路徑: %MATLAB_ROOT%

REM 安裝MATLAB Engine API
set ENGINE_PATH=%MATLAB_ROOT%\extern\engines\python
if not exist "%ENGINE_PATH%" (
    echo 錯誤: 找不到MATLAB引擎路徑: %ENGINE_PATH%
    pause
    exit /b 1
)

echo 切換到引擎目錄並安裝...
pushd "%ENGINE_PATH%"
python setup.py build --build-base="%TEMP%\matlab_build" install
popd

REM 檢查MATLAB引擎是否安裝成功
python -c "import matlab.engine" >nul 2>&1
if errorlevel 1 (
    echo.
    echo 錯誤: MATLAB Engine API安裝失敗。
    echo 請確保您有足夠的權限並且MATLAB已正確安裝。
    echo.
    echo 您可以嘗試手動安裝MATLAB Engine API:
    echo 1. 打開MATLAB
    echo 2. 在MATLAB命令窗口運行:
    echo    cd^(fullfile^(matlabroot,'extern','engines','python'^)^)
    echo    system^('python setup.py install'^)
    echo.
    pause
    exit /b 1
) else (
    echo.
    echo MATLAB Engine API安裝成功!
)

REM 創建啟動腳本
echo @echo off > start_ris_server.bat
echo echo. >> start_ris_server.bat
echo echo =================================================== >> start_ris_server.bat
echo echo                啟動RIS服務器 >> start_ris_server.bat
echo echo =================================================== >> start_ris_server.bat
echo echo. >> start_ris_server.bat
echo call .venv\Scripts\activate.bat >> start_ris_server.bat
echo python -m waitress --port=5000 app:app >> start_ris_server.bat
echo if errorlevel 1 pause >> start_ris_server.bat
echo call .venv\Scripts\deactivate.bat >> start_ris_server.bat

echo.
echo ===================================================
echo                  設置完成！
echo ===================================================
echo.
echo 虛擬環境已成功設置，所有依賴已安裝。
echo 您可以使用以下方式啟動服務器:
echo 1. 運行 start_ris_server.bat
echo 2. 或手動執行以下命令:
echo    - call .venv\Scripts\activate.bat
echo    - python -m waitress --port=5000 app:app
echo.
echo 按任意鍵退出...
pause 