@echo off
setlocal ENABLEDELAYEDEXPANSION

:: This script is run from the context of an MSBuild job.  This means that it will almost
:: certainly require admin rights elevation in order to modify associations.  In order to
:: get those in the least painful way possible, I packed the "meat" into a NSIS install
:: executable which has a manifest setting to request admin rights.
::
:: First step: try running an sh script which simply returns success.  If it fails then
:: there's no appropriate sh handler installed into the system.

set BINDIR=%~1
set INTERACTIVE=%2
IF "%BINDIR%" == ""  set BINDIR=.

IF NOT EXIST "%BINDIR%\test_script.sh"  goto :ERROR_CORRUPT

:: use a native CMD prompt tool FINDSTR, since we can't assume that grep is available in the path
set grep_cmd=FINDSTR

:: shortcut out if bash shell script association and pipe redirection checks already work
:: caveat: if someone has .sh bound as a textfile action, this will probably open Notepad.
"%BINDIR%\test_script.sh" | %grep_cmd% "VERIFIED" > nul 2>&1 && (
    exit /b 0
)

:: At this point we've confirmed association is present and the pipe isn't working.
:: It should be Git for Windows, which means it should be sh_auto_file defined.
:: FYI - 9009 is the code for "file not found", which gets set if test_script.sh has no valid
::       association.  But we don't care, as any failure is grounds for running the installer.
IF NOT EXIST "%BINDIR%\BashScriptShimInstaller.exe" goto :ERROR_CORRUPT

:: Interactive mode is optional to gracefully handle slave/autobuilder situations, where no human
:: is present to click through the buttons required to complete the installer process.
if %INTERACTIVE% == "true" (
    "%BINDIR%\BashScriptShimInstaller.exe"  || exit /b %errorlevel%
)
else (
    >&2 echo ERROR: Bash Scripts associations are required to build this software.
    >&2 echo Please download and install Git for Windows and then run the following installer:
    >&2 echo   %BINDIR%\BashScriptShimInstaller.exe
    exit /B 1
)

:: Function to get the quoted string filename from a set of input parameters.
:GETFILE
SET gfresult=%~nx1
exit /B

:ERROR_CORRUPT
>&2 echo ERROR: NuGet package state corrupted, a file was not found.
>&2 echo Please clear your NuGet caches and try again.
exit /b 1
