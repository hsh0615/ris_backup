@echo off 
chcp 65001 > nul 
echo. 
echo =================================================== 
echo                 Start RIS Server 
echo =================================================== 
echo. 
call .venv\Scripts\activate.bat 
python -m waitress --port=5000 app:app 
if errorlevel 1 pause 
call .venv\Scripts\deactivate.bat 
