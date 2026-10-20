@echo off
rem Usage: register_service_create.bat [ServiceName]
rem Service name: explicit arg, else auto-detected from <Name>Service.exe next to this bat, else CianChatService.
rem Bat must be next to <ServiceName>.exe. Service name must match exe name. Run as administrator.
set SERVICE=%~1
if "%SERVICE%"=="" for %%F in ("%~dp0*Service.exe") do set "SERVICE=%%~nF"
if "%SERVICE%"=="" set SERVICE=CianChatService
echo Service %SERVICE% registration...
sc create %SERVICE% binPath= "\"%~dp0%SERVICE%.exe\"" DisplayName= "%SERVICE%" start= auto
if %errorlevel% equ 0 (
 sc description %SERVICE% "CianChat.Setl.Corppn.ru"
 sc failure %SERVICE% reset= 86400 actions= restart/60000/restart/60000//
 echo Service %SERVICE% registered
) else (
 echo Service %SERVICE% registration error
)
pause
