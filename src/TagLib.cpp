#include "TagLib.hpp"

#include <stdexcept>

#include <QMimeDatabase>

#include "Download.hpp"
#include "nimfs.hpp"

TagLib::DataWithCover TagLib::readTrack(QString path)
{
  DataWithCover res;
  if (!fileExists(path)) throw std::runtime_error("file not exist");

  auto file = TagLib::MPEG::File(path.toUtf8());
  auto tag = file.ID3v2Tag();
  if (tag == nullptr) return res;

  auto toString = [](TagLib::String const& s) -> QString { return QString::fromUtf8(s.toCString(true)); };

  res.title = toString(tag->title());
  res.comment = toString(tag->comment());
  res.duration = TagLib::MPEG::Properties(&file).lengthInMilliseconds();
  res.artists = toString(tag->artist());

  bool findLiked = false, findCover = false;
  for (auto&& frame : tag->frameList()) {
    using Type = TagLib::ID3v2::AttachedPictureFrame::Type;

    if (auto popularityFrame = dynamic_cast<TagLib::ID3v2::PopularimeterFrame*>(frame); !findLiked && popularityFrame != nullptr) {
      res.liked = popularityFrame->rating() > 128;
      findLiked = true;
    }
    else if (auto cover = dynamic_cast<TagLib::ID3v2::AttachedPictureFrame*>(frame);
        !findCover && cover != nullptr && (cover->type() == Type::Other || cover->type() == Type::FrontCover || cover->type() == Type::BackCover || cover->type() == Type::Illustration)) {
      auto pic = cover->picture();
      res.cover = QByteArray{pic.data(), (int)pic.size()};
      res.coverMimeType = toString(cover->mimeType());
      findCover = true;
    }
  }
  return res;
}

void TagLib::writeTrack(QString path, Data const& data)
{
  auto toString = [](QString const& s) -> TagLib::String {
    return TagLib::String(s.toUtf8().data(), TagLib::String::UTF8);
  };
  if (!fileExists(path)) return;

  auto file = TagLib::MPEG::File(path.toUtf8());
  auto tag = file.ID3v2Tag(true);
  tag->setTitle(toString(data.title));
  tag->setComment(toString(data.comment));
  tag->setArtist(toString(data.artists));

  // find frames
  TagLib::ID3v2::PopularimeterFrame* ratingFrame = nullptr;
  for (auto&& frame : tag->frameList()) {
    if (auto rating = dynamic_cast<TagLib::ID3v2::PopularimeterFrame*>(frame); rating != nullptr && ratingFrame == nullptr) {
      ratingFrame = rating;
    }
  }

  // add raiting (liked/not liked)
  if (ratingFrame == nullptr) {
    ratingFrame = new TagLib::ID3v2::PopularimeterFrame();
    tag->addFrame(ratingFrame);
  }
  ratingFrame->setRating(data.liked? 255 : 128);

  file.save();
}

void TagLib::writeTrack(QString path, DataWithCover const& data)
{
  auto toString = [](QString const& s) -> TagLib::String {
    return TagLib::String(s.toUtf8().data(), TagLib::String::UTF8);
  };
  if (!fileExists(path)) return;

  auto file = TagLib::MPEG::File(path.toUtf8());
  auto tag = file.ID3v2Tag(true);
  tag->setTitle(toString(data.title));
  tag->setComment(toString(data.comment));
  tag->setArtist(toString(data.artists));

  // find frames
  TagLib::ID3v2::AttachedPictureFrame* coverFrame = nullptr;
  TagLib::ID3v2::PopularimeterFrame* ratingFrame = nullptr;
  for (auto&& frame : tag->frameList()) {
    using Type = TagLib::ID3v2::AttachedPictureFrame::Type;
    if (auto cover = dynamic_cast<TagLib::ID3v2::AttachedPictureFrame*>(frame); cover != nullptr && coverFrame == nullptr
        && (cover->type() == Type::Other || cover->type() == Type::FrontCover || cover->type() == Type::BackCover || cover->type() == Type::Illustration)) {
      coverFrame = cover;
    }
    else if (auto rating = dynamic_cast<TagLib::ID3v2::PopularimeterFrame*>(frame); rating != nullptr && ratingFrame == nullptr) {
      ratingFrame = rating;
    }
  }

  // add raiting (liked/not liked)
  if (ratingFrame == nullptr) {
    ratingFrame = new TagLib::ID3v2::PopularimeterFrame();
    tag->addFrame(ratingFrame);
  }
  ratingFrame->setRating(data.liked? 255 : 128);

  // add cover
  if (coverFrame == nullptr) {
    coverFrame = new TagLib::ID3v2::AttachedPictureFrame();
    tag->addFrame(coverFrame);
  }
  auto coverMime = data.coverMimeType;
  if (coverMime.isEmpty()) {
    auto mime = QMimeDatabase().mimeTypeForData(data.cover);
    coverMime = mime.name();
  }
  coverFrame->setMimeType(toString(coverMime));
  coverFrame->setType(TagLib::ID3v2::AttachedPictureFrame::Type::FrontCover);
  coverFrame->setPicture({data.cover.data(), (unsigned int)data.cover.length()});

  file.save();
}
