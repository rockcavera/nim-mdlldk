# Import the mdlldk package.
import mdlldk

# Adds procedure LoadDll().
addLoadProc(false, true):
  ## The dll will be unloaded right after use and the communication between
  ## mIRC and dll will be by the use of unicode strings.
  discard

# Adds procedure UnloadDll().
addUnloadProc(RAllowUnload):
  ## The dll is allowed to unloaded.
  discard

# Adds the `info` procedure, which can be called from mIRC.
newProcToExport(info):
  ## When called, it executes a command that prints a message about the dll
  ## in the active window.
  ##
  ## Usage: `/dll ttest.dll info`
  result.outData = "echo -a test.dll made in Nim " & NimVersion & " for mIRC"
  result.ret = RCommand

# Adds an alias named `dllInfo` to the `info` procedure.
addAliasFor(info, dllInfo):
  ## Is an alias of procedure `info()`.
  ##
  ## Usage: `/dll ttest.dll dllInfo`
  discard

# It must be added to the last line of your Nim code to correctly export all
# symbols to the dll.
exportAllProcs()
