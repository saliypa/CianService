@echo off
echo Uninstalling service...
cd /d "%CD%"
CianChatService.exe /uninstall

if %errorlevel% equ 0 (
 echo Service uninstalled successfully
) else (
 echo Service uninstallation error
)
pause