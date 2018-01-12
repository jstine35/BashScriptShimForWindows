
!include "LogicLib.nsh"

; The name of the installer
Name ".Sh Association Fix for Git for Windows"

; Request application privileges for Windows Vista
RequestExecutionLevel admin

Section

	; It is better to put stuff in $pluginsdir, $temp is shared
	InitPluginsDir
	SetOutPath "$pluginsdir\MyApp\Install" 
  
	File ..\sh_assoc_check.sh
	File ..\sh_auto_file_fix.sh
	File sh-assoc-fix.cmd
	
	DetailPrint "Executing sh-assoc-fix.cmd..."

	nsExec::ExecToLog "$pluginsdir\MyApp\Install\sh-assoc-fix.cmd"
	Pop $0 ; result

	; Change current dir so $temp and $pluginsdir is not locked by our open handle
	SetOutPath $exedir 
	
	${If} $0 <> 0
	    SetDetailsView show
		DetailPrint "Errors occurred."
	${EndIf}
  
SectionEnd
