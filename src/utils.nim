import unicode, times, sequtils

proc quoted*(s: string): string =
  result.addQuoted s

proc capitalizeFirst*(s: string): string =
  if s.len == 0: return
  $s.runeAt(0).toUpper & s[1..^1]

const
  emptyCover* = "qrc:resources/player/no-cover.svg"

proc ms*(i: int): Duration = initDuration(milliseconds=i)

proc format*(d: Duration, format: static string): string =
  times.format(initDateTime(1, mJan, 0, 0, 0, 0) + d, format)

proc formatTime*(format: static string, ns=0, mis=0, ms=0, s=0, m=0, h=0, d=0): string =
  times.format(initDateTime(1, mJan, 0, 0, 0, 0) + initDuration(ns, mis, ms, s, m, h, d), format)

proc `&`*(x: proc(), f: proc()): proc() =
  ## concatenate procs
  (proc = x(); f())

proc add*(x: var proc(), f: proc()) =
  x = x & f

proc move*[T](x: var seq[T], i, to: int) =
  let a = x[i]
  x.delete i
  x.insert a, to
