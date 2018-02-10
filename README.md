# ShAssocCheck
Performs checks for `.sh` file association and correct pipe redirection behavior and reports a coherent
error message if the check fails.  Supports auto-hotfixing a bug in [**Git for Windows**](https://gitforwindows.org/)
_(requires user admin rights elevation)_.  Hot-fixing [**MSYS2**](https://www.msys2.org) is not currently supported:
developers using **MSYS2** will need to create the `.sh` file association manually.

Available in multiple form factors:
  * ___(recommended)___ as an [installer for individual users](https://github.com/jstine35/ShAssocCheck/releases)
    looking to verify their CoreUtils is working as-it-should, or to fix their existing _Git for Windows_
    install.
  * as a NuGet package that can be attached to any project and throws helpful diagnostic messages if
    CoreUtils checks fail.
  * as stand-alone `.sh` scripts which must be run from an _admin-enabled_ `git-bash` shell -- for those
    who love their CLI as much as I do
    
## Getting and Using the NuGet Package

[TODO - link to nuget published page]

If you would like your Visual Studio projects to be robust against developers encountering mysterious build
failures due to pipe redirection failures or missing `.sh` file associations, then add this NuGet dependency.
Keep in mind that this NuGet package normally doesn't _do_ anything, except verify that `.sh` scripts are in
fact working.  If you have a controlled development envitonment where you can ensure everyone has Bash/CoreUtils
properly installed, then there's really no need to use the `ShAssocCheck` NuGet Package.

If you have a solution with many projects then it is a good idea to attach `ShAssocCheck` NuGet package to a
special startup project in your solution that runs before anything else.  Often times solutions will have such
a project for the purpose of collecting git repository version information and this NuGet package is best
added as a dependency there.  If the solution doesn't have such a project, then probably it probably _should_
have one.

## NuGet Package: How it Works
The script tests for operational `.sh` file associations by running a short `.sh` script and getting
the result via pipe redirection.  If it works, then the script does nothing else.  If that check fails, the
script proceeds to check `sh_auto_file` and see if it matches git-bash.exe.  If so, it applies the 
***Git for Windows* assocation fix** via a NSIS installer.  The installer is used because it provides
the _Admin Elevated Rights_ profile required to modify file types and associations, and will be invoked
only once after any *Git for Windows* install/update (due to GitWin overwritting our association with it's
broken one).

## Creating `.sh` Associations for MSYS2

#### Using MSYS Bash Shell
You can create the correct association by running `./sh_auto_file_fix.sh` that comes with this repository.
It has a feature that can forcibly create a new `.sh` association.  Example:

    $ sh_auto_file_fix.sh --force-assoc

### Using a CMD Prompt _(no downloads required)_
You can also manually create a file association for **MSYS2** without downloading anything from ShAssocCheck.
Paste the following commands into an _admin-elevated_ command prompt, making sure to replacd `c:\msys64\` with
the location of your MSYS2 install in the case that it's not installed into the default location.

    c:\> ftype sh_auto_file="c:\msys64\usr\bin\bash.exe" --login "%L" %*
    c:\> assoc .sh=sh_auto_file
    
For trivia sake: the same basic action is done to repair the broken association in **Git for Windows**,
except the path is to the `bash.exe` that's installed in the **Git for Windows** directory, usually
something akin to `c:\Program Files\Git\usr\bin\bash.exe`.

---------------------
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
size, etc.  And I don't know anyone who uses interactive shells anyway.  `gitk`, `GitExtensions`, and 
`TortoiseGit` are all _much_ better windows-native solutions to the interactive-UI problem.

#### Optional Workaround
If the association change does create a problem for specific interactive scripts, the ideal solution would 
be to create a new filetype and association that perfoms the default Git for Windows behavior and routes
through `git-bash.exe`.  Something like `.shw` -- short for `SH`ell for `W`indows.  It might be a good TODO
item for this script int he future, if there seems like there's interest in such a thing.  So far in my
development experience I've not found a single use case where the default Git for Windows behavior is actually
advantageous -- let alone necesssary -- so I've not been motiviated to try to implement a workaround to regain
access to it.

