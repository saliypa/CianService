@echo off
rem Usage: unregister_service_install.bat [ServiceName]
rem Service name: explicit arg, else auto-detected from <Name>Service.exe next to this bat, else CianChatService.
set SERVICE=%~1
if "%SERVICE%"=="" for %%F in ("%~dp0*Service.exe") do set "SERVICE=%%~nF"
if "%SERVICE%"=="" set SERVICE=CianChatService
cd /d "%~dp0"
echo Uninstalling service %SERVICE%...
sc stop %SERVICE% >nul 2>&1
"%~dp0%SERVICE%.exe" /uninstall /silent
sc query %SERVICE% >nul 2>&1
if %errorlevel% neq 0 (
 echo Service %SERVICE% uninstalled successfully
) else (
 echo Service %SERVICE% uninstallation error
)
pause
