import unicode, times, sequtils, tables, json

type
  CacheTable*[K, V] = object
    table: Table[K, (V, Time)]
  
  Notification* = seq[proc()]

{.experimental: "callOperator".}


proc quoted*(s: string): string =
  result.addQuoted s

proc capitalizeFirst*(s: string): string =
  if s.len == 0: return
  $s.runeAt(0).toUpper & s[1..^1]

const
  emptyCover* = "qrc:resources/player/no-cover.svg"

proc ms*(i: int): Duration = initDuration(milliseconds=i)

proc format*(d: Duration, format: static string): string =
  times.format(dateTime(1, mJan, 1, 0, 0, 0) + d, format)

proc formatTime*(format: static string, ns=0, mis=0, ms=0, s=0, m=0, h=0, d=0): string =
  times.format(dateTime(1, mJan, 1, 0, 0, 0) + initDuration(ns, mis, ms, s, m, h, d), format)

proc `()`*(n: Notification) =
  for x in n: x()

proc move*[T](x: var seq[T], i, to: int) =
  let a = x[i]
  x.delete i
  x.insert a, to



proc filter[K, V](x: var Table[K, V], f: proc(k: K, v: V): bool) =
  var keys: seq[K]
  for x in x.keys: keys.add x
  for k in keys:
    if not f(k, x[k]):
      x.del k

template filterit[K, V](x: var Table[K, V], body) =
  bind filter
  filter(x, proc(k {.inject.}: K, v {.inject.}: V): bool = body)

proc `[]`*[K, V](this: CacheTable[K, V], k: K): V =
  this.table[k][0]

proc contains*[K, V](this: CacheTable[K, V], k: K): bool =
  this.table.hasKey k

proc setValue*[K, V](this: var CacheTable[K, V], k: K, v: V) =
  this.table[k] = (v, getTime())

template `[]=`*[K, V](this: var CacheTable[K, V], k: K, v: V) =
  let key = k
  if key notin this:
    this.setValue key, v

proc garbageCollect*[K, V](this: var CacheTable[K, V], storeTime: Duration = initDuration(minutes = 1)) =
  let now = getTime()
  this.table.filterit(now - v[1] <= storeTime)


proc get*(x: JsonNode, t: type): t =
  if x == nil: t.default
  else:
    try: x.to(t) except: t.default

proc get*(x: JsonNode, t: type, default: t): t =
  if x == nil: default
  else:
    try: x.to(t) except: default
