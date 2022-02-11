# Import the mdlldk package.
import pkg/mdlldk

# Adds procedure LoadDll() and defines that the dll must not continue loaded after use and the
# communication between the dll and mIRC must be by unicode (WideCString).
addLoadProc(false, true):
  discard

# Adds procedure UnloadDll() and defines that mIRC can unload the dll when it is unused for ten
# minutes.
addUnloadProc(RAllowUnload):
  discard

# Adds the `test` procedure which can be called from mIRC like this: `/dll test.dll test`
newProcToExport(test):
  result.outData = "echo -a Dll test made in Nim " & NimVersion & " for mIRC"
  result.ret = RCommand

# It must be added to the last line of your Nim code to correctly export all symbols to the dll.
exportAllProcs()
