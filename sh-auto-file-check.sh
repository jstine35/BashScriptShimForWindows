#!/bin/bash
#

SHOW_HELP=0
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

is_git_bash=$(cmd //c ftype sh_auto_file | grep "git-bash")
is_bash=$(cmd //c ftype sh_auto_file | egrep '(\\|/)bash.exe')
	
if [[ -n "$is_bash" ]]; then
	# echo "Everything looks up-to-date, no system changes made."
	exit 0
fi

if [[ -z "$is_git_bash" ]]; then
	# echo "Git for Windows was not detected... nothing to do."
	exit 0
fi

exit 1
