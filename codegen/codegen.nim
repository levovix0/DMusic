
type
  CModule* = ref object
    namespaces*: seq[CNamespace]
    classes*: seq[CClass]
    functions*: seq[CFunction]
    # prvateNamespaces*: seq[CNamespace]
    # privateClasses*: seq[CClass]
    # privateFunctions*: seq[CFunction]
  CNamespace* = ref object
    classes*: seq[CClass]
    functions*: seq[CFunction]
  CClass* = ref object of RootObj
    publicFields*: seq[CField]
    publicMethods*: seq[CFunction]
    protectedFields*: seq[CField]
    protectedMethods*: seq[CFunction]
    privateFields*: seq[CField]
    privateMethods*: seq[CFunction]
  CFunction* = ref object of RootObj
  CField* = ref object

  QClass* = ref object of CClass
    properties*: seq[QProperty]
    signals*: seq[QSignal]
    publicSlots*: seq[CFunction]
    protectedSlots*: seq[CFunction]
    privateSlots*: seq[CFunction]
  QProperty* = ref object
  QSignal* = ref object
