@echo off

:: First step: try running an sh script which simply returns success.  If it fails then there's no appropriate sh
:: handler installed into the system.

set BINDIR=%~1
IF "%BINDIR%" == ""  set BINDIR=.

IF NOT EXIST "%BINDIR%\sh_assoc_check.sh"      goto :ERROR_CORRUPT
IF NOT EXIST "%BINDIR%\sh_auto_file_fix.sh"    goto :ERROR_CORRUPT

"%BINDIR%\sh_assoc_check.sh" > nul 2>&1 || (
	>&2 echo ERROR: SH script support check failed!
	>&2 echo This fix requires Git for Windows.  If you do have Git for Windows installed then the
	>&2 echo install appears to be corrupted.  Please re-install latest edition of Git for Windows
	>&2 echo and try again.
	exit /b 1
)

ftype sh_auto_file>nul 2>&1 || (
	::echo sh_auto_file not found, assuming shell is running by some means other than Git for Windows.
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

IF "%gfresult%" == "git-bash.exe" (
	:: It's expected that NSIS elevated to admin rights to allow this script to modify all
	:: the important things.
	"%BINDIR%\sh_auto_file_fix.sh"
)

exit /B 0


:: Function to get the quoted string filename from a set of input parameters.
:GETFILE
SET gfresult=%~nx1
exit /B

:ERROR_CORRUPT
echo ERROR: NuGet package state corrupted, sh_assoc_check.sh not found! 2>&1
echo Please clear your NuGet cache and try again. The NuGet cache is typically 2>&1
echo located in your c:\users\UserName\AppData\Local\.nuget dir. 2>&1
exit /b 1
