{.used.}
when not(defined(nimsuggest) or defined(nimdoc)):
  when not defined(noRes):
    {.warning: "Consider compiling with `-d:noRes`, to avoid the `winim` package linking a resource file".}

  when not defined(i386):
    {.fatal: "Compile with `--cpu:i386`".}

  when not compileOption("app", "lib"):
    {.fatal: "Compile with `--app:lib`".}

  when not compileOption("noMain"):
    {.fatal: "Compile with `--noMain`".}

  const mmArc = defined(gcArc) or defined(gcOrc) or defined(gcAtomicArc)

  when not mmArc:
    when (NimMajor, NimMinor, NimPatch) >= (1, 6, 2):
      when (NimMajor, NimMinor, NimPatch) >= (2, 0, 0):
        {.warning: "Consider compiling with `--mm:arc|orc|atomicArc`".}
      else:
        {.warning: "Consider compiling with `--mm:arc|orc`".}
    else:
      {.warning: "Consider compiling with `--gc:arc|orc`".}

    when not defined(useNimRtl):
      {.fatal: "Compile with `-d:useNimRtl`. See https://nim-lang.org/docs/nimc.html#dll-generation".}
  else:
    when defined(useNimRtl):
      when (NimMajor, NimMinor, NimPatch) >= (1, 6, 2):
        when (NimMajor, NimMinor, NimPatch) >= (2, 0, 0):
          {.warning: "`-d:useNimRtl` is not required for `--mm:arc|orc|atomicArc`".}
        else:
          {.warning: "`-d:useNimRtl` is not required for `--mm:arc|orc`".}
      else:
        {.warning: "`-d:useNimRtl` is not required for `--gc:arc|orc`".}

    when not defined(useMalloc):
      {.warning: "Consider compiling with `-d:useMalloc`".}
