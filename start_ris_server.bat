@echo off 
echo. 
echo =================================================== 
echo                啟動RIS服務器 
echo =================================================== 
echo. 
call .venv\Scripts\activate.bat 
python -m waitress --port=5000 app:app 
if errorlevel 1 pause 
call .venv\Scripts\deactivate.bat 
