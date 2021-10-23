import asyncdispatch
export asyncdispatch

template then*(x: Future, body) =
  x.addCallback(proc(res: typeof(x)) {.closure, gcsafe.} =
    let res {.inject.} = read res
    body
  )


proc cancel*(x: Future) =
  if x == nil or x.finished: return
  clearCallbacks x
  fail x, CatchableError.newException("Canceled")

proc cancel*(x: openarray[Future]) =
  for f in x: cancel f


template doAsync*(body): Future =
  (proc {.async.} = body)()


template await*(x: seq[Future]) =
  for f in x: await f
