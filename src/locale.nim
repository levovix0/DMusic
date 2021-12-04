when defined(windows):
  type
    TLocaleName = enum
      # Numbers are based on hex codes for their respective language in the WinAPI.
      # See MSDN -> http://msdn.microsoft.com/en-us/library/dd318693(v=VS.85).aspx
      Chinese = 4,
      German = 7,
      English = 9,
      Spanish = 10,
      Japanese = 11,
      French = 12,
      Italian = 16,
      Polish = 21
  proc GetUserDefaultLangID(): int {.importc, dynlib: "Kernel32.dll".}

  proc systemLocale*: tuple[lang, variant: string] =
    let lang = TLocaleName(GetUserDefaultLangID() and 0x00FF)
    case lang
    of Chinese: ("zh", "")
    of German: ("de", "")
    of English: ("en", "")
    of Spanish: ("es", "")
    of Japanese: ("ja", "")
    of French: ("fr", "")
    of Italian: ("it", "")
    of Polish: ("pl", "")
    else: ("en", "")

else:
  import os, strutils

  proc systemLocale*: tuple[lang, variant: string] =
    ## get system locale
    ## format "en_US.UTF-8" -> ("en", "us")
    var lang = getEnv("LANG", "en_US.UTF-8")
    if lang.endsWith(".UTF-8"):
      lang = lang[0..^7]
    let l = lang.split("_")
    (l[0].toLower, l[1..^1].join("_").toLower)
