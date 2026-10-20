@echo off
rem Usage: unregister_service_create.bat [ServiceName]
rem Service name: explicit arg, else auto-detected from <Name>Service.exe next to this bat, else CianChatService.
set SERVICE=%~1
if "%SERVICE%"=="" for %%F in ("%~dp0*Service.exe") do set "SERVICE=%%~nF"
if "%SERVICE%"=="" set SERVICE=CianChatService
echo Remove service %SERVICE%...
sc stop %SERVICE% >nul 2>&1
sc delete %SERVICE%
if %errorlevel% equ 0 (
 echo Service %SERVICE% removed
) else (
 echo Error deleting service %SERVICE%
)
pause
