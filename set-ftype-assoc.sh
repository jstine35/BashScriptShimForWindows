#!/bin/bash

sh_exec_path="$1"

# MSYS has a bad habit of mucking up the quotations when using 'cmd //C'.
# this little trick exports the command line as an env var, and then pastes it
# from the cmd.exe context -- safe from MSYS meddling.
export whut="sh_auto_file=\"${sh_exec_path}\" --login \"%L\" %*"
cmd //C ftype %whut% 			 || exit
cmd //C assoc .sh=sh_auto_file   || exit
