#include "AudioTag.hpp"
#include <QImage>
#include <QFile>
#include <tag.h>
#include <taglib/id3v2tag.h>
#include <taglib/mpegfile.h>
#include <attachedpictureframe.h>
#include "Download.hpp"

AudioTag::AudioTag()
{

}

void AudioTag::writeMetadata(const QString& file, const AudioMetadata& data)
{
  auto f = TagLib::MPEG::File(file.toUtf8().data());

  auto tag = f.ID3v2Tag(true);
  tag->setTitle(data.title.toUtf8().data());
  tag->setArtist(data.artists.toUtf8().data());
  tag->setComment(data.comment.toUtf8().data());

  f.save();
}

void AudioTag::writeCover(const QString& file, const char* data, unsigned int size)
{
  auto coverFrame = new TagLib::ID3v2::AttachedPictureFrame;
  coverFrame->setType(TagLib::ID3v2::AttachedPictureFrame::Type::FrontCover);
  coverFrame->setMimeType("image/png");
  coverFrame->setPicture({data, size});

  auto f = TagLib::MPEG::File(file.toUtf8().data());

  auto tag = f.ID3v2Tag(true);
  tag->addFrame(coverFrame);

  f.save();
}

void AudioTag::writeCover(const QString& file, const QByteArray& cover)
{
  writeCover(file, cover.data(), cover.size());
}

void AudioTag::writeCover(const QString& file, QUrl const& cover)
{
  if (cover.isLocalFile()) {
    auto f = QFile(cover.path());
    f.open(QIODevice::ReadOnly);
    writeCover(file, f.readAll());
    f.close();
  } else {
    auto d = new Download(cover);
    QObject::connect(d, &Download::finished, [file](QByteArray const& data) {
      writeCover(file, data);
    });
  }
}

bool AudioTag::hasCover(const QString& file)
{
  bool result = false;

  TagLib::MPEG::File* f = new TagLib::MPEG::File(file.toUtf8().data());
  auto tag = f->ID3v2Tag();
  if (tag->isEmpty()) goto defer;

  for (auto&& frame : tag->frameList()) {
    auto cover = dynamic_cast<TagLib::ID3v2::AttachedPictureFrame*>(frame);
    if (cover == nullptr) continue;
    using Type = TagLib::ID3v2::AttachedPictureFrame::Type;
    if (cover->type() == Type::Other || cover->type() == Type::FrontCover || cover->type() == Type::BackCover || cover->type() == Type::Illustration) {
      result = true;
      goto defer;
    }
  }

defer:
  delete f;
  return result;
}
