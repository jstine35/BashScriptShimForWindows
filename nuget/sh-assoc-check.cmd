@echo off

:: This script is run from the context of an MSBuild job.  This means that it will almost
:: certainly require admin rights elevation in order to modify associations.  In order to
:: get those in the least painful way possible, I packed the "meat" into a NSIS install
:: executable which has a manifest setting to request admin rights.
::
:: First step: try running an sh script which simply returns success.  If it fails then
:: there's no appropriate sh handler installed into the system.

set BINDIR=%~1
IF "%BINDIR%" == ""  set BINDIR=.

IF NOT EXIST %BINDIR%\ShAssocFixGitForWindows.exe"      goto :ERROR_CORRUPT

:: These are the dependencies baked into the NSIS installer:
:: IF NOT EXIST "%BINDIR%\sh_assoc_check.sh"      goto :ERROR_CORRUPT
:: IF NOT EXIST "%BINDIR%\sh_auto_file_fix.sh"    goto :ERROR_CORRUPT

"%BINDIR%\sh_assoc_check.sh" > nul 2>&1 || (
	>&2 echo ERROR: Bash/CoreUtils is required to build this software. 
	>&2 echo You can acquire CoreUtils by installing one of the following software packages:
	>&2 echo   * Git For Windows  [recommended]
	>&2 echo   * MinGW / MSYS
	>&2 echo 
	>&2 echo Note that Cygwin is *not* supported: it does not provide .sh file associations
	>&2 echo by default, and it lacks automatic windows/linux pathname conversion features of
	>&2 echo of MinGW / MSYS.
	exit /b 1
)

ftype sh_auto_file>nul 2>&1 || (
	:: sh_auto_file not found, but the .sh association check above passed.  Assume that
	:: bash/CoreUtils is running by some means other than Git for Windows, and that it's
	:: not having the git-for-windows behavioral problem.  Moving right along...
	::echo No fixup patching is required...
	exit /b 0
)


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
	"%BINDIR%\ShAssocFixGitForWindows.exe"
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
