# This example exports 4 procedures to the generated dll, which are: `dllInfo`, `getPId`,
# `setTitleBar` and `setIcon`. In addition to creating an alias for the `dllInfo` procedure with the
# name `version`.

# Read the comments to understand and know how to use this dll. Some obvious parts of the code were
# not commented and it is necessary to know the documentation of the mdlldk package.

# Import the mdlldk package.
import mdlldk

# Declares some common usage types in Windows.
# Use as a reference to declare Windows types:
# - https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-dtyp/cca27429-5689-4a16-b2b4-9325d93e4ba2
# - https://docs.microsoft.com/en-us/windows/win32/winprog/windows-data-types
type
  DWORD = uint32 # or cuint
  HANDLE = int # or pointer
  HICON = HANDLE
  LONG_PTR = int
  LPARAM = LONG_PTR
  LPCSTR = cstring # or ptr char
  LRESULT = LONG_PTR
  UINT = uint32 # or cuint
  UINT_PTR = uint
  WPARAM = UINT_PTR

# Define a dll version
const
  ICON_SMALL = WPARAM(0) # https://docs.microsoft.com/en-us/windows/win32/winmsg/wm-seticon
  ICON_BIG = WPARAM(1) # https://docs.microsoft.com/en-us/windows/win32/winmsg/wm-seticon
  UINT_MAX = 0xFFFFFFFF'u32 # https://docs.microsoft.com/en-us/cpp/c-runtime-library/data-type-constants?view=msvc-170
  WM_SETICON = 0x0080'u32 # https://docs.microsoft.com/en-us/windows/win32/winmsg/wm-seticon
  dllVersionMajor = 1 # The major version that we will assign to the dll.
  dllVersionMinor = 0 # The minor version that we will assign to the dll.
  strDllVersion = $dllVersionMajor & "." & $dllVersionMinor # The string version.

# Here begins the declaration of some procedures that will be imported from certain Windows dlls.

# https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-destroyicon
proc destroyIcon(hIcon: HICON): BOOL {.stdcall, importc: "DestroyIcon", dynlib: "User32.dll".}

# https://docs.microsoft.com/en-us/windows/win32/api/shellapi/nf-shellapi-extracticonexa
proc extractIconExA(lpszFile: LPCSTR, nIconIndex: cint, phiconLarge, phiconSmall: ptr HICON, nIcons: UINT): UINT {.stdcall, importc: "ExtractIconExA", dynlib: "Shell32.dll".}

# https://docs.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-getcurrentprocessid
proc getCurrentProcessId(): DWORD {.stdcall, importc: "GetCurrentProcessId", dynlib: "Kernel32.dll".}

# https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-sendmessagea
proc sendMessageA(hWnd: HWND, Msg: UINT, wParam: WPARAM, lParam: LPARAM): LRESULT {.stdcall, importc: "SendMessageA", dynlib: "User32.dll".}

# https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setwindowtexta
proc setWindowTextA(hWnd: HWND, lpString: LPCSTR): BOOL {.stdcall, importc: "SetWindowTextA", dynlib: "User32.dll".}

# Adds procedure LoadDll() and defines that the dll must not continue loaded after use and the
# communication between the dll and mIRC must be by unicode (WideCString).
addLoadProc(false, true):
  discard

# Adds procedure UnloadDll() and defines that mIRC can unload the dll when it is unused for ten
# minutes.
addUnloadProc(RAllowUnload):
  discard

# Displays the dll information in the active mIRC window.
# Use: /dll mircutils.dll dllInfo
newProcToExport(dllInfo):
  result.outData = "echo -a mircutils.dll v" & strDllVersion & " | echo -a Made with mdlldk on Nim - https://github.com/rockcavera/nim-mdlldk"
  result.ret = RCommand

# Returns the mIRC process identifier.
# Use: $dll(mircutils.dll, getPId, $null)
newProcToExport(getPId):
  let pId = getCurrentProcessId()
  if pId > 0:
    result.outData = $pId
  else:
    result.outData = "$false"
  result.ret = RReturn

# Change the text of the title bar of the mIRC main window.
# Use: $dll(mircutils.dll, setTitleBar, <TEXT|$null>)
newProcToExport(setTitleBar):
  if setWindowTextA(mWnd, LPCSTR(data)) > 0:
    result.outData = "$true"
  else:
    result.outData = "$false"
  result.ret = RReturn

# Changes the mIRC icon that is displayed in the title bar, alt + tab and Windows toolbar.
# Use: $dll(mircutils.dll, setIcon, <FILE.ICO>)
newProcToExport(setIcon):
  var
    largeIcon: HICON
    smallIcon: HICON
  
  let rExt = extractIconExA(LPCSTR(data), cint(0), cast[ptr HICON](addr largeIcon),
                            cast[ptr HICON](addr smallIcon), UINT(1))

  if rExt == UINT_MAX or rExt == 0: # If an error occurs, it will return `UINT_MAX`. If no icon is exported, it will return `0`.
    result.outData = "$false"
  else:
    if largeIcon == 0:
      largeIcon = smallIcon
    if smallIcon == 0:
      smallIcon = largeIcon

    smallIcon = cast[HICON](sendMessageA(mWnd, WM_SETICON, ICON_SMALL, cast[LPARAM](smallIcon))) # Send the new icon and return the old one if it exists
    largeIcon = cast[HICON](sendMessageA(mWnd, WM_SETICON, ICON_BIG, cast[LPARAM](largeIcon))) # Send the new icon and return the old one if it exists

    if smallIcon != 0:
      discard destroyIcon(smallIcon) # Destroy the old icon
    if smallIcon != 0:
      discard destroyIcon(largeIcon) # Destroy the old icon

    result.outData = "$true"

  result.ret = RReturn

static:
  # Adds an alias named `version` to the `dllInfo` procedure.
  # Use: /dll mircutils.dll version
  addAliasFor("dllInfo", "version")

# It must be added to the last line of your Nim code to correctly export all symbols to the dll.
exportAllProcs()
