@echo off
setlocal

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

IF NOT EXIST "%BINDIR%\sh_assoc_check.sh"      goto :ERROR_CORRUPT

:: if the user has CoreUtils in their path then `find` is going to be the Unix one, which is
:: very different from the grep-like `find` in CoreUtils.  Workaround by checking for grep and
:: favoring that, and assuming `find` is the Windows-one if grep is missing.
set grep_cmd=FINDSTR

:: UPDATE: use CMD's FINDSTR builtin instead of find or grep!
::grep --version >nul 2>&1 && (set grep_cmd=grep) || (set grep_cmd=find)

"%BINDIR%\sh_assoc_check.sh" | %grep_cmd% "VERIFIED" > nul 2>&1 && (
    :: full pipe redirection check passed, so there's nothing else we need to do.
    exit /b 0
)

:: 9009 is the code for "file not found", which gets set if sh_assoc_check.sh has no valid association 
IF %ERRORLEVEL% == 9009 (
    >&2 echo ERROR: Bash/CoreUtils is required to build this software. 
    >&2 echo You can acquire CoreUtils by installing one of the following software packages:
    >&2 echo   * Git For Windows  [recommended]
    >&2 echo   * MSYS2 (requires additional steps)
    >&2 echo 
    >&2 echo Note that MSYS2 support is dodgy and will likely require expert knowledge of MSYS2
    >&2 echo package management to get things working. The CoreUtils that come with Git for
    >&2 echo Windows are much more feature-complete.  If you have MSYS2 installed and are getting
    >&2 echo this message then you will need to create the .sh file association manually.
    exit /b 1
)

:: At this point we've confirmed association is present and the pipe isn't working.
:: It should be Git for Windows, which means it should be sh_auto_file defined.

ftype sh_auto_file>nul 2>&1 || (
    >&2 echo ERROR: CoreUtils/Bash pipe redirection test FAILED.
    >&2 echo ERROR: Unrecognized distribution of CoreUtils/Bash.
    >&2 echo   This buildstep doesn't recognize your CoreUtils software setup is not confident
    >&2 echo   enough to apply changes to try and fix it.  Please visit the ShAssocCheck website
    >&2 echo   on GitHub for details on how you can fix things manually.
    >&2 echo   
    >&2 echo Alternatively, install Git for Windows and make sure to select the full Unix
    >&2 echo Commandline integration via PATH option for best results.
    CALL ERROR_SOFTWARE_REQUIRED
    exit /b 1
)

IF NOT EXIST %BINDIR%\ShAssocFixGitForWindows.exe"      goto :ERROR_CORRUPT
:: These are the dependencies baked into the NSIS installer:
:: IF NOT EXIST "%BINDIR%\sh_auto_file_fix.sh"    goto :ERROR_CORRUPT

:: check if the sh_auto_file is already up to date and shortcut out if so.
:: The offending program that Git for Windows associates with is git-bash.exe,
:: so anything else we're going to consider valid.

FOR /F "tokens=* USEBACKQ" %%F IN (`ftype sh_auto_file`) DO (
    SET var=%%F
)

call :GETFILE %var:~13%

:: if the check fails, run the installer - it'll request elevation rights and install the patch.
:: All the shortcuts above ensure this only happens if it's *actually going to change something*.

IF "%gfresult%" == "git-bash.exe" (
    if %INTERACTIVE% == "true" (
        "%BINDIR%\ShAssocFixGitForWindows.exe"
    ) else (
    
    )
)

exit /B 0


:: Function to get the quoted string filename from a set of input parameters.
:GETFILE
SET gfresult=%~nx1
exit /B

:ERROR_CORRUPT
>&2 echo ERROR: NuGet package state corrupted, sh_assoc_check.sh not found!
>&2 echo Please clear your NuGet cache and try again. The NuGet cache is typically
>&2 echo located in your c:\users\UserName\.nuget dir.
exit /b 1
