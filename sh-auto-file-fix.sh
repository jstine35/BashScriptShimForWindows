#!/bin/bash
#
# Updates sh_auto_file setting for git for windows 2.xx
# 
# By default, Git for Windows  runs git-bash.exe, which internally spawns an MSYS console window
# and breaks pipe redirections (stdin/stdout/etc).  It is replaced with a direct invocation of
# bash.exe, which allows for completely seamless bash/cmd script executions. 
#
# This script has not been tested under stand-alone MSYS or Cygwin.  In theory it should
# not modify anything of those installations, since they either
#   1. don't use git-bash, or
#   2. don't use sh_auto_file association for .sh scripts.
#

SHOW_HELP=0
ELEVATE=0
FORCE_ASSOC=0
shell_path=


POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    --shell-path)
    shell_path="$2"
    shift 2 # past argument + value
    ;;
    --elevate)
    ELEVATE=1
    shift
    ;;
	--force-assoc)
	FORCE_ASSOC=1
    shift
    ;;
    --help)
    SHOW_HELP=1
    shift
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done

me=$(basename "$0")

if [[ "$FORCE_ASSOC" -eq "0" ]]; then
	if ! cmd //C assoc .sh | grep "sh_auto_file"; then
		# this is actually a pretty special error since somehow the bash script is running without
		# the aid of any association.
		
		>&2 echo 
		>&2 echo "ERROR: Git for Windows is not installed or the installation is corrupted."
		>&2 echo "  This error occurred because the association for the .sh filetype is not set"
		>&2 echo "  or is set to some unexpected value. You may optionally force configuration"
		>&2 echo "  of the .sh association with:"
		>&2 echo ""
		>&2 echo "    $ ${me} --force-assoc"
		>&2 echo ""
		>&2 echo "Probably, it won't work.  But might be worth the try!"
		
		echo "Press any key to close..."
		read  -n 1
		exit 1
	fi
fi

if [[ -z "$shell_path" ]]; then

	is_git_bash=$(cmd //c ftype sh_auto_file | grep "git-bash")
	is_bash=$(cmd //c ftype sh_auto_file | egrep '(\\|/)bash.exe')
	
	
	if [[ -n "$is_bash" ]]; then
		echo 
		echo "Everything looks up-to-date, no system changes made."
		exit 0
	fi

	bash_fullpath=

	if [[ -n "$is_git_bash" ]]; then
		exename=$(echo "$is_git_bash" | cut -d'=' -f2)
		
		# deletes everything after and including the last occurrence of .exe
		# strips preceding double quote.
		exename=${exename%.exe\" *}
		path_to_git=$(dirname "${exename##\"}")
		
		bash_fullpath="${path_to_git}\\usr\\bin\\bash.exe"
	fi
	
	if [[ ! -f  "$bash_fullpath" ]]; then
		# we're running in an sh shell, so 'where bash' should return the bash that we want
		# assuming the bash.exe is smart enough to set up a correct path env var that favors
		# itself over all the other myriad installs which might exist on any given system.
		bash_fullpath="$(where bash | head -n1)"
	fi

	if [[ ! -f "$bash_fullpath" ]]; then
		>&2 echo 
		>&2 echo "ERROR: suitable bash.exe could not found."
		>&2 echo "  For best results  make sure to (re-)install Git for Windows and select the option"
		>&2 echo "    > 'Use Git from the Windows Command Prompt' "
		>&2 echo
		>&2 echo "  Alternatively, manually specify a specific path on the command line:"
		>&2 echo "    $ ${me} --shell-path [path-to-shell-exec]"
		>&2 echo ""
		echo "Press any key to close..."
		read  -n 1
		exit -1
	fi
	
	shell_path="$bash_fullpath"
fi

if [[ -f "$bash_fullpath" ]]; then
	if [[ "$FORCE_ASSOC" -eq "1" ]]; then
		cmd //C assoc .sh=sh_auto_file
	fi

	# MSYS has a bad habit of mucking up the quotations when using 'cmd //C'.
	# this little trick exports the command line as an env var, and then pastes it
	# from the cmd.exe context -- safe from MSYS meddling.
	echo "BASH.exe found @ ${bash_fullpath}"
	export whut="sh_auto_file=\"${bash_fullpath}\" --login \"%L\" %*"
	if [[ "$ELEVATE" -eq "1" ]]; then
		sudo cmd //C ftype %whut% 
	else
	         cmd //C ftype %whut% 
	fi
	echo "Press any key to close..."
	read  -n 1
else
	>&2 echo "ERROR: File not found: $bash_fullpath"
	>&2 echo "  No changes to system settings made."
	>&2 echo 
	echo "Press any key to close..."
	read  -n 1
	exit -1
fi
