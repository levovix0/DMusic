import codegen/genconfig

genconfig "Config", "Config.hpp", "Config.cpp":
  imports:
    "IPlaylistRadio.hpp"
  srcimports:
    QDir
  
  bool isClientSideDecorations true
  double volume 0.5
  NextMode {.enum.} nextMode
  LoopMode {.enum.} loopMode

  config "YandexMusicConfig" ym, "Yandex.Music":
    type CoverQuality {.extendNames.} = enum
      Maximum ## "1000x1000"
      VeryHigh ## "700x700"
      High ## "600x600"
      Medium ## "400x400"
      Low ## "200x200"
      VeryLow ## "100x100"
      Minimum ## "50x50"

    string token
    string proxyServer
    string savePath "yandex/":
      get: """
        if (!QDir(`val`).exists())
          QDir::current().mkpath(`val`);
        return QDir(`val`).canonicalPath();
      """
      get rawSavePath: """
        return `val`;
      """
      get mediaPath(int id): """
        return QDir::cleanPath(`get` + QDir::separator() + (QString::number(id) + ".mp3"));
      """
      get coverPath(int id): """
        return QDir::cleanPath(`get` + QDir::separator() + (QString::number(id) + ".png"));
      """
      get metadataPath(int id): """
        return QDir::cleanPath(`get` + QDir::separator() + (QString::number(id) + ".json"));
      """
    int repeatsIfError 1
    bool downloadMedia true
    bool saveCover true
    bool saveInfo true
    CoverQuality coverQuality {.stringGetter.} Maximum
