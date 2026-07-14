import std/cmdline
import std/options
import std/strutils
include optimizer
include vm

type TerminalCommandKind = enum
    RUN = "run",
    OPTIMIZE = "optomize"


type TerminalCommand = object
    case kind: TerminalCommandKind:
        of RUN:
            file_to_run: string
        of OPTIMIZE:
            file_to_optimize: string



func parse_args(args: seq[string]): TerminalCommand=
    let arg_kind = parse_enum[TerminalCommandKind](args[0])
    case arg_kind:
        of RUN:
            return TerminalCommand(kind: arg_kind,
                                   file_to_run: args[1])
        of OPTIMIZE:
            return TerminalCommand(kind: arg_kind,
                                   file_to_optimize: args[1])


var commands = parse_args(command_line_params())


case commands.kind:
    of RUN:
        var text: string = read_file(commands.file_to_run)
        var i = exec(optimize(text))
        if not i.is_okay:
            echo (i.err)
    of OPTIMIZE:
        var text: string = read_file(commands.file_to_optimize)
        echo optimize(text).repr()
