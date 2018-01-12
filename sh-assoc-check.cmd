@echo off

:: First step: try running an sh script which simply returns success.  If it fails then there's no appropriate sh
:: handler installed into the system.

set BINDIR=%~1
IF "%BINDIR%" == ""  set BINDIR=.

IF NOT EXIST "%BINDIR%\sh_assoc_check.sh"      goto :ERROR_CORRUPT
IF NOT EXIST "%BINDIR%\sh_auto_file_fix.sh"    goto :ERROR_CORRUPT

"%BINDIR%\sh_assoc_check.sh" > nul 2>&1 || (
	echo ERROR: SH script support check failed! 2>&1
	echo   CoreUtils/BASH is required to build this software.  2>&1
	echo   This error can be remedied by installing Git for Windows or MSYS/MinGW. 2>&1
	exit /b 1
)

ftype sh_auto_file>nul 2>&1 || (
	::echo sh_auto_file not found, assuming shell is running by some means other than Git for Windows.
	::echo No fixup patching is required...
	exit /b 0
)


:: check if the sh_auto_file is already up to date and shortcut out if so.

FOR /F "tokens=* USEBACKQ" %%F IN (`ftype sh_auto_file`) DO (
	SET var=%%F
)

call :GETFILE %var:~13%

IF "%gfresult%" == "bash.exe" (
	::echo Everything looks up-to-date, no system changes made.
	::exit /B 0
)

"%BINDIR%\elevate.exe" "%BINDIR%\sh_auto_file_fix.sh"
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
