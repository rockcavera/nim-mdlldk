## The purpose of this module is just to document the procedures added by the
## `addLoadProc()<../mdlldk.html#addLoadProc.t%2Cbool%2Cbool%2Cuntyped>`_ template.
## 
## **This module must not be imported!**

import ./types

proc mMajor*(): int {.inline.} = discard
  ## Returns the fixed major version of mIRC. Returns `-1` if unable to determine.

proc mMinor*(): int {.inline.} = discard
  ## Returns the fixed minor version of mIRC. Returns `-1` if unable to determine.

proc mBeta*(): int {.inline.} = discard
  ## Returns the beta version of mIRC. Returns `-1` if unable to determine and `0` if it is not a
  ## beta version.

proc mMaxBytes*(): int {.inline.} = discard
  ## Returns the size, in bytes, allocated in the pointers to the `data` and `parms` parameters.

proc mKeepLoaded*(): bool {.inline.} = discard
  ## Returns `true` if mIRC will keep the dll loaded after the call. If it returns `false` mIRC will
  ## unload the dll after the call.

proc mUnicode*(): bool {.inline.} = discard
  ## Returns `true` if the communication between mIRC and the dll will be via unicode strings
  ## (WideCString). If it returns `false` the communication will be by ANSI C strings.

proc mMainWindowHandle*(): HWND {.inline.} = discard
  ## Returns a `HWND` for the identifier of the main window of mIRC. The `HWND` type is an alias for
  ## `int`.

proc mRawVersion*(): uint32 {.inline.} = discard
  ## Returns a `uint32` with the raw version passed by mIRC, in the `mVersion` field, of the
  ## `LoadInfo` object, when loading the dll.
  ## 
  ## **It is recommended to use the** `mMajor()<#mMajor>`_ **and** `mMinor()<#mMinor>`_.

proc mToCStringAndCopy*(dest: pointer|cstring, source: string) {.inline.} = discard
  ## Transforms `source` to `cstring` and copies it to `dest` up to the byte limit of `mMaxBytes()`.

proc mToWideCStringAndCopy*(dest: pointer|WideCString, source: string) = discard
  ## Transforms `source` into `WideCString` and copies it to `dest` up to the byte limit of
  ## `mMaxBytes()`.
