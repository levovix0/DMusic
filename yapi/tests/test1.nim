import unittest, os

import yapi

test "downloads track":
  # let token = generate_token("xlevovix@yandex.com", "Lx109583")
  # echo token
  discard login("AgAAAAAwR49zAAG8XvNMwDoyKUj6lw3xFFjPS_Y")
  let track = track_from_link("https://music.yandex.ru/album/13352869/track/75821086")
  discard track.download_track("a.mp3")
  check "a.mp3".fileExists
