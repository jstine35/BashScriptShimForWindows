# BASH Script Execution Shim for Windows

This utility is meant for use with both [**Git for Windows**](https://gitforwindows.org/) and
[**MSYS2**](https://sourceforge.net/projects/msys2/).  It allows `.sh` scripts to be run from the Windows
Explorer directly via double-click.  It also allows `.sh` scripts to be run from the `cmd` prompt and from
batch file scripts (`.bat` and `.cmd`).  It is available as an
    [installer for individual users](https://github.com/jstine35/ShAssocCheck/releases).

### What is a `shim` ?

A `shim` is a small script or executable that forwards a set of parameters onto another command.  The
command it forwards the parameters to depends on the current state of the running shell process.  In
the case of this shim, it forwards commands onto `bash.exe` for either Git for Windows or for MSYS2,
depending on the current state of the process.  It also ensures that the shell is spawned with `--login`
when appropriate.

### Benefits of installing this shim tool

 * Fixes a problem in Git for Windows `sh_auto_file` that breaks pipe redirection.  The bug is explained
   in detail later in this readme.
    
 * Provides safe interoperability on systems that have both Git for Windows and MSYS2 installed.
 
-----------------------------------------
## Installation for MSYS2 Standalone

It's expected that if you have **MSYS2** installed as a standalone tool, then it's a good chance you are
a CLI enthusiast and don't mind a few manual steps to get things working nicely.

### Using the Installer

If your MSYS2 is installed tot he default location at `c:\msys2` then all you should need to do is run
the installer.  The default settings should work fine.  If your MSYS2 is installed to a different
location then it becomes necessary to set an environment variable telling the shim where it can find
your MSYS2 install.  This is necessary because MSYS2 itself privodes _no clues_ about where it's been
installed to the Windows Registry or Environment.

The variable is `MSYS2_INSTALL_DIR` and can be set up like so:

    MSYS2_INSTALL_DIR=d:\path\to\msys64
    
Make sure to restart Windows Explorer (login/logout or kill process) before running the Installer, to make
sure the environment variable has taken effect.

### Using a CMD Prompt _(no installer)_
You can also manually create a file association for **MSYS2** without downloading the installer from this
repository.  Download sh-auto-shim.cmd onto your PC. Paste the following commands into an _admin-elevated_
command prompt, making sure to replace `c:\msys64` with the location of your MSYS2 install in the case
that it's not installed into the default location.

    c:\> ftype sh_auto_file="c:\path\to\sh-auto-shim.cmd" --msys2 "c:\msys64" "%L" %*
    c:\> assoc .sh=sh_auto_file

Alternatively you can set the MSYS2 dir via the `MSYS2_INSTALL_DIR` environment variable, in which case
the assocation can be abbrivated like so:

    c:\> ftype sh_auto_file="c:\path\to\sh-auto-shim.cmd" "%L" %*

-----------------------------------------
## Addendum: Trivia!
Probably this section's not helpful, unless you're academically curioous or your system is in some
bad or broken state and you're trying to troubleshoot it.

### Git for Windows Bug in Detail
The default mode of operation when Git for Windows is installed is to run a new terminal window for
any invocation of `.sh` file, which has two unwanted side effects:

 * a console window pops up -- and if part of a complex build step, this may be several windows.
 * pipe redirection is broken, which is severe since roughly 97% of posix coreutils that come with
   sh/bash and friends depend on it.

Git for Windows opts for this behavior because their devs _only_ consider one use-case: where a
Bash script is double-clicked from an explorer window as a means to input commit logs or interactively
modify rebase operations.  It makes sense from their narrow worldview to _always_ provide an interactive
shell whenever a `.sh` script is invoked.  After `ShAssocCheck` runs, it will repair this behavior so
that `.sh` files are run within the current shell context and process pipes are all connected correctly.

Note that I very much consider this a bug or design flaw because it _breaks interoperability_ between
users who have CoreUtils/Bash/Git installed via MSYS/CygWin and those who have it installed via Git for
Windows.  That is actually a problem.

#### Possible Drawback
The drawback to this method is that scripts authored explicitly for Git for Windows -- and which expect
the termincal console provided by Git for Windows terminal -- will start up in the default Windows Console
Terminal instead.  Basically this just means missing out on a lot of eye candy: nice fonts, bigger window
size, etc.  And you only miss out on that if you use interactive shell scripts in GIT.

#### Optional Workaround
If the association change does create a problem for specific interactive scripts, the ideal solution would 
be to create a new filetype and association that perfoms the default Git for Windows behavior and routes
through `git-bash.exe`.  Something like `.shw` -- short for `SH`ell for `W`indows.  It might be a good TODO
item for this script int he future, if there seems like there's interest in such a thing.  So far in my
development experience I've not found a single use case where the default Git for Windows behavior is actually
advantageous -- let alone necesssary -- so I've not been motiviated to try to implement a workaround to regain
access to it.

