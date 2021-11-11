import unittest
import ../uniony
import pkg/union
import pkg/jsony

suite "Object with union field":
  setup:
    type Val = object
      num: union(int | string | float)

    var u = Val(num: 42 as union(int | string | float))

  test "Parse JSON":
    let parsed = """{"num":42}""".fromJson(Val)

    check parsed == u

  test "Dump union object":
    let dump = u.toJson()

    check dump == """{"num":42}"""
