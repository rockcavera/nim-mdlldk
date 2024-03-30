## This example exports 4 procedures to the generated dll, which are: `dllInfo`,
## `getPId`, `setTitleBar` and `setIcon`. In addition to creating an alias for
## the `dllInfo` procedure with the name `version`.

# Read the comments to understand and know how to use this dll. Some obvious
# parts of the code were not commented and it is necessary to know the
# documentation of the mdlldk package.

# Import the mdlldk package.
import mdlldk

# WINAPI functions, constants and types imported from the `winim` package
from pkg/winim/inc/windef import DWORD, HANDLE, HICON, LONG_PTR, LPARAM, LPCSTR,
                                 LRESULT, UINT, UINT_PTR, WPARAM
from pkg/winim/winstr import winstrConverterStringToPtrChar # To convert `string` to `LPCSTR` (`ptr char`)
from pkg/winim/inc/winuser import DestroyIcon, SendMessageA, SetWindowTextA,
                                  ICON_SMALL, ICON_BIG, WM_SETICON
from pkg/winim/inc/shellapi import ExtractIconExA
from pkg/winim/inc/winbase import GetCurrentProcessId

# Missing constant in `winim` package
const UINT_MAX = UINT(-1) # https://docs.microsoft.com/en-us/cpp/c-runtime-library/data-type-constants?view=msvc-170

# Define a dll version
const
  dllVersionMajor = 1 # The major version that we will assign to the dll.
  dllVersionMinor = 0 # The minor version that we will assign to the dll.
  strDllVersion = $dllVersionMajor & "." & $dllVersionMinor # The string version.

# Adds procedure LoadDll().
addLoadProc(false, true):
  ## The dll must not continue loaded after use and the communication between
  ## the dll and mIRC must be by unicode.
  discard

# Adds procedure UnloadDll().
addUnloadProc(RAllowUnload):
  ## The dll is allowed to unloaded.
  discard

# Adds the `dllInfo` procedure, which can be called from mIRC.
newProcToExport(dllInfo):
  ## Displays the dll information in the active mIRC window.
  ##
  ## Usage: `/dll mircutils.dll dllInfo`
  result.outData = "echo -a mircutils.dll v" & strDllVersion & " | echo -a Made with mdlldk on Nim - https://github.com/rockcavera/nim-mdlldk"
  result.ret = RCommand

# Adds the `getPId` procedure, which can be called from mIRC.
newProcToExport(getPId):
  ## Returns the mIRC process identifier.
  ##
  ## Usage: `$dll(mircutils.dll, getPId, $null)`
  let pId = GetCurrentProcessId()
  if pId > 0:
    result.outData = $pId
  else:
    result.outData = "$false"
  result.ret = RReturn

# Adds the `setTitleBar` procedure, which can be called from mIRC.
newProcToExport(setTitleBar):
  ## Change the text of the title bar of the mIRC main window.
  ##
  ## Usage: `$dll(mircutils.dll, setTitleBar, <TEXT|$null>)`
  if SetWindowTextA(mWnd, LPCSTR(data)) > 0:
    result.outData = "$true"
  else:
    result.outData = "$false"
  result.ret = RReturn

# Adds the `setIcon` procedure, which can be called from mIRC.
newProcToExport(setIcon):
  ## Changes the mIRC icon that is displayed in the title bar, alt + tab and
  ## Windows toolbar.
  ##
  ## Usage: `$dll(mircutils.dll, setIcon, <FILE.ICO>)`
  var
    largeIcon: HICON
    smallIcon: HICON

  let rExt = ExtractIconExA(LPCSTR(data), 0, cast[ptr HICON](addr largeIcon),
                            cast[ptr HICON](addr smallIcon), 1)

  if rExt == UINT_MAX or rExt == 0: # If an error occurs, it will return `UINT_MAX`. If no icon is exported, it will return `0`.
    result.outData = "$false"
  else:
    if largeIcon == 0:
      largeIcon = smallIcon
    if smallIcon == 0:
      smallIcon = largeIcon

    smallIcon = cast[HICON](SendMessageA(mWnd, WM_SETICON, ICON_SMALL, LPARAM(smallIcon))) # Send the new icon and return the old one if it exists
    largeIcon = cast[HICON](SendMessageA(mWnd, WM_SETICON, ICON_BIG, LPARAM(largeIcon))) # Send the new icon and return the old one if it exists

    if smallIcon != 0:
      discard DestroyIcon(smallIcon) # Destroy the old icon
    if smallIcon != 0:
      discard DestroyIcon(largeIcon) # Destroy the old icon

    result.outData = "$true"

  result.ret = RReturn

# Adds an alias named `version` to the `dllInfo` procedure.
addAliasFor(dllInfo, version):
  ## Is an alias of procedure `dllInfo()`.
  ##
  ## Usage: `/dll mircutils.dll version`
  discard

# It must be added to the last line of your Nim code to correctly export all symbols to the dll.
exportAllProcs()
