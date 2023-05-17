type
  Ref*[T] = ref object
    raw*: ptr T


proc cppDestroy(x: pointer) {.importcpp: "delete #".}


proc destroy*[T](x: Ref[T]) =
  if x.raw != nil:
    cppDestroy x.raw
    x.raw = nil


proc toRef*[T](x: ptr T): Ref[T] =
  ## wraps a C++ pointer to Nim ref
  new result, proc(x: Ref[T]) {.nimcall.} =
    if x.raw != nil:
      cppDestroy x.raw
      x.raw = nil
  
  result.raw = x


proc `[]`*[T](x: Ref[T]): var T =
  x.raw[]

proc `[]=`*[T](x: Ref[T], v: T) =
  x.raw[] = v
