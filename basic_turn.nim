import std/cmdline
import std/options
import std/strutils
import std/strformat
include optimizer
include vm

type TerminalCommandKind = enum
    RUN = "run",
    OPTIMIZE = "optomize",
    UNVALID


type TerminalCommand = object
    case kind: TerminalCommandKind:
        of RUN:
            debug: bool
            optimize: bool
            file_to_run: string
        of OPTIMIZE:
            file_to_optimize: string
        of UNVALID:
            name: string


func parse_args(args: seq[string]): TerminalCommand=
    let arg_kind: TerminalCommandKind = parse_enum(args[0], TerminalCommandKind.UNVALID)
    case arg_kind:
        of RUN:
            var debug: bool = false
            var optimize: bool = true
            for i in args[1..len(args)-1]:
                if i == "--debug":
                    debug = true
                if i == "--no_optimizations":
                    optimize = false
            return TerminalCommand(kind: arg_kind,
                                   debug: debug,
                                   optimize: optimize,
                                   file_to_run: args[len(args)-1])
        of OPTIMIZE:
            return TerminalCommand(kind: arg_kind,
                                   file_to_optimize: args[1])
        of UNVALID:
            return TerminalCommand(kind: arg_kind,
                                   name: args[1])


var commands = parse_args(command_line_params())


case commands.kind:
    of RUN:
        var text: string = read_file(commands.file_to_run)
        var i: Result[void, ReasonsStateNotProper]
        var exacutable: ProperStates
        if commands.optimize:
            exacutable = optimize(text)
        else:
            exacutable = get_states(text).get()
        if commands.debug:
            i = debug(exacutable)
        else:
            i = exec(exacutable)
        if not i.is_okay:
            echo (i.err)
    of OPTIMIZE:
        var text: string = read_file(commands.file_to_optimize)
        echo optimize(text).repr()
    of UNVALID:
        echo fmt"UNVALID COMMAND {commands.name}"
