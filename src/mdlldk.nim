## The mdlldk is a Dynamic-link libraries (DLLs) Development Kit for mIRC. The package brings
## templates that add the standard procedures of an mIRC dll, such as: LoadDll() and UnloadDll(); as
## well as facilitating the export of procedures, as it automatically creates the .def file with the
## symbols.
##
## When exporting the LoadDll() procedure with the `addLoadProc()` template, procedures will be
## added that help in the development of your dll. The list of added procedures can be seen
## `here<mdlldk/onlydocumentation.html#12>`_.
##
## The `newProcToExport()` template, which adds a procedure exported to dll and creates an entire
## abstraction to enable it to work in both unicode and non-unicode mIRC, that is, from version 5.6
## (5.60), when support for dlls was added, up to the latest known version of mIRC. If you choose to
## use `newProcToExport()`, it will not be necessary to manually fill in the `data` or `parms`
## parameters, as this is done automatically, safely and without exceeding the size allocated by
## mIRC in the pointers and if it exceeds, it will be truncated to the limit and avoids mIRC
## crashes. This "magic" is done at runtime and according to each mIRC version, as the memory size
## allocated to the `data` and `parms` pointers has changed with the mIRC versions.
##
## There are also the `newProcToExportW()` and `newProcToExportA()` templates, which also add an
## exported procedure to dll, but at a lower level than `newProcToExport()`. In the first template
## the parameters `data` and `parms` will be of type `WideCString`, while in the second they will be
## `cstring`. Even if you use one of these two templates you can also take advantage of safe copying
## for `data` and `parms` using `mToWideCStringAndCopy()` or `mToCStringAndCopy()`. Remembering that
## these last two procedures are only available if the `addLoadProc()` template is called in your
## code.
##
## Finally, the `exportAllProcs()` template facilitates the process of exporting procedures to dll,
## as it generates the .def file with all the symbols that must be exported and links to the dll
## during the linking process.
##
## For more information see the documentation below.
##
## **Current support**
##
## Currently supported with the gcc, clang and vcc compilers, and the C and C++ backends. It is
## advised to use the last version of Nim or the devel version.
##
## **Documentation used as a reference**
## - https://www.mirc.com/help/html/dll.html
## - https://www.mirc.com/versions.txt
## - https://forum.nim-lang.org/t/8897
##
## Basic Use
## =========
## This is a basic commented example:
## ```nim
## # test.nim
## # Import the mdlldk package.
## import pkg/mdlldk
##
## # Adds procedure LoadDll() and defines that the dll must not continue loaded
## # after use and the communication between the dll and mIRC must be by unicode
## # (WideCString).
## addLoadProc(false, true):
##   discard
##
## # Adds procedure UnloadDll() and defines that mIRC can unload the dll when it is
## # unused for ten minutes.
## addUnloadProc(RAllowUnload):
##   discard
##
## # Adds the `test` procedure which can be called from mIRC like this:
## # `/dll test.dll test`
## newProcToExport(test):
##   result.outData = "echo -a Dll test made in Nim " & NimVersion & " for mIRC"
##   result.ret = RCommand
##
## # It must be added to the last line of your Nim code to correctly export all
## # symbols to the dll.
## exportAllProcs()
## ```
## The above code should be compiled as follows:
##
## `nim c --app:lib --cpu:i386 --gc:orc -d:useMalloc -d:release test.nim`
##
## To learn more about compiler options, visit https://nim-lang.org/docs/nimc.html.
##
## In case you want to produce a smaller dll, you can add such switches:
##
## `nim c --app:lib --cpu:i386 --gc:orc -d:useMalloc -d:danger -d:strip --opt:size test.nim`
##
## With this last line my generated dll had only 18.5KB against 139KB of the other one, using the
## Nim 1.6.4 and tdm64-gcc-10.3.0-2 compilers.

import std/[compilesettings, macros, os, tables]

import ./mdlldk/types

when defined(nimdoc):
  import ./mdlldk/onlydocumentation

export types

macro stringify(n: untyped): string =
  ## Turns an identifier name into a string. Taken from https://forum.nim-lang.org/t/1588#9907
  result = newNimNode(nnkStmtList, n)
  result.add(toStrLit(n))

var
  dllProcs {.compileTime.} = initTable[string, int]() # procName, size
    ## Table with the names and size of all procedures that should be exported to the dll.
  dllAliases {.compileTime.} = initTable[string, string]() # aliasName, procName
    ## Table with the name of all aliases that must be made for the exported procedures.

proc staticCreateDir(dir: string): bool {.compileTime.} =
  ## `createDir()` doesn't work at compile time, so this is a hack for Windows. It won't work on a
  ## possible cross build.
  when hostOS == "windows":
    let r = staticExec("cmd /Q /V:ON /C MD " & dir & " >nul 2>&1 & <NUL set /p=!ERRORLEVEL!")
    if r == "0":
      result = true

when defined(clang):
  import std/pegs

  proc clangAbiGnu(): bool {.compileTime.} =
    ## Determines if clang compiler is targeting abi gnu.
    const ccompilerPath = querySetting(SingleValueSetting.ccompilerPath)
    let s = staticExec(ccompilerPath / "clang -v")
    var m: array[4, string]
    if s.contains(peg"'Target:' \s* {( !\- . )*} \- {( !\- . )*} \- {( !\- . )*} \- {( !\n . )*} \n", m):
      result = m[3] == "gnu"

proc pExportAllProcs() {.compileTime.} =
  ## This template must be called at the end of your Nim code so that the .def file can be created
  ## with the name of all the procedures that must be exported to the dll.
  when defined(gcc):
    const
      gnuSymbols = true
      passLWl = false
  elif defined(clang):
    const
      gnuSymbols = clangAbiGnu()
      passLWl = not(gnuSymbols)
  elif defined(vcc):
    const
      gnuSymbols = false
      passLWl = false

  const
    nimcache = querySetting(SingleValueSetting.nimcacheDir)
    projectName = querySetting(SingleValueSetting.projectName)
    defFile = projectName & ".def"
    pathDef = nimcache / defFile

  if not dirExists(nimcache):
    discard staticCreateDir(nimcache)

  var s = "EXPORTS\r\n"

  for name, size in pairs(dllProcs):
    when gnuSymbols:
      add(s, name & "=" & name & "@" & $size & "\r\n")
    else:
      add(s, name & "=_" & name & "@" & $size & "\r\n")
  
  for aliasName, procName in pairs(dllAliases):
    if hasKey(dllProcs, procName):
      let size = dllProcs[procName]
      when gnuSymbols:
        add(s, aliasName & "=" & procName & "@" & $size & "\r\n")
      else:
        add(s, aliasName & "=_" & procName & "@" & $size & "\r\n")

  writeFile(pathDef, s)

  when passLWl:
    {.passL: "-Wl,\"/DEF:" & pathDef & "\"".}
  else:
    {.passL: pathDef.}

proc addProcToExport*(name: string, size: int) {.compileTime.} =
  ## Adds procedure `name`, which has `size` bytes in the parameter list, to be exported to the dll.
  ## 
  ## **Notes**
  ## - Procedures called by mIRC have 24 bytes in the parameter list.
  ## - Don't forget to call the `exportAllProcs()` template at the end of your Nim code.
  ## - Should not use this proc to add procedures created with `newProcToExport()`,
  ##   `newProcToExportW()` and `newProcToExportA()`.
  dllProcs[name] = size

proc addAliasFor*(procName, aliasName: string) {.compileTime.} =
  ## Adds an alias `aliasName` to a procedure `procName` already exported to the dll.
  dllAliases[aliasName] = procName

template exportAllProcs*() =
  ## This template must be called at the end of your Nim code so that the .def file can be created
  ## with the name of all the procedures that must be exported to the dll.
  static:
    pExportAllProcs()

template addLoadProc*(keepLoaded, strUnicode: bool, body: untyped) =
  ## Adds and exports the LoadDll() procedure, which is called when the dll is loaded in mIRC from
  ## version 5.8 onwards. In addition to adding the LoadDll() procedure, which captures and stores
  ## the information passed by mIRC to the dll, through the `LoadInfo` object, it makes some
  ## corrections that facilitate the development of the dll, such as:
  ## - determine the total bytes value allocated to the `data` and `parms` parameters according to
  ##   the mIRC version and string type (`WideCString` or `cstring`), since the `LoadInfo` object
  ##   did not always pass such information.
  ## - to correct and determine the version passed in the `mVersion` field, of the `LoadInfo`
  ##   object, because in some versions the major version of mIRC was passed as 0 and after version
  ##   6.21 mIRC started to adopt the filling with zero to the right of the minor version, which was
  ##   not done previously and caused ambiguity between versions.
  ##
  ## It also adds other Nim procedures to help with development. However, to have access to these
  ## added procedures it is necessary to call the `addLoadProc()` template on a line above the
  ## procedure usage. See the list of added procedures `here<mdlldk/onlydocumentation.html#12>`_.
  ## 
  ## **Template parameters**
  ## - `keepLoaded` sets the `mKeep` field of the `LoadInfo` object, if possible. If it is `true` it
  ##   will keep the dll loaded after being called, however, if it is `false`, the dll will be
  ##   unloaded right after use. See `mKeep` field in `LoadInfo<mdlldk/types.html#LoadInfo>`_.
  ## - `strUnicode` sets the `mUnicode` field of the `LoadInfo` object, if possible. If it is `true`
  ##   the communication between mIRC and dll will be by the use of unicode strings (`WideCString`),
  ##   however, if it is `false`, the communication will be by ANSI strings (`cstring`). See
  ##   `mUnicode` field in `LoadInfo<mdlldk/types.html#LoadInfo>`_.
  ## - `body` passes a code block that will be appended to the end of the LoadDll() procedure. If
  ##   you didn't want to pass any code, use the `discard` keyword.
  static:
    addProcToExport("LoadDll", 4)

  var
    iRawVersion: uint32
      ## Raw version sent by the `LoadInfo` structure.
    iVersionMajor = -1
      ## The major version is preset to -1, this value is given as undetermined.
    iVersionMinor = -1
      ## The manor version is preset to -1, this value is given as undetermined.
    iVersionBeta = -1
      ## It was only added in v7.51. `-1` for undetermined.
    iStringsUnicode = false
      ## By default mIRC loads dlls with ANSI strings.
    iKeepDllLoaded = false
      ## Before v5.8, dlls were loaded for use and then unloaded.
    iMaxBytesParms = 900
      ## When support was added for dll to work with mIRC, in version 5.6, the limit was set at 900
      ## chars (or 900 bytes).
    iHMainWindow: int
      ## The window handle to the main mIRC window.

  {.push inline, used.}

  proc mMajor(): int = iVersionMajor
  proc mMinor(): int = iVersionMinor
  proc mBeta(): int = iVersionBeta
  proc mUnicode(): bool = iStringsUnicode
  proc mMaxBytes(): int = iMaxBytesParms
  proc mKeepLoaded(): bool = iKeepDllLoaded
  proc mMainWindowHandle(): HWND = iHMainWindow
  proc mRawVersion(): uint32 = iRawVersion

  proc mToCStringAndCopy(dest: pointer|cstring, source: string) =
    var dest = cast[cstring](dest)
    let maxBytes = mMaxBytes()
    var size = len(source)
    if size >= maxBytes:
      size = maxBytes - 1
    copyMem(dest, cstring(source), size)
    dest[size] = '\0'

  proc mToWideCStringAndCopy(dest: pointer|WideCString, source: string) =
    var dest = cast[WideCString](dest)
    let
      maxBytes = mMaxBytes()
      w = newWideCString(source)
    var size = len(w) * 2
    if size >= maxBytes:
      size = maxBytes - 2
    when defined(nimv2):
      copyMem(dest, toWideCString(w), size)
    else:
      copyMem(cast[pointer](dest), cast[pointer](w), size)
    dest[size shr 1] = Utf16Char(0'i16)

  {.pop.}

  proc fixVersion() {.gensym.} =
    ## Fixes, when necessary, the major and minor version of mIRC to display in format from version
    ## 6.21. The value of the minor version is padded with zeros to the right and the major version
    ## is corrected, because, in some cases, it is marked as `0`.
    var
      major = int(iRawVersion and 0xFFFF)
      minor = int((iRawVersion shr 16) and 0xFFFF)

    if major == 0:
      if minor in [8, 81, 82, 9, 91]:
        major = 5
        if minor < 10:
          minor = minor * 10
      elif minor in [0, 1, 2, 3]:
        major = 6
    elif major == 6:
      if minor < 10:
        minor = minor * 10

    iVersionMajor = major
    iVersionMinor = minor

  proc fixMaxBytes() {.gensym.} =
    ## Fixes or sets the maximum amount of bytes that can be written to date and parms strings.
    let
      major = mMajor()
      minor = mMinor()

    if major == 5:
      iMaxBytesParms = 900
    elif major == 6:
      if minor > 31:
        iMaxBytesParms = 4096
      else:
        iMaxBytesParms = 900
    elif major == 7:
      if mUnicode():
        if minor < 53:
          iMaxBytesParms = 8192
        elif minor < 62:
          iMaxBytesParms = 16384
        elif minor < 64:
          iMaxBytesParms = 20480
      else:
        if minor < 53:
          iMaxBytesParms = 4096
        elif minor < 62:
          iMaxBytesParms = 8192
        elif minor < 64:
          iMaxBytesParms = 10240
        else:
          iMaxBytesParms = iMaxBytesParms div 2 # The amount of bytes passed in mBytes is for data
                                                # and parms that use widestring. It has been
                                                # observed that the size of pointers is half mBytes
                                                # when they are cstring.

  proc loadDll(info: ptr LoadInfo) {.stdcall, exportc: "LoadDll".} =
    ## mIRC calls the first time you load the dll. `info` provides information about mIRC and can
    ## also change the behavior of the dll by changing fields of type `LoadInfo`. Since mIRC v5.8.
    info.mKeep = cint(keepLoaded)
    iRawVersion = info.mVersion

    fixVersion()

    iHMainWindow = info.mHwnd
    iKeepDllLoaded = bool(info.mKeep)

    if iVersionMajor >= 7:
      info.mUnicode = cint(strUnicode)
      iStringsUnicode = bool(info.mUnicode)

    if iVersionMajor > 7 or (iVersionMajor == 7 and iVersionMinor >= 51):
      iVersionBeta = int(info.mBeta)

    if iVersionMajor > 7 or (iVersionMajor == 7 and iVersionMinor >= 64):
      iMaxBytesParms = int(info.mBytes)

    fixMaxBytes()

    block:
      body

template addUnloadProc*(unused: UnloadReturn, body: untyped) =
  ## Adds and exports the UnloadDll() procedure, which is called when mIRC unloads the dll from
  ## version 5.8 onwards.
  ## 
  ## **Template parameters**
  ## - `unused` determines if the dll will remain loaded or if it can be unloaded by mIRC when not
  ##   in use for ten minutes. See `UnloadReturn<mdlldk/types.html#UnloadReturn>`_.
  ## - `body` passes a code block that will be appended to the end of the UnloadDll() procedure. If
  ##   you didn't want to pass any code, use the `discard` keyword.
  ## 
  ## **Notes**
  ## - The `result` return variable is exposed and can be accessed and modified in `body`.
  ## - The `mTimeout` parameter is marked as `{.inject.}` and can be accessed in `body`. Is of type
  ##   `UnloadMode`. See `UnloadMode<mdlldk/types.html#UnloadMode>`_.
  static:
    addProcToExport("UnloadDll", 4)

  proc unloadDll(mTimeout {.inject.}: UnloadMode): UnloadReturn {.stdcall, exportc: "UnloadDll".} =
    ## mIRC will call when unloading a dll to allow it to clean up. Since mIRC v5.8.
    case mTimeout
    of MManual:
      result = RAllowUnload
    of MUnused:
      result = unused
    of MOnExit:
      result = RAllowUnload

    block:
      body

template newProcToExport*(procname, body: untyped) =
  ## This template facilitates the creation of a new procedure, with the name `procname`, to export
  ## to dll, as it creates an abstraction layer that makes it possible to work in unicode as well as
  ## non-unicode mIRC, that is, it allows for a retroportability up to the mIRC version 5.6, when
  ## dll support was added.
  ##
  ## Also, in this case the `data` parameter is of type `string`, and the `show` and `nopause`
  ## parameters are of type `bool`, providing better compatibility with Nim.
  ##
  ## There is also no need to manipulate pointers to copy command and parameter return into `data`
  ## and `parms`, as this is done in the abstraction layer and truncates them, if necessary, to
  ## avoid crashing mIRC when the strings are longer than the allocated pointers.
  ## 
  ## **Template parameters**
  ## - `procname` is the name of the procedure that will be exported to the dll.
  ## - `body` passes a code block that will be attached to the internal procedure that is called by
  ##   the `procname` procedure.
  ## 
  ## **The internal procedure**
  ## ```nim
  ## proc internalProc(mWnd {.inject.}, aWnd {.inject.}: HWND,
  ##                   data {.inject.}: string,
  ##                   show {.inject.}, nopause {.inject.}: bool):
  ##                  tuple[ret: ProcReturn, outData, outParms: string]
  ##                  {.gensym.} =
  ##   body
  ## ```
  ## Parameters marked with `{.inject.}` are accessed through `body`. See below the description of
  ## each parameter. Already the return value of the internal procedure is
  ## `tuple[ret: ProcReturn, outData, outParms: string]` and will be explained below.
  ## 
  ## **Parameters accessible in body**
  ## - `mWnd` is the handle to the main mIRC window. It is of type `HWND`, which is a `int`.
  ## - `aWnd` is the handle of the window in which the command is being issued, this might not be
  ##   the currently active window if the command is being called by a remote script. It is of type
  ##   `HWND`, which is a `int`.
  ## - `data` is the information sent to the dll. It is of type `string`.
  ## - `show` is `false` if the . prefix was specified to make the command quiet, or `true`
  ##   otherwise. It is of type `bool`.
  ## - `nopause` is `true` if mIRC is in a critical routine and the dll must not do anything that
  ##   pauses processing in mIRC, eg. the dll should not pop up a dialog. It is of type `bool`.
  ## 
  ## **The fields of the internal procedure's return tuple**
  ## - `ret` indicates what mIRC should do. See `ProcReturn<mdlldk/types.html#ProcReturn>`_.
  ## - `outData` can be filled in with a command you want mIRC to perform if any.
  ## - `outParms` can be filled in with the parameters you want mIRC to use when performing the
  ##   command passed in `outData`.
  static:
    addProcToExport(stringify(procname), 24)

  proc internalProc(mWnd {.inject.}, aWnd {.inject.}: HWND,
                    data {.inject.}: string,
                    show {.inject.}, nopause {.inject.}: bool):
                   tuple[ret: ProcReturn, outData, outParms: string] {.gensym.} =
    body

  proc procname(inMWnd, inAWnd: HWND, ptrData, ptrParms: pointer, inShow, inNoPause: BOOL):
               ProcReturn {.stdcall, exportc.} =
    var
      sData: string
      outData, outParms: string

    let isUnicode = mUnicode()

    if isUnicode:
      var wData = cast[WideCString](ptrData)
      sData = $wData
      wData[0] = Utf16Char(0'i16)
    else:
      var cData = cast[cstring](ptrData)
      sData = $cData
      cData[0] = '\0'

    (result, outData, outParms) = internalProc(inMWnd, inAWnd, sData, bool(inShow), bool(inNoPause))

    if isUnicode:
      if len(outData) > 0:
        mToWideCStringAndCopy(ptrData, outData)
      if len(outParms) > 0:
        mToWideCStringAndCopy(ptrParms, outParms)
    else:
      if len(outData) > 0:
        mToCStringAndCopy(ptrData, outData)
      if len(outParms) > 0:
        mToCStringAndCopy(ptrParms, outParms)

template newProcToExportW*(procname, body: untyped) =
  ## This template makes it easy to create a new procedure to export to the dll, but at a lower
  ## level than `newProcToExport()`. In this case the `data` and `parms` parameters are of type
  ## `WideCString`.
  ## 
  ## **The `procname` procedure**
  ## ```nim
  ## proc procname(mWnd {.inject.}, aWnd {.inject.}: HWND,
  ##               data {.inject.}, parms {.inject.}: WideCString,
  ##               show {.inject.}, nopause {.inject.}: BOOL):
  ##              ProcReturn {.stdcall, exportc.} =
  ##   body
  ## ```
  ## Parameters marked with `{.inject.}` are accessed through `body`. See below the description of
  ## each parameter. Already the return value is `ProcReturn`. See
  ## `ProcReturn<mdlldk/types.html#ProcReturn>`_.
  ## 
  ## **`procname` parameters**
  ## - `mWnd` is the handle to the main mIRC window. It is of type `HWND`, which is a `int`.
  ## - `aWnd` is the handle of the window in which the command is being issued, this might not be
  ##   the currently active window if the command is being called by a remote script. It is of type
  ##   `HWND`, which is a `int`.
  ## - `data` is the information that you wish to send to the dll. On return, the dll can fill this
  ##   variable with the command it wants mIRC to perform if any. It is of type `WideCString`.
  ## - `parms` is filled by the dll on return with parameters that it wants mIRC to use when
  ##   performing the command that it returns in the `data` variable. It is of type `WideCString`.
  ## - `show` is FALSE (0) if the . prefix was specified to make the command quiet, or TRUE (1)
  ##   otherwise. It is of type `BOOL`, which is a `cint`.
  ## - `nopause` is TRUE (1) if mIRC is in a critical routine and the dll must not do anything that
  ##   pauses processing in mIRC, eg. the dll should not pop up a dialog. It is of type `BOOL`,
  ##   which is a `cint`.
  static:
    addProcToExport(stringify(procname), 24)

  proc procname(mWnd {.inject.}, aWnd {.inject.}: HWND,
                data {.inject.}, parms {.inject.}: WideCString,
                show {.inject.}, nopause {.inject.}: BOOL): ProcReturn {.stdcall, exportc.} =
    body

template newProcToExportA*(procname, body: untyped) =
  ## This template makes it easy to create a new procedure to export to the dll, but at a lower
  ## level than `newProcToExport()`. In this case the `data` and `parms` parameters are of type
  ## `cstring`.
  ## 
  ## **The `procname`**
  ## ```nim
  ## proc procname(mWnd {.inject.}, aWnd {.inject.}: HWND,
  ##               data {.inject.}, parms {.inject.}: cstring,
  ##               show {.inject.}, nopause {.inject.}: BOOL):
  ##              ProcReturn {.stdcall, exportc.} =
  ##   body
  ## ```
  ## Parameters marked with `{.inject.}` are accessed through `body`. See below the description of
  ## each parameter. Already the return value is `ProcReturn`. See
  ## `ProcReturn<mdlldk/types.html#ProcReturn>`_.
  ## 
  ## **`procname` parameters**
  ## - `mWnd` is the handle to the main mIRC window. It is of type `HWND`, which is a `int`.
  ## - `aWnd` is the handle of the window in which the command is being issued, this might not be
  ##   the currently active window if the command is being called by a remote script. It is of type
  ##   `HWND`, which is a `int`.
  ## - `data` is the information that you wish to send to the dll. On return, the dll can fill this
  ##   variable with the command it wants mIRC to perform if any. It is of type `cstring`.
  ## - `parms` is filled by the dll on return with parameters that it wants mIRC to use when
  ##   performing the command that it returns in the `data` variable. It is of type `cstring`.
  ## - `show` is FALSE (0) if the . prefix was specified to make the command quiet, or TRUE (1)
  ##   otherwise. It is of type `BOOL`, which is a `cint`.
  ## - `nopause` is TRUE (1) if mIRC is in a critical routine and the dll must not do anything that
  ##   pauses processing in mIRC, eg. the dll should not pop up a dialog. It is of type `BOOL`,
  ##   which is a `cint`.
  static:
    addProcToExport(stringify(procname), 24)

  proc procname(mWnd {.inject.}, aWnd {.inject.}: HWND,
                data {.inject.}, parms {.inject.}: cstring,
                show {.inject.}, nopause {.inject.}: BOOL): ProcReturn {.stdcall, exportc.} =
    body
