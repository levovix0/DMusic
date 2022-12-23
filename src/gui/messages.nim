{.used.}
import qt

var history: seq[tuple[text, details: string, isError: bool]]

var notifyMessage: proc(text, details: string) = proc(text, details: string) =
  history.add (text, details, false)

var notifyError: proc(text, details: string) = proc(text, details: string) =
  history.add (text, details, true)

proc sendMessage*(text: string, details = "") = notifyMessage(text, details)
proc sendError*(text: string, details = "") = notifyError(text, details)

type Messages = object

qobject Messages:
  proc message(text, details: string) {.signal.}
  proc error(text, details: string) {.signal.}

  proc init =
    notifyMessage = proc(text, details: string) = this.message(text, details)
    notifyError = proc(text, details: string) = this.error(text, details)

    for (text, details, isError) in history:
      if isError: this.error(text, details)
      else:       this.message(text, details)
    history = @[]

registerInQml Messages, "DMusic", 1, 0
