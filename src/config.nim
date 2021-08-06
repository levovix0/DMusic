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
