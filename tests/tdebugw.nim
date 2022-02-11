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
proc estimatePointersSize(d, p: pointer): tuple[d, p: int] =
  const limit = 100_000

  template estimate(x: WideCString, limitPtr: uint, counter: var int) =
    while int16(x[counter]) != 0'i16 and counter < limit and
          cast[uint](unsafeAddr(x[counter])) < limitPtr:
      inc(counter)
    while int16(x[counter]) == 0'i16 and counter < limit and
          cast[uint](unsafeAddr(x[counter])) < limitPtr:
      inc(counter)

  let
    d = cast[WideCString](d)
    p = cast[WideCString](p)
    dAddr = cast[uint](unsafeAddr(d[0]))
    pAddr = cast[uint](unsafeAddr(p[0]))

  if dAddr > pAddr:
    estimate(p, dAddr, result.p)
    estimate(d, high(uint), result.d)
  else:
    estimate(d, pAddr, result.d)
    estimate(p, high(uint), result.p)

  result.d = result.d * 2
  result.p = result.p * 2

# Adds the `debug` procedure which can be called from mIRC like this: `/dll tdebugw.dll debug`.
newProcToExportW(debug):
  var outData = newStringOfCap(mMaxBytes())

  let (dataSizeEstimate, parmsSizeEstimate) = estimatePointersSize(unsafeAddr(data[0]),
                                                                   unsafeAddr(parms[0]))

  add(outData, "echo -ea Dll debug made in Nim " & NimVersion & " for mIRC")
  add(outData, " | echo -ea Compiled with command line: " & querySetting(commandLine))
  add(outData, " | echo -a Parameters accessible in body:")
  add(outData, " | echo -a mWnd: " & $mWnd)
  add(outData, " | echo -a aWnd: " & $aWnd)
  add(outData, " | echo -a data: " & $data)
  add(outData, " | echo -a parms: " & $parms)
  add(outData, " | echo -a show: " & $show)
  add(outData, " | echo -a nopause: " & $nopause)
  add(outData, " | echo -a -")
  add(outData, " | echo -a Address pointed by:")
  add(outData, " | echo -a data: " & $(cast[uint](data)))
  add(outData, " | echo -a parms: " & $(cast[uint](parms)))
  add(outData, " | echo -a -")
  add(outData, " | echo -a Possible pointer size of:")
  add(outData, " | echo -a data: " & $dataSizeEstimate)
  add(outData, " | echo -a parms: " & $parmsSizeEstimate)
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

  mToWideCStringAndCopy(data, outData)

  result = RCommand

# It must be added to the last line of your Nim code to correctly export all symbols to the dll.
exportAllProcs()
