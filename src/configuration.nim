import json, os

let configDir* =
  when defined(linux): getHomeDir() / ".config/DMusic"
  else: "."

let dataDir* =
  when defined(linux): getHomeDir() / ".local/share/DMusic"
  else: "."

converter toJsonNode(x: string): JsonNode = newJString x
converter toJsonNode(x: float): JsonNode = newJFloat x
converter toJsonNode(x: bool): JsonNode = newJBool x
proc get(x: JsonNode, t: type, default = t.default): t =
  try: x.to(t) except: default
converter toJsonNode[T: enum](x: T): JsonNode = %* x

type Config* = distinct JsonNode

converter toJsonNode(x: Config): JsonNode = x.JsonNode
converter toConfig(x: JsonNode): Config = x.Config

proc readConfig*: Config =
  if fileExists(configDir/"config.json"):
    readFile(configDir/"config.json").parseJson
  else: %{:}

proc save*(config: Config) =
  createDir configDir
  writeFile(configDir/"config.json", config.pretty)

var config* = readConfig()


type
  Language* {.pure.} = enum
    en, ru

  LoopMode* {.pure.} = enum
    none, playlist, track


proc language*(config: Config): Language = config{"language"}.get(Language)
proc `language=`*(config: Config, v: Language) = config{"language"} = v; save config

proc volume*(config: Config): float = config{"volume"}.getFloat(0.5)
proc `volume=`*(config: Config, v: float) = config{"volume"} = v; save config

proc shuffle*(config: Config): bool = config{"shuffle"}.getBool
proc `shuffle=`*(config: Config, v: bool) = config{"shuffle"} = v; save config

proc loop*(config: Config): LoopMode = config{"loop"}.get(LoopMode)
proc `loop=`*(config: Config, v: LoopMode) = config{"loop"} = v; save config

proc ym_token*(config: Config): string = config{"Yandex.Music", "token"}.getStr
proc `ym_token=`*(config: Config, v: string) = config{"Yandex.Music", "token"} = v; save config


when isMainModule:
  import codegen/genconfig

  genconfig "Config", "Config.hpp", "Config.cpp", "DMusic":
    type Language = enum
      EnglishLanguage = ""
      RussianLanguage = ":translations/russian"

    type NextMode = enum
      NextSequence
      NextShuffle
    
    type LoopMode = enum
      LoopNone
      LoopTrack
      LoopPlaylist

    Language language EnglishLanguage
    string colorAccentDark "#FCE165"
    string colorAccentLight "#FFA800"

    bool isClientSideDecorations true

    double width 1280
    double height 720
    
    double volume 0.5
    NextMode nextMode NextSequence
    LoopMode loopMode LoopNone

    bool darkTheme true
    bool darkHeader true
    bool themeByTime true

    bool discordPresence false

    config user, "User":
      dir saveDir "data:user"

      get QString trackFile(int id): """
        return user_saveDir().sub(QString::number(id) + ".mp3");
      """

    config ym, "Yandex.Music":
      type CoverQuality = enum
        MaximumCoverQuality  = "1000x1000"
        VeryHighCoverQuality = "700x700"
        HighCoverQuality     = "600x600"
        MediumCoverQuality   = "400x400"
        LowCoverQuality      = "200x200"
        VeryLowCoverQuality  = "100x100"
        MinimumCoverQuality  = "50x50"

      string token
      string email
      string proxyServer

      dir saveDir "data:yandex"

      get QString trackFile(int id): """
        return ym_saveDir().sub(QString::number(id) + ".mp3");
      """

      int repeatsIfError 1
      bool saveAllTracks false
      CoverQuality coverQuality MaximumCoverQuality
