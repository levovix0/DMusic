import tables, times

proc filter[K, V](x: var Table[K, V], f: proc(k: K, v: V): bool) =
  var keys: seq[K]
  for x in x.keys: keys.add x
  for k in keys:
    if not f(k, x[k]):
      x.del k

template filterit[K, V](x: var Table[K, V], body) =
  bind filter
  filter(x, proc(k {.inject.}: K, v {.inject.}: V): bool = body)


type CacheTable*[K, V] = object
  table: Table[K, (V, Time)]

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

