import times, os, filetype
import impl

{.passc: "-I/usr/include/taglib".}
{.passl: "-ltag".}

type
  TaglibString {.importcpp: "TagLib::String", header: "tag.h".} = object
  TaglibList[T] {.importcpp: "TagLib::List", header: "tag.h".} = object
  TaglibByteVector {.importcpp: "TagLib::ByteVector", header: "tag.h".} = object

  MpegFile {.importcpp: "TagLib::MPEG::File", header: "mpegfile.h".} = object
  Id3v2Tag {.importcpp: "TagLib::ID3v2::Tag", header: "id3v2tag.h".} = object
  Frame {.importcpp: "TagLib::ID3v2::Frame", inheritable, header: "id3v2tag.h".} = object
  PopularimeterFrame {.importcpp: "TagLib::ID3v2::PopularimeterFrame", header: "popularimeterframe.h".} = object of Frame
  AttachedPictureFrame {.importcpp: "TagLib::ID3v2::AttachedPictureFrame", header: "attachedpictureframe.h".} = object of Frame

  PMpegFile = ptr MpegFile
  PId3v2Tag = ptr Id3v2Tag
  PFrame = ptr Frame
  PPopularimeterFrame = ptr PopularimeterFrame
  PAttachedPictureFrame = ptr AttachedPictureFrame

  PictureKind {.pure.} = enum
    other
    fileIcon
    otherFileIcon
    frontCover
    backCover
    leafletPage
    media
    leadArtist
    artist
    conductor
    band
    composer
    lyricist
    recordingLocation
    duringRecording
    duringPerformance
    movieScreenCapture
    colouredFish
    illustration
    bandLogo
    publisherLogo



#----------- TaglibString -----------#
converter toTablibString(this: string): TaglibString =
  proc impl(data: cstring): TaglibString {.importcpp: "TagLib::String(@, TagLib::String::UTF8)", header: "tag.h".}
  impl(this)

converter `$`(this: TaglibString): string =
  proc impl(this: TaglibString): cstring {.importcpp: "#.toCString(true)", header: "tag.h".}
  $impl(this)



#----------- TaglibList -----------#
converter toSeq[T](this: TaglibList[T]): seq[T] =
  proc len(this: TaglibList): int {.importcpp: "#.size()", header: "tag.h".}
  proc `[]`(this: TaglibList, i: int): var T {.importcpp: "#[#]", header: "tag.h".}
  result.setLen this.len
  for i, v in result.mpairs:
    v = this[i]



#----------- TaglibByteVector -----------#
converter `$`(this: TaglibByteVector): string =
  proc len(this: TaglibByteVector): int {.importcpp: "#.size()", header: "tag.h".}
  proc data(this: TaglibByteVector): cstring {.importcpp: "#.data()", header: "tag.h".}
  result.setLen this.len
  if result.len == 0: return
  copyMem result[0].addr, this.data, result.len



proc read(_: type MpegFile, filename: string): ptr MpegFile =
  proc impl(filename: cstring): PMpegFile {.importcpp: "new TagLib::MPEG::File(@)", header: "mpegfile.h".}
  impl(filename)

impl PMpegFile:
  proc id3v2Tag(create = false): PId3v2Tag =
    proc impl(this: PMpegFile, create: bool): PId3v2Tag {.importcpp: "#->ID3v2Tag(@)", header: "mpegfile.h".}
    impl(this, create)

  proc duration: Duration =
    proc impl(this: PMpegFile): int {.importcpp: "TagLib::MPEG::Properties(#).lengthInMilliseconds()", header: "id3v2tag.h".}
    initDuration(milliseconds=impl(this))

  proc destroy {.importcpp: "delete #".}

  proc save {.importcpp: "#->save()".}



impl PId3v2Tag:
  proc title: string =
    proc impl(this: PId3v2Tag): TaglibString {.importcpp: "#->title()", header: "id3v2tag.h".}
    impl(this)

  proc `title=`(v: string) =
    proc impl(this: PId3v2Tag, v: TaglibString) {.importcpp: "#->setTitle(#)", header: "id3v2tag.h".}
    impl(this, v)

  proc comment: string =
    proc impl(this: PId3v2Tag): TaglibString {.importcpp: "#->comment()", header: "id3v2tag.h".}
    impl(this)

  proc `comment=`(v: string) =
    proc impl(this: PId3v2Tag, v: TaglibString) {.importcpp: "#->setComment(#)", header: "id3v2tag.h".}
    impl(this, v)

  proc artist: string =
    proc impl(this: PId3v2Tag): TaglibString {.importcpp: "#->artist()", header: "id3v2tag.h".}
    impl(this)

  proc `artist=`(v: string) =
    proc impl(this: PId3v2Tag, v: TaglibString) {.importcpp: "#->setArtist(#)", header: "id3v2tag.h".}
    impl(this, v)

  proc frames: seq[PFrame] =
    proc impl(this: PId3v2Tag): TaglibList[PFrame] {.importcpp: "#->frameList()", header: "id3v2tag.h".}
    impl(this)

  proc add(frame: PFrame) =
    proc impl(this: PId3v2Tag, frame: PFrame) {.importcpp: "#->addFrame(#)", header: "id3v2tag.h".}
    impl(this, frame)



impl PFrame:
  proc isOf(t: type): bool =
    proc dyncast[T](this: PFrame): T {.importcpp: "dynamic_cast<'0>(#)".}
    dyncast[t](this) != nil
  
  proc asPopularimeterFrame: PPopularimeterFrame =
    cast[PPopularimeterFrame](this)
  
  proc asAttachedPictureFrame: PAttachedPictureFrame =
    cast[PAttachedPictureFrame](this)



proc new(_: type PopularimeterFrame): PPopularimeterFrame =
  proc impl: PPopularimeterFrame {.importcpp: "new TagLib::ID3v2::PopularimeterFrame", header: "popularimeterframe.h".}
  impl()

impl PPopularimeterFrame:
  proc rating: int =
    proc impl(this: PPopularimeterFrame): cint {.importcpp: "#->rating()", header: "popularimeterframe.h".}
    impl(this).int

  proc `rating=`(v: int) =
    proc impl(this: PPopularimeterFrame, v: cint) {.importcpp: "#->setRating(#)", header: "popularimeterframe.h".}
    impl(this, v.cint)
  
  proc asFrame: PFrame =
    cast[PFrame](this)



proc new(_: type AttachedPictureFrame): PAttachedPictureFrame =
  proc impl: PAttachedPictureFrame {.importcpp: "new TagLib::ID3v2::AttachedPictureFrame", header: "attachedpictureframe.h".}
  impl()

impl PAttachedPictureFrame:
  proc kind: PictureKind =
    proc impl(this: PAttachedPictureFrame): PictureKind {.importcpp: "(int)#->type()", header: "attachedpictureframe.h".}
    impl(this)

  proc `kind=`(v: PictureKind) =
    proc impl(this: PAttachedPictureFrame, v: PictureKind) {.importcpp: "#->setType((TagLib::ID3v2::AttachedPictureFrame::Type)#)", header: "attachedpictureframe.h".}
    impl(this, v)

  proc picture: string =
    proc impl(this: PAttachedPictureFrame): TaglibByteVector {.importcpp: "#->picture()", header: "attachedpictureframe.h".}
    impl(this)

  proc `picture=`(v: string) =
    proc impl(this: PAttachedPictureFrame, v: cstring, l: cuint) {.importcpp: "#->setPicture({#, #})", header: "attachedpictureframe.h".}
    impl(this, v, v.len.cuint)

  proc `mime=`(v: string) =
    proc impl(this: PAttachedPictureFrame, v: TaglibString) {.importcpp: "#->setMimeType(#)", header: "attachedpictureframe.h".}
    impl(this, v)
  
  proc asFrame: PFrame =
    cast[PFrame](this)



const coverKinds = {PictureKind.other, PictureKind.frontCover, PictureKind.backCover, PictureKind.illustration}


proc readTrackMetadata*(filename: string): tuple[title, comment, artists, cover: string; liked: bool; duration: Duration] =
  if not fileExists filename: return
  let file = MpegFile.read(filename)
  let tag = file.id3v2Tag
  if tag == nil: destroy file; return

  result.title = tag.title
  result.comment = tag.comment
  result.artists = tag.artist
  result.duration = file.duration

  var findLiked = false
  for frame in tag.frames:
    if result.cover.len == 0 and frame.isOf(PAttachedPictureFrame) and frame.asAttachedPictureFrame.kind in coverKinds:
      result.cover = frame.asAttachedPictureFrame.picture
    
    if not findLiked and frame.isOf(PPopularimeterFrame):
      result.liked = frame.asPopularimeterFrame.rating > 128
      findLiked = true
  
  destroy file


proc writeTrackMetadata*(filename: string; title, comment, artists, cover: string; liked: bool, writeCover = true) =
  if not fileExists filename: return
  let file = MpegFile.read(filename)
  let tag = file.id3v2Tag(true)

  tag.title = title
  tag.comment = comment
  tag.artist = artists

  var coverFrame: PAttachedPictureFrame
  var likedFrame: PPopularimeterFrame

  for frame in tag.frames:
    if coverFrame == nil and frame.isOf(PAttachedPictureFrame) and frame.asAttachedPictureFrame.kind in coverKinds:
      coverFrame = frame.asAttachedPictureFrame
    
    if likedFrame == nil and frame.isOf(PPopularimeterFrame):
      likedFrame = frame.asPopularimeterFrame

  if coverFrame == nil and writeCover:
    coverFrame = AttachedPictureFrame.new
    tag.add coverFrame.asFrame

  if likedFrame == nil:
    likedFrame = PopularimeterFrame.new
    tag.add likedFrame.asFrame

  likedFrame.rating = if liked: 255 else: 128

  if writeCover:
    coverFrame.mime = cast[seq[byte]](cover).match.mime.value
    coverFrame.kind = PictureKind.frontCover
    coverFrame.picture = cover
  
  save file
  destroy file