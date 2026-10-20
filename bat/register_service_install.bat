@echo off
rem Usage: register_service_install.bat [ServiceName]
rem Service name: explicit arg, else auto-detected from <Name>Service.exe next to this bat, else CianChatService.
rem Bat must be next to <ServiceName>.exe. Run as administrator.
set SERVICE=%~1
if "%SERVICE%"=="" for %%F in ("%~dp0*Service.exe") do set "SERVICE=%%~nF"
if "%SERVICE%"=="" set SERVICE=CianChatService
cd /d "%~dp0"
echo Installing service %SERVICE%...
"%~dp0%SERVICE%.exe" /install /silent
rem /install returns 0 even on error, so check the service really exists
sc query %SERVICE% >nul 2>&1
if %errorlevel% equ 0 (
 sc failure %SERVICE% reset= 86400 actions= restart/60000/restart/60000// >nul
 echo Service %SERVICE% installed successfully
) else (
 echo Service %SERVICE% installation error
)
pause
