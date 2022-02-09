# Import the std/compilesettings package.
import std/compilesettings

# Import the mdlldk package.
import mdlldk

# Declares the `messageBox` procedure which should call the `MessageBoxA` procedure from the
# `User32.dll` dll.
# https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-messageboxa
proc messageBox(hWnd: HWND, lpText, lpCaption: cstring, uType: cuint): cint
               {.stdcall, importc: "MessageBoxA", dynlib: "User32.dll".}

# Adds procedure LoadDll() and defines that the dll must continue loaded after use and the
# communication between the dll and mIRC must be by unicode (WideCString).
addLoadProc(true, true):
  discard

# Adds procedure UnloadDll() and defines that mIRC can unload the dll when it is unused for ten
# minutes.
addUnloadProc(RAllowUnload):
  let
    msg = "UnloadMode: " & $mTimeout
    title = "Debug"

  discard messageBox(mMainWindowHandle(), cstring(msg), cstring(title), cuint(0'u32))

# This procedure estimates the memory size allocated to a `pointer`.
proc estimatePointerSize(p: pointer): int =
  if mUnicode():
    var p = cast[WideCString](p)
    while int16(p[result]) != 0'i16 and result < 100000:
      inc(result)
    while int16(p[result]) == 0'i16 and result < 100000:
      inc(result)
    result = result * 2
  else:
    var p = cast[cstring](p)
    while p[result] != '\0' and result < 100000:
      inc(result)
    while p[result] == '\0' and result < 100000:
      inc(result)

# Adds the `debug` procedure which can be called from mIRC like this: `/dll tdebug.dll debug`.
proc debug(mWnd, aWnd: HWND, data, parms: pointer, show, nopause: BOOL): ProcReturn {.stdcall,
                                                                                      exportc.} =
  var
    sData: string
    sParms: string
    outData = newStringOfCap(mMaxBytes())
    outParms: string

  let isUnicode = mUnicode()

  if isUnicode:
    var wData = cast[WideCString](data)
    sData = $wData
    sParms = $(cast[WideCString](parms))
    wData[0] = Utf16Char(0'i16)
  else:
    var cData = cast[cstring](data)
    sData = $cData
    sParms = $(cast[cstring](parms))
    cData[0] = '\0'

  add(outData, "echo -ea Dll debug made in Nim " & NimVersion & " for mIRC")
  add(outData, " | echo -ea Compile Command Line: " & querySetting(commandLine))
  add(outData, " | echo -a Parameters:")
  add(outData, " | echo -a mWnd: " & $mWnd)
  add(outData, " | echo -a aWnd: " & $aWnd)
  add(outData, " | echo -a data: " & sData)
  add(outData, " | echo -a parms: " & sParms)
  add(outData, " | echo -a show: " & $show)
  add(outData, " | echo -a nopause: " & $nopause)
  add(outData, " | echo -a -")
  add(outData, " | echo -a Address pointed by:")
  add(outData, " | echo -a data: " & $(cast[uint](addr data)))
  add(outData, " | echo -a parms: " & $(cast[uint](addr parms)))
  add(outData, " | echo -a -")
  add(outData, " | echo -a Possible pointer size of:")
  add(outData, " | echo -a data: " & $estimatePointerSize(data))
  add(outData, " | echo -a parms: " & $estimatePointerSize(parms))
  add(outData, " | echo -a -")
  add(outData, " | echo -a Values returned by:")
  add(outData, " | echo -a mMajor: " & $mMajor())
  add(outData, " | echo -a mMinor: " & $mMinor())
  add(outData, " | echo -a mBeta: " & $mBeta())
  add(outData, " | echo -a mKeepLoaded: " & $mKeepLoaded())
  add(outData, " | echo -a mUnicode: " & $mUnicode())
  add(outData, " | echo -a mMaxBytes: " & $mMaxBytes())
  add(outData, " | echo -a mMainWindowsHandle: " & $mMainWindowHandle())
  add(outData, " | echo -a mRawVersion: " & $mRawVersion())

  if isUnicode:
    if len(outData) > 0:
      mToWideCStringAndCopy(data, outData)
    if len(outParms) > 0:
      mToWideCStringAndCopy(parms, outParms)
  else:
    if len(outData) > 0:
      mToCStringAndCopy(data, outData)
    if len(outParms) > 0:
      mToCStringAndCopy(parms, outParms)

  result = RCommand

# Adds `debug` procedure to be exported.
static:
  addProcToExport("debug", 24)

# It must be added to the last line of your Nim code to correctly export all symbols to the dll.
exportAllProcs()
