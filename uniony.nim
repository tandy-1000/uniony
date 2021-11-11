import std/[macros, genasts]
import pkg/jsony
import pkg/union
import pkg/union/uniontraits

proc parseHook*[T: Union](s: string, i: var int, v: var T) =
  macro parseHookAux[T: Union](s: string, i: var int, v: var T): untyped =
    let
      union = v.getUnionType

      # The symbol for the copy of `i` in case we have to rollback.
      origIdx = nskLet.genSym("origIdx")

    result = newStmtList()
    # Add the declaration for origIdx
    result.add newLetStmt(origIdx, i)

    # Construct a block to handle parsing.
    #
    # The idea is to construct a block like this:
    #
    # block parser:
    #   doParse(<a type in union (ie. int)>)
    #   if successful:
    #     break parser
    #
    #   doParse(<an another type (ie. string)>)
    #   if successful:
    #     break parser
    #
    #   raise JsonError otherwise
    let
      parser = nskLabel.genSym("parser")
      # The statements inside block
      blkStmt = newStmtList()
      blk = nnkBlockStmt.newTree(copy(parser), blkStmt)

    # Construct parsing blocks for each type in union.
    for _, _, typ in union.variants:
      blkStmt.add:
        genAst(
          typ, # A type within union
          parser = copy(parser), # The parser label to break out of on success
          i, # The index variable used by parseHook
          origIdx, # The original position to rollback if parsing failed
          v # The union we are creating
        ):
          try:
            var x: typ
            parseHook(s, i, x)

            # If parseHook succeed, assign the result to `v` and we are done.
            v <- x
            break parser
          except JsonError:
            # Otherwise rollback the index and let the next block try again
            i = origIdx

    # Add a raise at the end of the block. This raise is only reachable if all
    # other parsers failed.
    blkStmt.add:
      genAst(i, v):
        raise newException(JsonError, $typeof(v) & " expected at: " & $i)

    # Add the block to the result.
    result.add blk

  parseHookAux(s, i, v)

proc dumpHook*[T: Union](s: var string, v: T) =
  unpack(v):
    dumpHook(s, it)
