ECHO OFF
ECHO ************************************
ECHO *** MUST BE RUN AS ADMINISTRATOR ***
ECHO ************************************
PAUSE
ECHO Directory parameter: %~dp0
ECHO Registering %~dp0BoldSOAP.dll
%systemroot%\syswow64\regsvr32.exe -s "%~dp0BoldSOAP.dll"
IF ERRORLEVEL 1 GOTO regerror
ECHO Registering %~dp0BoldPropagatorInterfaces.dll
%systemroot%\syswow64\regsvr32.exe -s "%~dp0BoldPropagatorInterfaces.dll"
IF ERRORLEVEL 1 GOTO regerror
ECHO Registering %~dp0BoldLockingSupportInterfaces.dll
%systemroot%\syswow64\regsvr32.exe -s "%~dp0BoldLockingSupportInterfaces.dll"
IF ERRORLEVEL 1 GOTO regerror
ECHO Registering %~dp0BoldComConnection.dll
%systemroot%\syswow64\regsvr32.exe -s "%~dp0BoldComConnection.dll"
IF ERRORLEVEL 1 GOTO regerror
ECHO Registering "%~dp0BoldPropagator.exe"
"%~dp0BoldPropagator.exe" /regserver
IF ERRORLEVEL 1 GOTO regerror

GOTO complete
:regerror
ECHO Registration failed! Errorlevel: %ERRORLEVEL%

:complete
ECHO Registration completed


Pause