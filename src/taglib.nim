import times, os, filetype, strformat, json
import impl, utils

when not defined(linux):
  proc findExistant(s: varargs[string]): string =
    result = s[0]
    for x in s:
      if dirExists x: return x
  const taglibPath = findExistant("C:/taglib", "D:/taglib", "C:/Libraries/taglib", "D:/Libraries/taglib")

const taglibInclude {.strdefine.} =
  when defined(flatpak): "/app/include/taglib"
  elif defined(linux): "/usr/include/taglib"
  else:                taglibPath / "include" / "taglib"
const taglibLib {.strdefine.} =
  when defined(flatpak): "/app/lib"
  elif defined(linux): ""
  else:                taglibPath / "lib"

{.passc: &"-I{taglibInclude}".}
{.passl: "-ltag -lz".}
when taglibLib != "": {.passl: &"-L{taglibLib}".}
when defined(windows): {.passc: "-DTAGLIB_STATIC".}

type
  TaglibString {.importcpp: "TagLib::String", header: "tag.h".} = object
  TaglibList[T] {.importcpp: "TagLib::List", header: "tag.h".} = object
  TaglibByteVector {.importcpp: "TagLib::ByteVector", header: "tag.h".} = object

  MpegFile {.importcpp: "TagLib::MPEG::File", header: "mpegfile.h".} = object
  Id3v2Tag {.importcpp: "TagLib::ID3v2::Tag", header: "id3v2tag.h".} = object
  Frame {.importcpp: "TagLib::ID3v2::Frame", inheritable, header: "id3v2tag.h".} = object
  AttachedPictureFrame {.importcpp: "TagLib::ID3v2::AttachedPictureFrame", header: "attachedpictureframe.h".} = object of Frame
  PrivateFrame {.importcpp: "TagLib::ID3v2::PrivateFrame", header: "privateframe.h".} = object of Frame

  PMpegFile = ptr MpegFile
  PId3v2Tag = ptr Id3v2Tag
  PFrame = ptr Frame
  PAttachedPictureFrame = ptr AttachedPictureFrame
  PPrivateFrame = ptr PrivateFrame

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
  
  TrackMetadata* = tuple[title, comment, artists, cover: string; liked, disliked: bool; duration: Duration]



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
  
  proc asAttachedPictureFrame: PAttachedPictureFrame =
    cast[PAttachedPictureFrame](this)
  
  proc asPrivateFrame: PPrivateFrame =
    cast[PPrivateFrame](this)



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



proc new(_: type PrivateFrame): PPrivateFrame =
  proc impl: PPrivateFrame {.importcpp: "new TagLib::ID3v2::PrivateFrame", header: "privateframe.h".}
  impl()

impl PPrivateFrame:
  proc data: string =
    proc impl(this: PPrivateFrame): TaglibByteVector {.importcpp: "#->data()", header: "privateframe.h".}
    impl(this)
  
  proc `data=`(v: string) =
    proc impl(this: PPrivateFrame, v: cstring, l: cuint) {.importcpp: "#->setData({#, #})", header: "privateframe.h".}
    impl(this, v, v.len.cuint)
  
  proc owner: string =
    proc impl(this: PPrivateFrame): TaglibString {.importcpp: "#->owner()", header: "privateframe.h".}
    impl(this)
  
  proc `owner=`(v: string) =
    proc impl(this: PPrivateFrame, v: cstring) {.importcpp: "#->setOwner({#, TagLib::String::Type::UTF8})", header: "privateframe.h".}
    impl(this, v)
  
  proc asFrame: PFrame =
    cast[PFrame](this)



const coverKinds = {PictureKind.other, PictureKind.frontCover, PictureKind.backCover, PictureKind.illustration}


proc readTrackMetadata*(filename: string): TrackMetadata =
  if not fileExists filename: return
  let file = MpegFile.read(filename)
  let tag = file.id3v2Tag
  if tag == nil: destroy file; return

  result.title = tag.title
  result.comment = tag.comment
  result.artists = tag.artist
  result.duration = file.duration

  var findData = false
  for frame in tag.frames:
    if result.cover.len == 0 and frame.isOf(PAttachedPictureFrame) and frame.asAttachedPictureFrame.kind in coverKinds:
      result.cover = frame.asAttachedPictureFrame.picture
    
    if not findData and frame.isOf(PPrivateFrame) and frame.asPrivateFrame.owner == "DMusic":
      let data = frame.asPrivateFrame.data.parseJson
      result.liked = data{"liked"}.get(bool)
      result.disliked = data{"disliked"}.get(bool)
      findData = true
  
  destroy file


proc readTrackMetadata2*(filename: string): TrackMetadata =
  ## todo: read id3v2 without taglib


proc writeTrackMetadata*(filename: string; data: TrackMetadata, writeCover = true) =
  if not fileExists filename: return
  let file = MpegFile.read(filename)
  let tag = file.id3v2Tag(true)

  tag.title = data.title
  tag.comment = data.comment
  tag.artist = data.artists

  var coverFrame: PAttachedPictureFrame
  var dataFrame: PPrivateFrame

  for frame in tag.frames:
    if coverFrame == nil and frame.isOf(PAttachedPictureFrame) and frame.asAttachedPictureFrame.kind in coverKinds:
      coverFrame = frame.asAttachedPictureFrame
    
    if dataFrame == nil and frame.isOf(PPrivateFrame) and frame.asPrivateFrame.owner == "DMusic":
      dataFrame = frame.asPrivateFrame

  if coverFrame == nil and writeCover:
    coverFrame = AttachedPictureFrame.new
    tag.add coverFrame.asFrame

  if dataFrame == nil:
    dataFrame = PrivateFrame.new
    tag.add dataFrame.asFrame

  dataFrame.owner = "DMusic"
  dataFrame.data = $ %*{
    "liked": data.liked,
    "disliked": data.disliked
  }

  if writeCover:
    coverFrame.mime = cast[seq[byte]](data.cover).match.mime.value
    coverFrame.kind = PictureKind.frontCover
    coverFrame.picture = data.cover
  
  save file
  destroy file
