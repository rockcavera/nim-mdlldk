## `NimMain()` is a function required to initialize the Nim runtime. As it is
## not recommended to call it `DllMain()`, as the Nim compiler does by default,
## the dlls created by the `mdlldk` package call `NimMain()` from the
## `LoadDll()` function, which is called by mIRC as soon as a dll is loaded from
## version 5.8 of mIRC.
##
## For compatibility reasons, every function added by the `newProcToExport()`,
## `newProcToExportW()` and `newProcToExportA()` templates checks whether the
## Nim runtime has already been initialized, otherwise they call `NimMain()`.
##
## If compiled with `-d:mdlldkNoDllMain`, you should initialize the Nim runtime
## in whatever way suits you best.
when not defined(mdlldkNoDllMain):
  var nimInitialized = false
    ## will be `true` when `initNimImpl()` is called.

  proc NimMain() {.codegenDecl: "N_LIB_EXPORT N_CDECL($1, $2)$3", importc,
                   cdecl.}
    ## Declaration of the function `NimMain()`

  proc initNimImpl() =
    ## Calls the `NimMain()` function, which initializes the Nim runtime.
    NimMain()

    nimInitialized = true

  template initNim*() =
    ## Template that checks if the Nim runtime has already been initialized, if
    ## not, calls `initNimImpl()`.
    ##
    ## This template does nothing when compiled with `-d:mdlldkNoDllMain`.
    if not nimInitialized:
      initNimImpl()
else:
  template initNim*() =
    discard
