#include "AudioTag.hpp"
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
    QObject::connect(d, &Download::finished, [d, file](QByteArray const& data) {
      writeCover(file, data);
      delete d;
    });
  }
}

bool AudioTag::hasCover(TagLib::MPEG::File& file)
{
  auto tag = file.ID3v2Tag();
  return getCoverTag(tag) != nullptr;
}

bool AudioTag::hasCover(const QString& file)
{
  auto f = TagLib::MPEG::File(file.toUtf8().data());
  return hasCover(f);
}

TagLib::ID3v2::AttachedPictureFrame* AudioTag::getCoverTag(TagLib::ID3v2::Tag* tag)
{
  if (tag->isEmpty()) return nullptr;

  for (auto&& frame : tag->frameList()) {
    auto cover = dynamic_cast<TagLib::ID3v2::AttachedPictureFrame*>(frame);
    if (cover == nullptr) continue;
    using Type = TagLib::ID3v2::AttachedPictureFrame::Type;
    if (cover->type() == Type::Other || cover->type() == Type::FrontCover || cover->type() == Type::BackCover || cover->type() == Type::Illustration)
      return cover;
  }
  return nullptr;
}

QByteArray AudioTag::readCover(const QString& file)
{
  auto f = TagLib::MPEG::File(file.toUtf8().data());
  auto tag = f.ID3v2Tag();
  auto cover = getCoverTag(tag);
  if (cover == nullptr) return {};
  auto pic = cover->picture();
  return {pic.data(), (int)pic.size()};
}
