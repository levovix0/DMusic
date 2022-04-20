import times, os, filetype, strformat, json, streams, strutils, bitops
import impl, utils

when not defined(linux):
  proc findExistant(s: varargs[string]): string =
    result = s[0]
    for x in s:
      if dirExists x: return x
  const taglibPath = findExistant("C:/taglib", "D:/taglib", "C:/Libraries/taglib", "D:/Libraries/taglib")

const taglibInclude {.strdefine.} =
  when defined(linux): "/usr/include/taglib"
  else:                taglibPath / "include" / "taglib"
const taglibLib {.strdefine.} =
  when defined(linux): ""
  else:                taglibPath / "lib"

{.passc: &"-I{taglibInclude}".}
{.passl: "-ltag -lz".}
when taglibLib != "": {.passl: &"-L{taglibLib}".}
when defined(windows): {.passc: "-DTAGLIB_STATIC".}

type
  TaglibString {.importcpp: "TagLib::String", header: "tag.h".} = object
  TaglibList[T] {.importcpp: "TagLib::List", header: "tag.h".} = object

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
  
  TrackMetadata* = tuple[title, comment, artists: string; liked, disliked: bool; duration: Duration]



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



proc read(_: type MpegFile, filename: string): ptr MpegFile =
  proc impl(filename: cstring): PMpegFile {.importcpp: "new TagLib::MPEG::File(@)", header: "mpegfile.h".}
  impl(filename)

impl PMpegFile:
  proc id3v2Tag(create = false): PId3v2Tag =
    proc impl(this: PMpegFile, create: bool): PId3v2Tag {.importcpp: "#->ID3v2Tag(@)", header: "mpegfile.h".}
    impl(this, create)

  proc destroy {.importcpp: "delete #".}

  proc save {.importcpp: "#->save()".}



impl PId3v2Tag:

  proc `title=`(v: string) =
    proc impl(this: PId3v2Tag, v: TaglibString) {.importcpp: "#->setTitle(#)", header: "id3v2tag.h".}
    impl(this, v)

  proc `comment=`(v: string) =
    proc impl(this: PId3v2Tag, v: TaglibString) {.importcpp: "#->setComment(#)", header: "id3v2tag.h".}
    impl(this, v)

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

proc readZeroTerminatedStr(s: Stream): string =
  while true:
    let c = s.readUint8.char
    if c == '\0': break
    result.add c

proc reverseBytes[T](x: T): T =
  let x = cast[array[T.sizeof, byte]](x)
  var y: array[T.sizeof, byte]
  for i in 0..y.high:
    y[i] = x[^(i + 1)]
  cast[T](y)

proc readReversedUint32(s: Stream): uint32 =
  s.readUint32.reverseBytes

proc to(x: string, t: type): t =
  when t.sizeof == 0: return
  if x.len < t.sizeof: return
  cast[ptr t](x[0].unsafeaddr)[]

proc skip(s: Stream, n: int) =
  s.setPosition(s.getPosition + n)

proc readTagSize(s: Stream): int =
  let n = s.readReversedUint32
  for i in 0..6:
    if n.testBit(i): result.setBit(i)
  for i in 8..8+6:
    if n.testBit(i): result.setBit(i - 1)
  for i in 16..16+6:
    if n.testBit(i): result.setBit(i - 2)
  for i in 24..24+6:
    if n.testBit(i): result.setBit(i - 3)

template readID3v2(filename: string, onFrame: untyped) =
  if not fileExists filename: return
  var s {.inject.} = newFileStream(filename, fmRead)
  if s.isNil: return
  try:
    let head = s.readStr(6)
    let size = s.readTagSize
    if not head.startsWith("ID3"): return

    let version = (head[3].int, head[4].int)
    if version[0] < 2: return

    let extendedHeader = bool(head[5].byte and 0b10)
    if extendedHeader:
      discard s.readStr(s.readReversedUint32.int + 6)
    
    while true:
      if s.atEnd or s.getPosition >= size + 10: break
      let id {.inject.} = s.readStr(4)
      if id == "\0\0\0\0": break
      let size {.inject.} = s.readReversedUint32.int
      s.skip(2)
      let pos {.inject.} = s.getPosition

      onFrame

      s.setPosition(pos + size)

  except: discard
  finally: close s

proc readTrackMetadata*(filename: string): TrackMetadata =
  var
    titleFrameReaded = false
    commentFrameReaded = false
    artistsFrameReaded = false
    dmusicFrameReaded = false

  filename.readID3v2:
    if id == "TIT2" and not titleFrameReaded:
      result.title = s.readStr(size).strip(chars={'\3', '\0'})
      titleFrameReaded = true
    
    elif id in ["COMM", "TIT3"] and not commentFrameReaded:
      result.comment = s.readStr(size).strip(chars={'\3', '\0'})
      if result.comment.startsWith("XXX\0"):
        result.comment = result.comment[4..^1]
      commentFrameReaded = true
    
    elif id == "TPE1" and not artistsFrameReaded:
      result.artists = s.readStr(size).strip(chars={'\3', '\0'}).split("/").join(", ")
      artistsFrameReaded = true

    elif id == "PRIV" and not dmusicFrameReaded:
      let owner = s.readZeroTerminatedStr
      if owner == "DMusic":
        try:
          let data = s.readStr(size - (s.getPosition - pos)).parseJson
          result.liked = data{"liked"}.get(bool)
          result.disliked = data{"disliked"}.get(bool)
          dmusicFrameReaded = true
        except: discard
    
  block readDuration:
    if not fileExists filename: break
    var s = newFileStream(filename, fmRead)
    if s.isNil: break
    try:
      var tagSize = 0
      block skipTag:
        let head = s.readStr(6)
        if not head.startsWith("ID3"): break
        tagSize = s.readTagSize
        s.skip(tagSize)
        
      const bitrates = [
        [ # Version 1
          [0, 32, 64, 96, 128, 160, 192, 224, 256, 288, 320, 352, 384, 416, 448, 0], # layer 1
          [0, 32, 48, 56, 64,  80,  96,  112, 128, 160, 192, 224, 256, 320, 384, 0], # layer 2
          [0, 32, 40, 48, 56,  64,  80,  96,  112, 128, 160, 192, 224, 256, 320, 0], # layer 3
        ], [ # Version 2 or 2.5
          [0, 32, 48, 56, 64, 80, 96, 112, 128, 144, 160, 176, 192, 224, 256, 0], # layer 1
          [0, 8,  16, 24, 32, 40, 48, 56,  64,  80,  96,  112, 128, 144, 160, 0], # layer 2
          [0, 8,  16, 24, 32, 40, 48, 56,  64,  80,  96,  112, 128, 144, 160, 0], # layer 3
        ]
      ]

      const sampleRates = [
        [44100, 48000, 32000, 0], # Version 1
        [22050, 24000, 16000, 0], # Version 2
        [11025, 12000, 8000,  0], # Version 2.5
      ]

      const samplesPerFrames = [
        [384,  384 ], # Layer 1
        [1152, 1152], # Layer 2
        [1152, 576 ], # Layer 3
      ]

      let head = s.readStr(10)

      let version = case (head[1].byte shr 3) and 0x3:
        of 0: 2
        of 2: 1
        of 3: 0
        else: break
      
      let layer = case (head[1].byte shr 1) and 0x3:
        of 1: 2
        of 2: 1
        of 3: 0
        else: break
      
      let bitrate = bitrates[version.min(1)][layer][(head[2].byte shr 4) and 0xF]
      if bitrate == 0: break

      let sampleRate = sampleRates[version][(head[2].byte shr 2) and 0x3]
      if sampleRate == 0: break

      let samplesPerFrame = samplesPerFrames[layer][version.min(1)]

      var size = samplesPerFrame * bitrate * 125 div sampleRate
      if head[2].byte.testBit(2): size += [4, 1, 1][layer]

      let data = s.readStr(128)

      proc find(s: string, sub: string): int =
        result = -1
        for i in 0..(s.high - sub.len):
          block a:
            for j in 0..sub.high:
              if s[i + j] != sub[j]: break a
            return i

      var vbrOffset = data.find("Xing")
      if vbrOffset < 0: vbrOffset = data.find("Info")
      if vbrOffset >= 0:
        let frames = data[vbrOffset + 8 ..< vbrOffset + 12].to(uint32).reverseBytes.int
        result.duration = initDuration(milliseconds = frames * samplesPerFrame * 1000 div sampleRate)
        break
      
      vbrOffset = data.find("VBRI")
      if vbrOffset >= 0:
        let frames = data[vbrOffset + 14 ..< vbrOffset + 18].to(uint32).reverseBytes.int
        result.duration = initDuration(milliseconds = frames * samplesPerFrame * 1000 div sampleRate)
        break
      
      # todo: calculate relative to last frame, not to file size
      result.duration = initDuration(milliseconds = (filename.getFileSize - tagSize) * 8 div bitrate)

    except: discard
    finally: close s

proc readTrackCover*(filename: string): string =
  filename.readID3v2:
    if id == "APIC":
      let size = s.readReversedUint32.int
      discard s.readStr(2)

      discard s.readUint8
      discard s.readZeroTerminatedStr
      discard s.readUint8
      discard s.readZeroTerminatedStr
      return s.readStr(size - (s.getPosition - pos))



proc writeTrackMetadata*(filename: string; data: TrackMetadata, cover = "") =
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

  if coverFrame == nil and cover != "":
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

  if cover != "":
    coverFrame.mime = cast[seq[byte]](cover).match.mime.value
    coverFrame.kind = PictureKind.frontCover
    coverFrame.picture = cover
  
  save file
  destroy file
