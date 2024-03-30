## Using a custom `DllMain()` was necessary, as the "Dynamic-Link Library Best
## Practices" advises not to perform some tasks within a `DllMain()` function
## and `NimMain()` calls `LoadLibrary()`, which is not recommended.
##
## Therefore, the custom `DllMain()` does not perform any tasks when the dll is
## loaded, but calls `GC_fullCollect()` and `NimDestroyGlobals()` when it is
## unloaded. For more information on when `NimMain()` is called, see the
## `initnim<mdlldk/initnim.html>`_ module.
##
## If you want to add a custom `DllMain()` to your needs, compile with
## `-d:mdlldkNoDllMain`.
##
## References:
## - https://learn.microsoft.com/en-us/windows/win32/dlls/dllmain
## - https://learn.microsoft.com/en-us/windows/win32/dlls/dynamic-link-library-entry-point-function
## - https://learn.microsoft.com/en-us/windows/win32/dlls/dynamic-link-library-best-practices
{.used.}
when not defined(mdlldkNoDllMain):
  from pkg/winim/inc/windef import BOOL, DWORD, HINSTANCE, LPVOID, TRUE, FALSE,
                                   DLL_PROCESS_ATTACH, DLL_PROCESS_DETACH,
                                   DLL_THREAD_ATTACH, DLL_THREAD_DETACH

  when (NimMajor, NimMinor, NimPatch) >= (2, 1, 0):
    proc NimDestroyGlobals() {.codegenDecl: "N_LIB_EXPORT N_CDECL($1, $2)$3",
                               importc, cdecl.}

  proc DllMain(hinstDLL: HINSTANCE, fdwReason: DWORD, lpvReserved: LPVOID): BOOL
              {.exportc, stdcall, noinit.} =
    # `hinstDll`: handle to DLL module
    # `fdwReason`: reason for calling function
    # `lpvReserved`: reserved

    # Perform actions based on the reason for calling.
    case fdwReason
    of DLL_PROCESS_ATTACH:
      # Initialize once for each new process.
      # Return FALSE to fail DLL load.
      result = TRUE # Successful DLL_PROCESS_ATTACH.
    of DLL_THREAD_ATTACH:
      # Do thread-specific initialization.
      discard
    of DLL_THREAD_DETACH:
      # Do thread-specific cleanup.
      discard
    of DLL_PROCESS_DETACH:
      if not isNil(lpvReserved):
        # do not do cleanup if process termination scenario
        discard
      else:
        # Perform any necessary cleanup.
        GC_fullCollect()

        when (NimMajor, NimMinor, NimPatch) >= (2, 1, 1):
          NimDestroyGlobals()
    else:
      discard
