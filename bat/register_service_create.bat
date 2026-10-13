@echo off
echo Service registration...
sc create CianChatService binPath="C:\WebServices\CianChatService\CianChatService.exe" DisplayName="CianChat Service" start=auto
if %errorlevel% equ 0 (
 echo Service registered
) else (
 echo Service registration error
)
pause