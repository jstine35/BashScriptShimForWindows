@echo off

SETLOCAL

:: First step: try running an sh script which simply returns success.  If it fails then there's no appropriate sh
:: handler installed into the system.

set BINDIR=%~1
IF "%BINDIR%" == ""  set BINDIR=.

IF NOT EXIST "%BINDIR%\sh_assoc_check.sh"      goto :ERROR_CORRUPT
IF NOT EXIST "%BINDIR%\sh_auto_file_fix.sh"    goto :ERROR_CORRUPT

:: if the user has CoreUtils in their path then `find` is going to be the Unix one, which is
:: very different from the grep-like `find` in CoreUtils.  Workaround by checking for grep and
:: favoring that, and assuming `find` is the Windows-one if grep is missing.
grep --version >nul 2>&1 && (set grep_cmd=grep) || (set grep_cmd=find)

"%BINDIR%\sh_assoc_check.sh" | %grep_cmd% 'VERIFIED' > nul 2>&1 && (
    echo Shell pipe redirection check passed!
    echo No changes to the system will be made.
    exit /b 0
)

:: 9009 is the code for "file not found", which gets set if sh_assoc_check.sh has no valid association 
IF %ERRORLEVEL% == 9009 (
    >&2 echo ERROR: .sh file association check failed!
    >&2 echo This installer requires Git for Windows.  If you do have Git for Windows installed then the
    >&2 echo install appears to be corrupted.  Please re-install latest edition of Git for Windows
    >&2 echo and try again.
    exit /b 1
)

ftype sh_auto_file>nul 2>&1 || (
    >&2 echo ERROR: CoreUtils/Bash pipe redirection test FAILED.
    >&2 echo ERROR: Git for Windows association 'sh_auto_file' not found!
    
    >&2 echo This is an unrecognized version of CoreUtils/Bash and things aren't
    >&2 echo working right but this installer is also not confident enough to apply
    >&2 echo changes since it doesn't recognize your software setup.  Please visit
    >&2 echo the ShAssocFix website on GitHub for details on how you can investigate
    >&2 echo your setup and fix things manually.
    >&2 echo
    >&2 No changes to the system will be made.
    exit /b 1
)


:: check if the sh_auto_file is already up to date and shortcut out if so.
:: The offending program that Git for Windows associates with is git-bash.exe,
:: so anything else we're going to consider valid.

FOR /F "tokens=* USEBACKQ" %%F IN (`ftype sh_auto_file`) DO (
    SET var=%%F
)

call :GETFILE %var:~13%

IF "%gfresult%" == "git-bash.exe" (
    :: It's expected that NSIS elevated to admin rights to allow this script to modify all
    :: the important things.
    "%BINDIR%\sh_auto_file_fix.sh --noninteractive"
) ELSE (
    echo git-bash.exe is what we're looking to fix and it already looks fixed!
    echo   ^> current .sh association = %gfresult%
    echo No changes to the system will be made.
)

exit /B 0


:: Function to get the quoted string filename from a set of input parameters.
:GETFILE
SET gfresult=%~nx1
exit /B

:ERROR_CORRUPT
>&2 echo ERROR: NSIS package state is corrupted! 
exit /b 1
