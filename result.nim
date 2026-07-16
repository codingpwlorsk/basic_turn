type ResultKind* = enum
    OKAY,
    ERR


type Result*[O, E] = object
    case kind*: ResultKind:
        of OKAY:
            okay*: O
        of ERR:
            err*: E


func okay*[Okay, Err](value: Okay): Result[Okay, Err]=
    return Result[Okay, Err](kind: ResultKind.OKAY,
                                okay: value)


func err*[Okay, Err](value: Err): Result[Okay, Err]=
    return Result[Okay, Err](kind: ResultKind.ERR,
                                err: value)


func get*[Okay, Err](self: Result[Okay, Err]): Okay=
    return self.okay


func is_okay*[Okay, Err](self: Result[OKay, Err]): bool=
    return self.kind == ResultKind.OKAY


func is_err*[Okay, Err](self: Result[OKay, Err]): bool=
    return self.kind == ResultKind.ERR
