
type
  EventBase = object
    connected: seq[(EventHandlerCursor, proc(v: int) {.closure.})]
  
  EventHandler* = ref object
    connected: seq[ptr EventBase]


  EventHandlerCursor = object
    eh {.cursor.}: EventHandler

  Event*[T] = object
    ## only EventHandler can be connected to event
    ## one event can be connected to multiple components
    ## one EventHandler can connect to multiple events
    ## one event can be connected to one EventHandler multiple times
    ## connection can be removed, but if EventHandler connected to event multiple times, they all will be removed
    connected: ref seq[(EventHandlerCursor, proc(v: T) {.closure.})]



#* ------------- Event ------------- *#

proc destroyEvent(s: ptr EventBase)
proc destroyEventHandler(c: EventHandler)


proc `=destroy`[T](s: Event[T]) =
  if s.connected != nil:
    destroyEvent(cast[ptr EventBase](s.connected[].addr))

proc initIfNeeded[T](s: var Event[T]) =
  if s.connected == nil:
    new s.connected


proc initIfNeeded(c: var EventHandler) =
  if c == nil:
    {.push, warning[Deprecated]: off.}
    new c, destroyEventHandler
    {.pop.}


proc destroyEvent(s: ptr EventBase) =
  for (c, _) in s[].connected:
    var i = 0
    while i < c.eh.connected.len:
      if c.eh.connected[i] == s:
        c.eh.connected.del i
      else:
        inc i

proc destroyEventHandler(c: EventHandler) =
  for s in c.connected:
    var i = 0
    while i < s[].connected.len:
      if s[].connected[i][0].eh == c:
        s[].connected.del i
      else:
        inc i


proc disconnect*[T](s: var Event[T]) =
  if s == nil: return
  for (c, _) in s.connected[]:
    var i = 0
    while i < c.eh.connected.len:
      if c.eh.connected[i] == cast[ptr EventBase](s.connected[].addr):
        c.eh.connected.del i
      else:
        inc i
  s.connected[] = @[]

proc disconnect*(c: var EventHandler) =
  if c == nil: return
  for s in c.connected:
    var i = 0
    while i < s[].connected.len:
      if s[].connected[i][0].eh == c:
        s[].connected.del i
      else:
        inc i
  c.connected = @[]

proc disconnect*[T](s: var Event[T], c: var EventHandler) =
  if s.connected == nil or c == nil: return
  var i = 0
  while i < c.connected.len:
    if c.connected[i] == cast[ptr EventBase](s.connected[].addr):
      c.connected.del i
    else:
      inc i
  
  i = 0
  while i < s.connected[].len:
    if s.connected[][i][0].eh == c:
      s.connected[].del i
    else:
      inc i


proc emit*[T](s: Event[T], v: T) =
  if s.connected == nil: return
  let connected = s.connected[]
  for (_, f) in connected:
    f(v)

proc emit*(s: Event[void]) =
  if s.connected == nil: return
  let connected = s.connected[]
  for (_, f) in connected:
    f()


proc connect*[T](s: var Event[T], c: var EventHandler, f: proc(v: T)) =
  initIfNeeded s
  initIfNeeded c
  s.connected[].add (EventHandlerCursor(eh: c), f)
  c.connected.add cast[ptr EventBase](s.connected[].addr)

proc connect*(s: var Event[void], c: var EventHandler, f: proc()) =
  initIfNeeded s
  initIfNeeded c
  s.connected[].add (EventHandlerCursor(eh: c), f)
  c.connected.add cast[ptr EventBase](s.connected[].addr)

template connectTo*[T](s: var Event[T], obj: var EventHandler, body: untyped) =
  connect s, obj, proc(e {.inject.}: T) =
    body

template connectTo*(s: var Event[void], obj: var EventHandler, body: untyped) =
  connect s, obj, proc() =
    body
