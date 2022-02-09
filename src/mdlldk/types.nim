type
  BOOL* = cint
    ## Is a 32-bit field that is set to 1 to indicate TRUE, or 0 to
    ## indicate FALSE.
  HANDLE = int # or pointer?
    ## A handle to an object.
  HWND* = HANDLE
    ## A handle to a window.

  LoadInfo* = object
    ## Object received by the LoadDll() procedure when the dll is loaded in mIRC with $dll or /dll.
    ## Brings and takes information to mIRC. Since mIRC v5.8.
    mVersion*: uint32
      ## Contains the mIRC version number in the low and high words.
    mHwnd*: HWND
      ## Contains the window handle to the main mIRC window.
    mKeep*: BOOL
      ## Is set to TRUE by default, indicating that mIRC will keep the
      ## dll loaded after the call. You can set mKeep to FALSE to make
      ## mIRC unload the dll after the call (which is how previous
      ## versions of mIRC worked).
    mUnicode*: BOOL
      ## Is set to FALSE by default, for backward compatibility. Can be
      ## set to TRUE to indicate that strings are Unicode as opposed to
      ## ANSI. Since mIRC v7.0.
    mBeta*: uint32
      ## Contains the mIRC beta version number, for public betas. Since
      ## mIRC v7.51.
    mBytes*: uint32
      ## Specifies the maximum number of bytes (not characters) allowed in
      ## the `data` and `parms` variables. Since mIRC v7.64.

  UnloadMode* {.importc: "int", nodecl, size: sizeof(cint).} = enum
    ## Values that indicate why the UnloadDll() procedure was called by mIRC. Since mIRC v5.8.
    MManual = 0
      ## Unloaded with /dll -u. In versions older than mIRC v6.3 it may
      ## also be when mIRC exits.
    MUnused = 1
      ## Dll not being used for ten minutes. The UnloadDll() procedure can
      ## return `RKeepLoaded` to keep the DLL loaded, or `RAllowUnload` to
      ## allow it to be unloaded.
    MOnExit = 2
      ## Unloaded when mIRC exits. Since mIRC v6.3.

  UnloadReturn* {.importc: "int", nodecl, size: sizeof(cint).} = enum
    ## Return values for the UnloadDll() procedure. Since mIRC v5.8.
    RKeepLoaded = 0
      ## Keep the dll loaded.
    RAllowUnload = 1
      ## Allows the dll to be unloaded.

  ProcReturn* {.importc: "int", nodecl, size: sizeof(cint).} = enum
    ## Values that can be returned by dll procedures. These values indicate what the mIRC should do.
    ## Since mIRC v5.6.
    RHalt = 0
      ## Means that mIRC should /halt processing.
    RContinue = 1
      ## Means that mIRC should continue processing.
    RCommand = 2
      ## Means that the dll has filled the `data` or `result.outData`
      ## variable with a command which it wants mIRC to perform, and has
      ## filled `parms` or `result.outParms` with the parameters to use,
      ## if any, when performing the command.
    RReturn = 3
      ## Means that the dll has filled the `data` or `result.outData`
      ## variable with the result that $dll() identifier should return.
