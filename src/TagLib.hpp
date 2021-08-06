#pragma once
#include <taglib/tag.h>
#include <taglib/id3v2tag.h>
#include <taglib/mpegfile.h>
#include <taglib/mpegproperties.h>
#include <taglib/attachedpictureframe.h>
#include <taglib/popularimeterframe.h>

#include <QMediaContent>
#include <QImage>
#include <QFile>

namespace TagLib {
  struct Data {
    QString title, comment;
    QString artists;
    bool liked{false};
    int duration{0};
  };

  struct DataWithCover : Data {
    QByteArray cover;
    QString coverMimeType;
  };

  DataWithCover readTrack(QString path);
  void writeTrack(QString path, Data const& data);
  void writeTrack(QString path, DataWithCover const& data);
}
