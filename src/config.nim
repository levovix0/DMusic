import codegen/genconfig

genconfig "Config", "Config.hpp", "Config.cpp", "DMusic":  
  bool isClientSideDecorations true
  double volume 0.5

  type NextMode = enum
    NextSequence
    NextShuffle
  
  type LoopMode = enum
    LoopNone
    LoopTrack
    LoopPlaylist
  
  NextMode nextMode NextSequence
  LoopMode loopMode LoopNone

  bool darkTheme true
  bool darkHeader true

  config user, "User":
    dir saveDir "data:user"

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

    get File media(int id): """
      return ym_saveDir().file(QString::number(id) + ".mp3");
    """
    get File cover(int id): """
      return ym_saveDir().file(QString::number(id) + ".png");
    """
    get File metadata(int id): """
      return ym_saveDir().file(QString::number(id) + ".json");
    """
    get File artistCover(int id): """
      return ym_saveDir().file("artist-" + QString::number(id) + ".png");
    """
    get File artistMetadata(int id): """
      return ym_saveDir().file("artist-" + QString::number(id) + ".json");
    """

    int repeatsIfError 1
    bool downloadMedia true
    bool saveCover true
    bool saveInfo true
    CoverQuality coverQuality MaximumCoverQuality
