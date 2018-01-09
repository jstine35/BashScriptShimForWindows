
This script fixes up the `sh_auto_file` setting on a windows system so that `.sh` script files
can be run from batch files and build steps without buggy behavior.

## The Bug in Detail
The default mode of operation when Git for Windows is installed is to run a new terminal window for
any invocation of `.sh` file, which has two unwanted side effects:

 1. a console window pops up -- and if part of a complex build step, this may be several windows.
 2. pipe redirection is broken, which is severe since roughly 97% of posix coreutils that come with
    sh/bash and friends depend on it.

## The Fix in Detail
	
## Possible Unintended Side-Effect
Scripts which depend on Git for Windows default behavior will not operate correctly.  Namely scripts
that expect to be able to query user input from a non-interactive context (such as a build step during
a build run from the IDE) will be unable to query anything since there will be no terminal to bind to.
The correct fix to this problem is the *_same fix_* that has been used on Linux systems:

    Explicitly run a terminal program with the shell script as a parameter, eg:
	
	$ winpty my_shell_script.sh
