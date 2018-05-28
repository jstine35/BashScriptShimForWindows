
!include "LogicLib.nsh"
!include "MUI2.nsh"


; The name of the installer
Name "Bash Script Exec Shim for Git for Windows and MSYS2"
InstallDir "$ProgramFiles\BashScriptShim-MSYS2"
RequestExecutionLevel admin

!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES

Section

	SetOutPath "$INSTDIR"
	File ..\sh-auto-shim.cmd
	File ..\set-ftype-assoc.sh

	; It is better to put stuff in $pluginsdir, $temp is shared
	InitPluginsDir
	SetOutPath "$pluginsdir\BashScriptShim-MSYS2" 

	DetailPrint "Installing sh_auto_file association..."
	nsExec::ExecToLog '"$INSTDIR\sh-auto-shim.cmd" "$INSTDIR\set-ftype-assoc.sh" "$INSTDIR\sh-auto-shim.cmd"'
	Pop $0 ; result

	; Change current dir so $temp and $pluginsdir is not locked by our open handle
	SetOutPath $exedir 
	
	${If} $0 <> 0
	    SetDetailsView show
		DetailPrint "Installation failed."
		Abort
	${EndIf}
  
SectionEnd

; TODO : Add an uninstall section.

; For uninstalling purposes, the original sh_auto_file looks like this:
;  sh_auto_file="C:\Program Files\Git\git-bash.exe" --no-cd "%L" %*