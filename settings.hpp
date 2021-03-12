#pragma once
#include <QString>
#include <QObject>
#include <filesystem>
#include "file.hpp"

class Settings : public QObject
{
  Q_OBJECT
public:
  Settings();
  ~Settings();

  static bool isClientSideDecorations();

  static QString ym_token();
  static QString ym_proxyServer();

  static fs::path ym_savePath_();
  static QString ym_savePath();
  static int ym_repeatsIfError();

  static QString ym_mediaPath(int id);
  static QString ym_coverPath(int id);
  static QString ym_metadataPath(int id);
  static QString ym_artistCoverPath(int id);
  static QString ym_artistMetadataPath(int id);

  static QString ym_coverQuality() { return "1000x1000"; };

  Q_PROPERTY(bool isClientSideDecorations READ get_isClientSideDecorations WRITE set_isClientSideDecorations NOTIFY reload)

  Q_PROPERTY(QString ym_token READ get_ym_token WRITE set_ym_token NOTIFY reload)
  Q_PROPERTY(QString ym_proxyServer READ get_ym_proxyServer WRITE set_ym_proxyServer NOTIFY reload)

  Q_PROPERTY(QString ym_savePath READ get_ym_savePath WRITE set_ym_savePath NOTIFY reload)
  Q_PROPERTY(int ym_repeatsIfError READ get_ym_repeatsIfError WRITE set_ym_repeatsIfError NOTIFY reload)

public slots:
  bool get_isClientSideDecorations();
  void set_isClientSideDecorations(bool v);

  QString get_ym_token();
  void set_ym_token(QString v);
  QString get_ym_proxyServer();
  void set_ym_proxyServer(QString v);

  QString get_ym_savePath();
  void set_ym_savePath(QString v);
  int get_ym_repeatsIfError();
  void set_ym_repeatsIfError(int v);

  void reloadFromJson();
  void saveToJson();

signals:
  void reload();

private:
  inline static bool _isClientSideDecorations = true;

  inline static QString _ym_token = "";
  inline static QString _ym_proxyServer = "";
  inline static fs::path _ym_savePath = "yandex/";
  inline static int _ym_repeatsIfError = 1;
};
