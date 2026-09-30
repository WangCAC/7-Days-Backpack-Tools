@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0build-single-file.ps1" %*
set "result=%ERRORLEVEL%"
if not "%result%"=="0" echo.
if not "%result%"=="0" echo Build failed. See the error above.
echo.
pause
exit /b %result%
