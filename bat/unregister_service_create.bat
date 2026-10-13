@echo off
echo Remove service...
sc delete CianChatService
if %errorlevel% equ 0 (
 echo Service removed
) else (
 echo Error deleting service
)
pause