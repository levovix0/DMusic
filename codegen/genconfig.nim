import codegen, macros

macro genconfig*(classname, header, source: static[string], body: untyped): untyped =
  echo body.treeRepr
