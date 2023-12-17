type
  RefObj[T] = object
    raw*: ptr T
  Ref*[T] = ref RefObj[T]


proc cppDestroy(x: pointer) {.importcpp: "delete #".}


proc `=destroy`*[T](x: RefObj[T]) =
  if x.raw != nil:
    cppDestroy x.raw


proc toRef*[T](x: ptr T): Ref[T] =
  ## wraps a C++ pointer to Nim ref
  Ref[T](raw: x)


proc `[]`*[T](x: Ref[T]): var T =
  x.raw[]

proc `[]=`*[T](x: Ref[T], v: T) =
  x.raw[] = v
