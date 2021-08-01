#pragma once
#include <QMediaContent>
#include <QImage>
#include <QFile>
#include <tag.h>
#include <taglib/id3v2tag.h>
#include <taglib/mpegfile.h>
#include <attachedpictureframe.h>

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

  static bool hasCover(TagLib::MPEG::File& file);
  static bool hasCover(QString const& file);

  static TagLib::ID3v2::AttachedPictureFrame* getCoverTag(TagLib::ID3v2::Tag* tag);
  static QByteArray readCover(QString const& file);
};

