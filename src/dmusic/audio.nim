# audio output and track sequence implementation using miniaudio
# note: miniaudio is kinda buggy
# note: seems like miniaudio can't correctly play tracks with idv2 tags  # todo: find workaround

import locks, times, os, sequtils, strutils, options, random, algorithm, asyncdispatch
import miniaudio, miniaudio/futharkminiaudio
import ./[api, configuration]
import ./yandexMusic except Track, Radio, toRadio
import gui/[events]

type
  AudioStreamState* = enum
    paused
    playing

  OutAudioStream* = ref object of EventHandler
    volume*: CustomProperty[float]
    state*: Property[AudioStreamState]
    atEnd*: Event[void]
    position*: CustomProperty[float]  # in 0..1
    duration*: Property[Duration]
    
    m_position: float
    m_volume: float
    engine: AudioEngine
    decoder: ma_decoder
    device: ma_device
    creationLock, getInfoLock: Lock
    eventsToEmit: tuple[stateChanged, atEnd, positionChanged: bool]
    hasPlayingTrack: bool

  TrackSequence* = ref object of EventHandler
    current*: int
    yandexId*: (int, int)
    case isRadio*: bool
    of false:
      tracks*: seq[Track]
      history*: seq[int]
      shuffle*, loop*: bool
    of true:
      radio*: Radio
      radioHistory*: seq[Track]


template wrapError(body: typed) =
  let res = body
  if res != MaSuccess:
    raise newException(MiniAudioError, $res)


proc data_callback(device: ptr ma_device, output: pointer, input: pointer, frameCount: ma_uint32) {.cdecl.} =
  let stream = cast[OutAudioStream](device.pUserdata)
  withLock stream.creationLock:
    if stream.getInfoLock.tryAcquire:
      defer: stream.getInfoLock.release
      case stream.state[]
      of playing:
        let state = ma_decoder_read_pcm_frames(stream.decoder.addr, output, frameCount, nil)
        case state
        of MaSuccess:
          stream.m_position = stream.m_position + frameCount.int / stream.decoder.outputSampleRate.int / (stream.duration[].inMicroseconds / 1_000_000)
          stream.eventsToEmit.positionChanged = true
        of MaAtEnd:
          stream.m_position = 0
          stream.eventsToEmit.positionChanged = true
          stream.eventsToEmit.stateChanged = true
          stream.eventsToEmit.atEnd = true
          stream.state{} = paused
        else: wrapError state
        
        let output = cast[ptr UncheckedArray[float32]](output)
        let volume = stream.m_volume * stream.m_volume
        
        for i in 0..<(frameCount * 2):  #? wtf why multipliying by 2? float32 is 4 bytes, but 1 nor 4 don't work
          output[i] = output[i] * volume
      else: discard


proc newOutAudioStream*(): OutAudioStream =
  new result
  result.engine = new AudioEngine
  let this = result
  result.volume = CustomProperty[float](
    get: proc(): float = this.m_volume,
    set: proc(v: float) = this.m_volume = v.max(0).min(1),
  )
  result.position = CustomProperty[float](
    get: proc(): float = this.m_position,
    set: (proc(v: float) =
      withLock this.getInfoLock:
        this.m_position = v.max(0).min(1)
        ma_decoder_seek_to_pcm_frame(this.decoder.addr, (this.m_position * (this.duration[].inMicroseconds / 1_000_000) * this.decoder.outputSampleRate.float).ma_uint64).wrapError
    ),
  )
  initLock result.creationLock
  initLock result.getInfoLock


proc playTrackFromMemory*(stream: OutAudioStream, audio: string) =
  withLock stream.creationLock:
    if stream.hasPlayingTrack:
      wrapError ma_device_stop(stream.device.addr)
      ma_device_uninit(stream.device.addr)
      wrapError ma_decoder_uninit(stream.decoder.addr)
    
    stream.hasPlayingTrack = true
    stream.m_position = 0

    wrapError ma_decoder_init_memory(audio[0].addr, audio.len.csize_t, nil, stream.decoder.addr)
    doassert stream.decoder.outputFormat == maformatf32
    var length: ma_uint64
    wrapError ma_decoder_get_length_in_pcm_frames(stream.decoder.addr, length.addr)
    let lenInSecs = length.int / stream.decoder.outputSampleRate.int
    stream.duration[] = initDuration(seconds = lenInSecs.int, microseconds = (lenInSecs * 1_000_000).int mod 1_000_000)
    
    var deviceConfig = ma_device_config_init(ma_device_type_playback)
    deviceConfig.playback.format = stream.decoder.outputFormat
    deviceConfig.playback.channels = stream.decoder.outputChannels
    deviceConfig.sampleRate = stream.decoder.outputSampleRate
    deviceConfig.dataCallback = data_callback
    deviceConfig.pUserdata = cast[pointer](stream)
    
    wrapError ma_device_init(nil, deviceConfig.addr, stream.device.addr)
  wrapError ma_device_start(stream.device.addr)


proc emitEvents*(stream: OutAudioStream) =
  ## since miniaudio works in other thread, we need to sync before emitting events
  withLock stream.getInfoLock:
    if stream.eventsToEmit.stateChanged:
      stream.state.changed.emit(stream.state[])
      stream.eventsToEmit.stateChanged = false
    if stream.eventsToEmit.atEnd:
      stream.atEnd.emit()
      stream.eventsToEmit.atEnd = false
    if stream.eventsToEmit.positionChanged:
      stream.position.changed.emit(stream.position[])
      stream.eventsToEmit.positionChanged = false


proc curr*(x: TrackSequence): Track =
  try:
    if x.isRadio:
      if x.current < x.radioHistory.len:
        x.radioHistory[x.current]
      else:
        x.radio.current
    else:
      if x.shuffle: x.tracks[x.history[x.current]]
      else: x.tracks[x.current]
  except: nil

proc next*(x: TrackSequence, totalPlayedSeconds: int, skip=true): Future[Track] {.async.} =
  if x.isRadio:
    if x.current >= x.radioHistory.len:
      x.radioHistory.add x.radio.current
      if skip:
        x.radio.skip(totalPlayedSeconds).await
      else:
        x.radio.next(totalPlayedSeconds).await

      if config.ym_skipRadioDuplicates:
        let history = x.radioHistory.mapit(it.id)
        for i in 1..10:
          if x.radio.current.id in history:
            when defined(debugYandexMusicBehaviour):
              logger.log(lvlInfo, "[debugYandexMusicBehaviour] skip in radio: ", x.curr.id)
            x.radio.skip(1).await

    inc x.current
    return x.curr
  else:
    if x.shuffle:
      if x.current > x.history.high: return Track()
      x.history.delete 0
      x.history.add:
        toSeq(0..x.tracks.high)
        .filterit(it notin x.history[^(x.tracks.len div 2)..^1])
        .sample
      return x.tracks[x.history[x.current]]
    else:
      inc x.current
      if x.current > x.tracks.high:
        if x.loop: x.current = 0
      if x.current notin 0..x.tracks.high:
        return Track()
      else:
        return x.tracks[x.current]

proc prev*(x: TrackSequence): Track =
  if x.isRadio:
    if x.current < 1:
      return Track()
    dec x.current
    return x.curr
  else:
    if x.shuffle:
      if x.current > x.history.high: return Track()
      x.history.del x.history.high
      x.history.insert:
        toSeq(0..x.tracks.high)
        .filterit(it notin x.history[0..<(x.tracks.len div 2)])
        .sample
      return x.tracks[x.history[x.current]]
    else:
      dec x.current
      if x.current < 0:
        if x.loop: x.current = x.tracks.high
      if x.current notin 0..x.tracks.high:
        return Track()
      else:
        return x.tracks[x.current]

proc shuffle(x: TrackSequence, current = -1) =
  if x.isRadio: return
  if x.shuffle: return
  x.shuffle = true
  if x.tracks.len == 0: return
  
  var
    h1 = toSeq(0..x.tracks.high)
    h2 = toSeq(0..x.tracks.high)
    current =
      if current in 0..x.tracks.high: current
      else: rand(x.tracks.high)
  
  shuffle h1
  if current in h1[^(x.tracks.len div 2)..^1]: reverse h1
  shuffle h2
  if current in h2[0..<(x.tracks.len div 2)]: reverse h1
  
  x.history = h1 & @[current] & h2
  x.current = x.tracks.len

proc unshuffle(x: TrackSequence, current = 0) =
  if x.isRadio: return
  if x.shuffle == false: return
  x.shuffle = false
  
  x.history = @[]
  x.current = current


proc initTrackSequence*(sequence: TrackSequence) =
  config.shuffle.changed.connectTo sequence:
    if e:
      shuffle(this, this.current)
    else:
      try: unshuffle(this, this.history[this.current])
      except: discard

  config.loop.changed.connectTo sequence:
    if not this.isRadio:
      this.loop = config.loop == LoopMode.playlist

  if not sequence.isRadio: 
    if config.shuffle: shuffle sequence
    sequence.loop = config.loop == LoopMode.playlist
