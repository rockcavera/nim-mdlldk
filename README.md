This package is a Dynamic-link libraries (DLLs) Development Kit for mIRC.

But why use this package and the Nim programming language to create dlls for mIRC?

Well, if you don't know the Nim programming language, I invite you to visit the site (https://nim-lang.org/) that has a description and possible reasons for you to venture into it. However, I will give my view here. Nim is an easy language to start and evolve, but there are also advanced features that need more effort. Provides C-like performance. It has several backends (C, C++, Objective C and Javascript) making it possible to work in both backend and frontend development. It offers a bidirectional interface with the target backend, making it possible to call code from the backend to Nim or call the Nim code from the backend. In theory it compiles for any architecture and operating system that supports C (may need minor tweaks). There are several methods for managing memory (garbage collectors), but the preferred one for mIRC dlls is ARC. Finally, I could not fail to mention the package manager Nimble, which facilitates the installation of new packages that extend the language.

The mdlldk package brings templates that add the standard procedures of an mIRC dll, such as: LoadDll() and UnloadDll(); as well as facilitating the export of procedures, as it automatically creates the .def file with the symbols.

When exporting the LoadDll() procedure with the `addLoadProc()` template, procedures will be added that help in the development of your dll.

There is also the `newProcToExport()` template, which adds a procedure exported to dll and creates an entire abstraction to enable it to work in both unicode and non-unicode mIRC, that is, from version 5.6 (5.60), when support for dlls was added , up to the latest known version of mIRC. If you choose to use `newProcToExport()`, it will not be necessary to manually fill in the `data` or `parms` parameters, as this is done automatically, safely and without exceeding the size allocated by mIRC in the pointers. If it exceeds, it will be truncated to the limit. This avoids mIRC crashes. This "magic" is done at runtime and according to each mIRC version, as the memory size allocated to the `data` and `parms` pointers has changed with the mIRC versions.

There are also the `newProcToExportW()` template, in which `data` and `parms` parameters are `WideCString`, and `newProcToExportA()` template, in which `data` and `parms` parameters are `cstring`, which also add an exported procedure to dll, but at a lower level than `newProcToExport()`. However, if your choice is `newProcToExportW()` or `newProcToExportA()` you can also take advantage of safe copying for `data` and `parms` using `mToWideCStringAndCopy()` or `mToCStringAndCopy()`. Remembering that these last two procedures are only available if the `addLoadProc()` template is called in your code.

Finally, the `exportAllProcs()` template facilitates the process of exporting procedures to dll, as it generates the .def file with all the symbols that must be exported and links to the dll during the linking process.

Currently supported with the gcc, clang and vcc compilers, and the C and C++ backends. It is advised to use the most current version of Nim or the devel version.

Documentation used as a reference: https://www.mirc.com/help/html/dll.html.

# Install
`nimble install mdlldk`

or

`nimble install https://github.com/rockcavera/nim-mdlldk.git`

# Basic Use
This is a basic commented example:
```nim
# test.nim
# Import the mdlldk package.
import pkg/mdlldk

# Adds procedure LoadDll() and defines that the dll must not continue loaded
# after use and the communication between the dll and mIRC must be by unicode
# (WideCString).
addLoadProc(false, true):
  discard

# Adds procedure UnloadDll() and defines that mIRC can unload the dll when it is
# unused for ten minutes.
addUnloadProc(RAllowUnload):
  discard

# Adds the `test` procedure which can be called from mIRC like this:
# `/dll test.dll test`
newProcToExport(test):
  result.outData = "echo -a Dll test made in Nim " & NimVersion & " for mIRC"
  result.ret = RCommand

# It must be added to the last line of your Nim code to correctly export all
# symbols to the dll.
exportAllProcs()
```
The above code should be compiled as follows:

`nim c --app:lib -d:release --cpu:i386 --gc:arc test.nim`

To learn more about compiler options, visit https://nim-lang.org/docs/nimc.html.

In case you want to produce a smaller dll, you can add such switches:

`nim c --app:lib -d:danger -d:useMalloc -d:strip --opt:size --cpu:i386 --gc:arc test.nim`

With this last line my generated dll had only 17KB against 285KB of the other one, using the tdm64-gcc-10.3.0-2 compiler.

# Documentation
https://rockcavera.github.io/nim-mdlldk/mdlldk.html
