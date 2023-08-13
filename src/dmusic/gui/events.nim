
type
  EventBase = object
    connected: seq[(EventHandler, proc(c: EventHandler, v: int))]
  
  EventHandler* = ref object of RootObj
    connected*: seq[ptr EventBase]

  Event*[T] = object
    ## only EventHandler can be connected to event
    ## one event can be connected to multiple components
    ## one EventHandler can connect to multiple events
    ## one event can be connected to one EventHandler multiple times
    ## connection can be removed, but inf EventHandler connected to event multiple times, they all will be removed
    connected*: seq[(EventHandler, proc(c: EventHandler, v: T))]
  

  Property*[T] = object
    unsafeVal*: T
    changed*: Event[T]

  CustomProperty*[T] = object
    get*: proc(): T
    set*: proc(v: T)
    changed*: Event[T]

  AnyProperty*[T] = Property[T] | CustomProperty[T]


proc property*[T](v: T): Property[T] =
  Property[T](unsafeVal: v)



#* ------------- Event ------------- *#

proc `=destroy`*[T](s: Event[T]) =
  for (c, _) in s.connected:
    var i = 0
    while i < c.connected.len:
      if c.connected[i] == cast[ptr EventBase](s.addr):
        c.connected.del i
      else:
        inc i


proc disconnect*[T](s: var Event[T]) =
  for (c, _) in s.connected:
    var i = 0
    while i < c.connected.len:
      if c.connected[i] == cast[ptr EventBase](s.addr):
        c.connected.del i
      else:
        inc i
  s.connected = @[]

proc disconnect*(c: EventHandler) =
  for s in c.connected.mitems:
    var i = 0
    while i < s.connected.len:
      if s.connected[i][0] == c:
        s.connected.del i
      else:
        inc i
  c.connected = @[]

proc disconnect*[T](s: var Event[T], c: EventHandler) =
  var i = 0
  while i < c.connected.len:
    if c.connected[i] == cast[ptr EventBase](s.addr):
      c.connected.del i
    else:
      inc i
  
  i = 0
  while i < s.connected.len:
    if s.connected[i][0] == c:
      s.connected.del i
    else:
      inc i


proc emit*[T](s: Event[T], v: T) =
  let connected = s.connected
  for (c, f) in connected:
    f(c, v)

proc emit*(s: Event[void]) =
  let connected = s.connected
  for (c, f) in connected:
    f(c)


proc connect*[T](s: var Event[T], c: EventHandler, f: proc(c: EventHandler, v: T)) =
  s.connected.add (c, f)
  c.connected.add cast[ptr EventBase](s.addr)

proc connect*(s: var Event[void], c: EventHandler, f: proc(c: EventHandler)) =
  s.connected.add (c, f)
  c.connected.add cast[ptr EventBase](s.addr)

template connectTo*[T; O: EventHandler](s: var Event[T], obj: O, body: untyped) =
  connect s, obj, proc(c: EventHandler, e {.inject.}: T) =
    let this {.cursor, inject, used.} = cast[O](c)
    body

template connectTo*[O: EventHandler](s: var Event[void], obj: O, body: untyped) =
  connect s, obj, proc(c: EventHandler) =
    let this {.cursor, inject, used.} = cast[O](c)
    body


#* ------------- Property ------------- *#

proc `val=`*[T](p: var Property[T], v: T) =
  ## note: p.changed will be emitted even if new value is same as previous value
  if v == p.unsafeVal: return
  p.unsafeVal = v
  emit p.changed, p.unsafeVal

proc `[]=`*[T](p: var Property[T], v: T) = p.val = v

proc val*[T](p: Property[T]): T = p.unsafeVal
proc `[]`*[T](p: Property[T]): T = p.unsafeVal

proc `{}`*[T](p: var Property[T]): var T = p.unsafeVal
proc `{}=`*[T](p: var Property[T], v: T) = p.unsafeVal = v
  ## same as []=, but does not emit p.changed

converter toValue*[T](p: Property[T]): T = p[]

proc `=copy`*[T](p: var Property[T], v: Property[T]) {.error.}


#* ------------- CustomProperty ------------- *#

proc `val=`*[T](p: var CustomProperty[T], v: T) =
  ## note: p.changed will not be emitted if new value is same as previous value
  if v == p.get(): return
  p.set(v)
  emit p.changed, p.get()

proc `[]=`*[T](p: var CustomProperty[T], v: T) = p.val = v

proc val*[T](p: CustomProperty[T]): T = p.get()
proc `[]`*[T](p: CustomProperty[T]): T = p.get()

proc unsafeVal*[T](p: var CustomProperty[T]): T = p.get()
  ## note: can't get var T due to nature of CustomProperty
proc `{}`*[T](p: var CustomProperty[T]): T = p.get()

proc `unsafeVal=`*[T](p: var CustomProperty[T], v: T) =
  ## same as val=, but always call setter and does not emit p.changed
  p.set(v)

proc `{}=`*[T](p: var CustomProperty[T], v: T) = p.unsafeVal = v

converter toValue*[T](p: CustomProperty[T]): T = p[]

proc `=copy`*[T](p: var CustomProperty[T], v: CustomProperty[T]) {.error.}
