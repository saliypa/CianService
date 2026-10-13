@echo off
echo Installing service...
cd /d "%CD%"
CianChatService.exe /install

if %errorlevel% equ 0 (
 echo Service installed successfully
) else (
 echo Service installation error
)
pause