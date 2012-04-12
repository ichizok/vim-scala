
if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

setlocal et sw=2 ts=2
setlocal include=^import
