import strformat

type
  Module* = ref object
    namespaces*: seq[Namespace]
    classes*: seq[Class]
    functions*: seq[Function]
    # prvateNamespaces*: seq[Namespace]
    # privateClasses*: seq[Class]
    # privateFunctions*: seq[Function]
  Namespace* = ref object
    classes*: seq[Class]
    functions*: seq[Function]
  Class* = ref object of RootObj
    publicFields*: seq[Field]
    publicMethods*: seq[Function]
    protectedFields*: seq[Field]
    protectedMethods*: seq[Function]
    privateFields*: seq[Field]
    privateMethods*: seq[Function]
  Function* = ref object of RootObj
    name: string
    `type`: string
    args: seq[Variable]
  Field* = ref object of Variable
  Variable* = ref object
    name: string
    `type`: string

  Statement* = ref object of RootObj
    line: string

  QClass* = ref object of Class
    properties*: seq[QProperty]
    signals*: seq[QSignal]
    publicSlots*: seq[Function]
    protectedSlots*: seq[Function]
    privateSlots*: seq[Function]
  QProperty* = ref object
  QSignal* = ref object


proc newStatement(line: string): Statement =
  new result
  result.line = line

converter toString(this: Statement): string = &"{this.line};"


proc newVariable(name: string, `type` = "auto"): Variable =
  new result
  result.name = name
  result.`type` = `type`

proc definition(this: Variable): string = &"{this.`type`} {this.name}"
converter toStatement(this: Variable): Statement = newStatement this.definition
