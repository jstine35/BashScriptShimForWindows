@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

:: Optimization: SH_AUTO_SHIM_EXEC is set by the first time the sh_auto_file association is invoked.
:: Any subsequent sub-shells will thus shortcut here.  User can also force behavior of the shim.
if EXIST "%SH_AUTO_SHIM_EXEC%" (
	set bash_path=%SH_AUTO_SHIM_EXEC%
	goto :BASH_SUBSHELL_FOUND
)

set shell_exec_cmd=bash.exe

:: If already a child of an MSYS2 shell process then it's necessary to run the *same* MSYS2 bash instance
:: otherwise it will fail with a DLL mismatch error.  Can't just check for bash tho, it might be bogus.
:: a few apps, chocolately installers in particular, install stripped-down non-functional versions of
:: bash.exe into the PATH just so they can glob files (making them equivalent to malware imo)
:: Workaround: Check for cygpath first, which serves as a good litmus for MSYS2 presence.
where cygpath 2>NUL 1>NUL
if %errorlevel% == 0 (
	where bash 2>NUL 1>NUL
	if %errorlevel% == 0 (
		FOR /F "tokens=* USEBACKQ" %%F IN (`where bash`) DO (
			SET bash_path=%%F\%shell_exec_cmd%
		)
		goto :BASH_SUBSHELL_FOUND
	)
)

:: favor git-bash ahead of MSYS2 bash as it generally integrates better with Windows.
:: GIT Bash usually sets up an sh_auto_file association that allows sh files to be run directly.  But
:: sometimes it is missing from developers' installs, or has been incorrectly re-assigned to load sh
:: scripts into text files.  So check if git is in the path first...

where git 2>NUL 1>NUL
if %errorlevel% == 0 (
    FOR /F "tokens=* USEBACKQ" %%F IN (`where git`) DO (
        SET git_path=%%F
    )
    
    if defined git_path (
        call :dirname result "!git_path!"
        set bash_path=!result!\..\bin\%shell_exec_cmd%
		goto :GIT_PATH_FOUND
    )
)

:: 1. look for MSYS2_INSTALL_DIR in the environment. Note that MSYS2 doesn't setup any environment vars
::    you will need to add it yourself if you want to control the beavior of this script.
:: 2. fallback on MSYS2 bash at the fixed location...
set bash_path=%MSYS2_INSTALL_DIR%\usr\bin\%shell_exec_cmd%
if NOT EXIST "%bash_path%" (
	set bash_path=c:\msys64\usr\bin\%shell_exec_cmd%
	if NOT EXIST "%bash_path%" (
		goto :ERROR_BASH_NOT_FOUND
	)
)

:: MSYS2 doesn't integrate with cmd shell the same way git-bash does by default.  It needs some
:: env setup to help mimic git-bash behavior:
set CHERE_INVOKING=1
set MSYSTEM=MINGW64
set MSYS2_PATH_TYPE=inherit

:: SHLVL is used by bash to decide if it should clear the screen after logout, which fails with an error on
:: jenkins since there is no terminal bound to the shell. This works around it while retaining support for
:: nested shell calls.
:BASH_SUBSHELL_FOUND
:GIT_PATH_FOUND
set SH_AUTO_SHIM_EXEC=%bash_path%
IF not defined SHLVL set SHLVL=0
set /a SHLVL+=1
"%bash_path%" --login %*
exit /b %errorlevel%

:dirname <resultVar> <pathVar>
(
    set "%~1=%~dp2"
    exit /b
)

:ERROR_BASH_NOT_FOUND
>&2 echo error: GIT bash was not found in the PATH.
>&2 echo Please install GIT for Windows and ensure its installer is instructed to add
>&2 echo GIT to the PATH.
>&2 echo -----------------------------
>&2 echo If you have a standalone installation of MSYS2 its location can be specified 
>&2 echo directly via: set MSYS2_INSTALL_DIR=c:\path\to\msys2
exit /b 1
