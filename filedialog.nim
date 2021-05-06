# rebuilding:
#   nim c filedialog

import gintro/[gtk, gobject], strutils, os

proc lockOutput(file: File) =
  discard file.reopen("/dev/null", fmWrite)

proc openFileDialog(title: string, opens: string, cancels: string, pattern: string, filterTitle: string): string =
  let dialog = newFileChooserDialog(title, nil, FileChooserAction.open)
  discard dialog.addButton(cancels, 0)
  discard dialog.addButton(opens, 1)
  if pattern != "":
    let filter = newFileFilter()
    filter.name = filterTitle
    for pattern in pattern.split:
      filter.addPattern pattern
    dialog.addFilter filter
  if dialog.run.cint == 1:
    return dialog.filename

if paramCount() != 5:
  echo ""
else:
  lockOutput stderr
  gtk.init()
  echo openFileDialog(paramStr 1, paramStr 2, paramStr 3, paramStr 4, paramStr 5)
