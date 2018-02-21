
@echo off
SETLOCAL

:: c:\msys64\usr\bin\bash.exe

set COREUTILS_SHELL=%1
for /f "tokens=*" %%a in ('%COREUTILS_SHELL% --login shell-test.sh "%COREUTILS_SHELL%"') do (
    set result=%%a
)

if errorlevel 0 (
    echo Updating file associations:
    @echo on
    ftype sh_auto_file="%result%" --login "%%L" %%*
    assoc .sh=sh_auto_file
    @echo off
    echo Operation completed with success.
) else (
    echo Error: Unable to run .sh script via %COREUTILS_SHELL%
    echo        No file association changes have been made.
)