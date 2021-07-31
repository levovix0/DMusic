#pragma once
#include <QMediaContent>

struct AudioMetadata {
  QString title;
  QString artists;
  QString comment;
//  QString album;
};

class AudioTag
{
public:
  AudioTag();
  static void writeMetadata(QString const& file, AudioMetadata const& data);
  static void writeCover(QString const& file, char const* data, unsigned int size);
  static void writeCover(QString const& file, QByteArray const& cover);
  static void writeCover(QString const& file, QUrl const& cover);

  static bool hasCover(QString const& file);
};

