import pkg/jsony
import pkg/union
import pkg/union/uniontraits


proc parseHook*[T: Union](s: string, i: var int, v: var T)

proc dumpHook*[T: Union](s: var string, v: var T)


proc parseHook*[T: Union](s: string, i: var int, v: var T) =
  unpack(v):
    var unpacked = it
    parseHook(s, i, unpacked)
    v <- unpacked


proc dumpHook*[T: Union](s: var string, v: var T) =
  unpack(v):
    var unpacked = it
    dumpHook(s, unpacked)
    v <- unpacked