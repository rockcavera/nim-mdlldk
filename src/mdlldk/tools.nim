## Provides some procedures to facilitate the development of dlls for mIRC.
import ./types

var
  toolsInitialized = false
    ## Will be `true` when `initTools()` has been called.
  rawVersion: uint32
    ## Raw version sent by the `LoadInfo` structure.
  versionMajor = -1
    ## The major version is preset to -1, this value is given as undetermined.
  versionMinor = -1
    ## The manor version is preset to -1, this value is given as undetermined.
  versionBeta = -1
    ## It was only added in v7.51. `-1` for undetermined.
  stringsUnicode = false
    ## By default mIRC loads dlls with ANSI strings.
  keepDllLoaded = false
    ## Before v5.8, dlls were loaded for use and then unloaded.
  maxBytesParms = 900
    ## When support was added for dll to work with mIRC, in version 5.6, the
    ## limit was set at 900 chars (or 900 bytes).
  hMainWindow: int
    ## The window handle to the main mIRC window.

{.push inline, raises: [].}

proc mInitialized*(): bool = toolsInitialized
   ## Returns `true` if the dll was loaded by the template `addLoadProc()` or if
   ## the procedure `initTools()` was called.

proc mMajor*(): int = versionMajor
  ## Returns the fixed major version of mIRC. Returns `-1` if unable to
  ## determine.

proc mMinor*(): int = versionMinor
  ## Returns the fixed minor version of mIRC. Returns `-1` if unable to
  ## determine.

proc mBeta*(): int = versionBeta
  ## Returns the beta version of mIRC. Returns `-1` if unable to determine and
  ## `0` if it is not a beta version.

proc mUnicode*(): bool = stringsUnicode
  ## Returns `true` if the communication between mIRC and the dll will be via
  ## unicode strings (WideCString). If it returns `false` the communication will
  ## be by ANSI C strings.

proc mMaxBytes*(): int = maxBytesParms
  ## Returns the size, in bytes, allocated in the pointers to the `data` and
  ## `parms` parameters.

proc mKeepLoaded*(): bool = keepDllLoaded
  ## Returns `true` if mIRC will keep the dll loaded after the call. If it
  ## returns `false` mIRC will unload the dll after the call.

proc mMainWindowHandle*(): HWND = hMainWindow
  ## Returns a `HWND` for the identifier of the main window of mIRC. The `HWND`
  ## type is an alias for `int`.

proc mRawVersion*(): uint32 = rawVersion
  ## Returns a `uint32` with the raw version passed by mIRC, in the `mVersion`
  ## field, of the `LoadInfo` object, when loading the dll.
  ##
  ## **It is recommended to use the** `mMajor()<#mMajor>`_ **and** `mMinor()<#mMinor>`_.

{.pop.}

proc mToCStringAndCopy*(dest: pointer|cstring, source: string) =
  ## Transforms `source` to `cstring` and copies it to `dest` up to the byte
  ## limit of `mMaxBytes()`.
  var dest = cast[cstring](dest)
  let size = min(len(source), mMaxBytes() - 1)
  copyMem(dest, cstring(source), size)
  dest[size] = '\0'

proc mToWideCStringAndCopy*(dest: pointer|WideCString, source: string) =
  ## Transforms `source` into `WideCString` and copies it to `dest` up to the
  ## byte limit of `mMaxBytes()`.
  var dest = cast[WideCString](dest)
  let
    w = newWideCString(source)
    size = min(len(w) * 2, mMaxBytes() - 2)
  when defined(nimv2):
    copyMem(dest, toWideCString(w), size)
  else:
    copyMem(cast[pointer](dest), cast[pointer](w), size)
  dest[size shr 1] = Utf16Char(0'i16)

proc fixVersion() =
  ## Fixes, when necessary, the major and minor version of mIRC to display in
  ## format from version 6.21. The value of the minor version is padded with
  ## zeros to the right and the major version is corrected, because, in some
  ## cases, it is marked as `0`.
  var
    major = int(rawVersion and 0xFFFF)
    minor = int((rawVersion shr 16) and 0xFFFF)

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

  versionMajor = major
  versionMinor = minor

proc fixMaxBytes() =
  ## Fixes or sets the maximum amount of bytes that can be written to date and
  ## parms strings.
  let
    major = mMajor()
    minor = mMinor()

  if major == 5:
    maxBytesParms = 900
  elif major == 6:
    if minor > 31:
      maxBytesParms = 4096
    else:
      maxBytesParms = 900
  elif major == 7:
    if mUnicode():
      if minor < 53:
        maxBytesParms = 8192
      elif minor < 62:
        maxBytesParms = 16384
      elif minor < 64:
        maxBytesParms = 20480
    else:
      if minor < 53:
        maxBytesParms = 4096
      elif minor < 62:
        maxBytesParms = 8192
      elif minor < 64:
        maxBytesParms = 10240
      else:
        maxBytesParms = maxBytesParms div 2 # The amount of bytes passed in
                                            # mBytes is for data and parms that
                                            # use widestring. It has been
                                            # observed that the size of pointers
                                            # is half mBytes when they are
                                            # cstring.

proc initTools*(info: ptr LoadInfo, keepLoaded, strUnicode: bool) =
  ## Initializes the variables that are used in the functionality procedures of
  ## this module. Must be called in the LoadDll() function. Is called
  ## automatically by the `addLoadProc()` template.
  if not toolsInitialized:
    toolsInitialized = true
    info.mKeep = cint(keepLoaded)
    rawVersion = info.mVersion

    fixVersion()

    hMainWindow = info.mHwnd
    keepDllLoaded = bool(info.mKeep)

    if versionMajor >= 7:
      info.mUnicode = cint(strUnicode)
      stringsUnicode = bool(info.mUnicode)

    if versionMajor > 7 or (versionMajor == 7 and versionMinor >= 51):
      versionBeta = int(info.mBeta)

    if versionMajor > 7 or (versionMajor == 7 and versionMinor >= 64):
      maxBytesParms = int(info.mBytes)

    fixMaxBytes()
