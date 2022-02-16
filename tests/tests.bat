@ECHO OFF
SETLOCAL ENABLEEXTENSIONS
SETLOCAL ENABLEDELAYEDEXPANSION
SETLOCAL

SET /a pass=0
SET /a fail=0

RMDIR /S /Q builds >nul 2>&1
MD builds
CALL :FILES
ECHO PASS=%pass%
ECHO FAIL=%fail%

RMDIR /S /Q builds >nul 2>&1

PAUSE
EXIT /B

:FILES
FOR %%i IN (tdebug tdebuga tdebugw ttest) do (
  ECHO %%i
  CALL :COMPILERS %%i
  ECHO.
)
EXIT /B

:COMPILERS
FOR %%i IN (gcc clang vcc) do CALL :BACKENDS %* %%i
EXIT /B

:BACKENDS
FOR %%i IN (c cpp) do CALL :GCS %* %%i
EXIT /B

:GCS
FOR %%i IN (refc orc arc) do CALL :NIMCOMPILER %* %%i
EXIT /B

:NIMCOMPILER
SETLOCAL
SET line=nim %3 -o:builds\ --nimcache:"builds\nimcache\%1" --app:lib --cpu:i386 --cc:%2 --gc:%4 %1
%line% >nul 2>&1
IF %ERRORLEVEL% neq 0 (
  ECHO [FAIL] %line%
  ENDLOCAL
  SET /a fail=%fail%+1
) ELSE (
  ECHO [PASS] %line%
  ENDLOCAL
  SET /a pass=%pass%+1
)
EXIT /B
