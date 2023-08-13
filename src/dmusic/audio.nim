import locks, times
import miniaudio, miniaudio/futharkminiaudio
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


template wrapError(body: typed) =
  let res = body
  if res != MaSuccess:
    raise newException(MiniAudioError, $res)


proc data_callback(device: ptr ma_device, output: pointer, input: pointer, frameCount: ma_uint32) {.cdecl.} =
  let stream = cast[OutAudioStream](device.pUserdata)
  withLock stream.creationLock:
    withLock stream.getInfoLock:
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
    set: proc(v: float) =
      this.m_position = v.max(0).min(1)
      ma_decoder_seek_to_pcm_frame(this.decoder.addr, (this.m_position * (this.duration[].inMicroseconds / 1_000_000) * this.decoder.outputSampleRate.float).ma_uint64).wrapError,
      # note: looks buggy, but i can do nothing about it
      # note: thats why we need siaud
  )
  initLock result.creationLock
  initLock result.getInfoLock


proc playTrackFromMemory*(stream: OutAudioStream, audio: string) =
  withLock stream.creationLock:
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
