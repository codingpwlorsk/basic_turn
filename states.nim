import std/strutils
import std/options
import std/sets
import std/strformat
import result
import lexer
import parser


type TapeValue* = enum 
    ZERO = "0",
    ONE = "1"


func repr*(self: TapeValue): string=
    return $self


type Dirrection* = enum 
    LEFT = "LEFT",
    RIGHT = "RIGHT"


func repr*(self: Dirrection): string=
    return $self


type CommandKind* = enum
    MOVE = "move",
    SET = "set",
    GOTO = "goto",
    HALT = "halt"


func repr*(self: CommandKind): string=
    return $self


type MoveCommand* = object
    dir*: Dirrection
    value*: Token


func repr*(self: MoveCommand): string=
    return fmt"move {$self.dir}"


type SetCommand* = object
    tape_val*: TapeValue
    value*: Token


func repr*(self: SetCommand): string=
    return fmt"set {$self.tape_val}"


type GotoCommand* = object
    name*: string
    value*: Token


func repr*(self: GotoCommand): string=
    return fmt"goto {$self.name}"


type HaltCommand* = object
    _: int
    value*: Token


func repr*(self: HaltCommand): string=
    return "halt"


type CaseBodyKind* = enum
    CONTINUE,
    HALT


type Command* = object
    case kind*: CommandKind:
        of MOVE:
            move*: MoveCommand
        of SET:
            set*: SetCommand
        of GOTO:
            goto*: GotoCommand
        of HALT:
            halt*: HaltCommand


func name*(self: Command): string=
    return self.goto.name


func dir*(self: Command): Dirrection=
    return self.move.dir


func tape_val*(self: Command): TapeValue=
    return self.set.tape_val


func value*(self: Command): Token=
    case self.kind:
        of MOVE:
            return self.move.value
        of SET:
            return self.set.value
        of GOTO:
            return self.goto.value
        of HALT:
            return self.halt.value


func repr*(self: Command): string=
    case self.kind:
        of MOVE:
            return fmt"{self.move.repr}\n"
        of SET:
            return fmt"{self.set.repr}\n"
        of GOTO:
            return fmt"{self.goto.repr}\n"
        of HALT:
            return fmt"{self.halt.repr}\n"


type CaseBody* = object
    case kind*: CaseBodyKind:
        of CONTINUE:
            goto*: GotoCommand
            set*: SetCommand
            move*: MoveCommand
        of HALT:
            halt*: HaltCommand


func repr*(self: CaseBody): string=
    var repr_of_self: string = ""
    if self.kind == CaseBodyKind.HALT:
        repr_of_self.add("\t\t")
        repr_of_self.add(self.halt.repr)
        repr_of_self.add("\n")
        return repr_of_self
    repr_of_self.add("\t\t")
    repr_of_self.add($self.set.repr)
    repr_of_self.add("\n")
    repr_of_self.add("\t\t")
    repr_of_self.add($self.move.repr)
    repr_of_self.add("\n")
    repr_of_self.add("\t\t")
    repr_of_self.add($self.goto.repr)
    repr_of_self.add("\n")
    return repr_of_self


func `==`*(original: CaseBody, other: CaseBody): bool=
    if original.kind != other.kind:
        return false
    if original.kind == CaseBodyKind.HALT:
        return true
    if original.goto != other.goto:
        return false
    if original.set != other.set:
        return false
    if original.move != other.move:
        return false
    return true


type Case* = object
    case_val*: TapeValue
    body*: CaseBody


func repr*(self: Case): string=
    var repr_of_self = ""
    repr_of_self.add("\tgot " & self.case_val.repr & " {\n")
    repr_of_self.add(self.body.repr)
    repr_of_self.add("\t}\n")
    return repr_of_self

func goto*(self: Case): GotoCommand=
    return self.body.goto

func set*(self: Case): SetCommand=
    return self.body.set

func move*(self: Case): MoveCommand=
    return self.body.move

func halt*(self: Case): HaltCommand=
    return self.body.halt

func kind*(self: Case): CaseBodyKind=
    return self.body.kind

func `==`*(original: Case, other: Case): bool=
    return ((original.case_val == other.case_val) and
            (original.body == other.body))


type StateBody* = object
    case0: Case
    case1: Case


func repr*(self: StateBody): string=
    return self.case0.repr & self.case1.repr


type State* = object
    name*: string
    body*: StateBody


func repr*(self: State): string=
    var repr_of_self = ""
    repr_of_self.add("state " & self.name & " {\n")
    repr_of_self.add(self.body.repr)
    repr_of_self.add("}\n")
    return repr_of_self


func case0*(self: State): Case=
    return self.body.case0

func case1*(self: State): Case=
    return self.body.case1


func get_command*(node: Tree): Command=
    var command_name: string
    command_name = node[0].token_val.value
    case parse_enum[CommandKind](command_name):
        of MOVE:
            var dir: Dirrection = parse_enum[Dirrection](node[1].token_val.value)
            return Command(kind: CommandKind.MOVE,
                        move: MoveCommand(dir: dir))
        of SET:
            var com_tape_val = node[1].token_val
            var val: TapeValue = parse_enum[TapeValue](com_tape_val.value)
            return Command(kind: CommandKind.SET,
                            set: SetCommand(tape_val: val))
        of GOTO:
            var name = node[1].token_val.value
            return Command(kind: CommandKind.GOTO,
                        goto: GotoCommand(name: name,
                                            value: node[1].token_val))
        of HALT:
            return Command(kind: CommandKind.HALT,
                        halt: HaltCommand())


func get_case_body*(node: var Tree): CaseBody=
    var commands: seq[Command] = @[]
    while not(node.branch.len == 0):
        var com = get_command(node)
        commands.add(com)
        if com.kind == CommandKind.HALT:
            node.branch.delete(0)
        else:
            node.branch.delete(0)
            node.branch.delete(0)
    var pos_halt: Option[HaltCommand] = none(HaltCommand)
    var pos_goto: Option[GotoCommand] = none(GotoCommand)
    var pos_set: Option[SetCommand] = none(SetCommand)
    var pos_move: Option[MoveCommand] = none(MoveCommand)
    for com in commands:
        case com.kind:
            of MOVE:
                pos_move = some(com.move)
            of SET:
                pos_set = some(com.set)
            of GOTO:
                pos_goto = some(com.goto)
            of HALT:
                pos_halt = some(com.halt)
    if pos_halt.is_some:
        return CaseBody(kind: CaseBodyKind.HALT,
                        halt: pos_halt.get())
    return CaseBody(kind: CaseBodyKind.CONTINUE,
                    set: pos_set.get(),
                    goto: pos_goto.get(),
                    move: pos_move.get())


func get_case*(node: Tree): Case=
    var tape_val_node: Tree = node[1]
    var tape_val: TapeValue = parse_enum[TapeValue](tape_val_node.token_val.value)
    var node_body = node[2]
    var body = get_case_body(node_body)
    return Case(case_val: tape_val,
                body: body)


func get_state_body*(node: Tree): StateBody=
    var new_node = node.seperate(3)
    var first_case = get_case(new_node[0])
    var second_case = get_case(new_node[1])
    var zero_case: Option[Case] = none(Case)
    var one_case: Option[Case] = none(Case)
    if first_case.case_val == TapeValue.ZERO:
        zero_case = some(first_case)
        one_case = some(second_case)
    elif second_case.case_val == TapeValue.ZERO:
        zero_case = some(second_case)
        one_case = some(first_case)
    return StateBody(case0: zero_case.get(),
                    case1: one_case.get())


type ProperStates* = object
    states*: seq[State]


func `states=`(self: ProperStates, other: seq[State]): void=
    type immutable = ref Defect
    raise immutable()


func repr*(self: ProperStates): string=
    var repr_of_self = ""
    for i in self.states:
        repr_of_self.add(i.repr)
    return repr_of_self


type ReasonsStateNotProperKind* = enum
    NOT_HAVE_MAIN,
    GO_TO_NONEXSISTANT_STATE


type ReasonsStateNotProper* = object
    case kind*: ReasonsStateNotProperKind:
        of NOT_HAVE_MAIN:
            _: int
        of GO_TO_NONEXSISTANT_STATE:
            non_exstistant_state_name*: Token


func new_reasons_state_not_proper*(): ReasonsStateNotProper=
    return ReasonsStateNotProper(kind:ReasonsStateNotProperKind.NOT_HAVE_MAIN)


func new_reasons_state_not_proper*(non_exstistant_state_name: Token): ReasonsStateNotProper=
    return ReasonsStateNotProper(kind:ReasonsStateNotProperKind.GO_TO_NONEXSISTANT_STATE,
                                    non_exstistant_state_name: non_exstistant_state_name)


func new_proper_states*(states: seq[State]): Result[ProperStates, ReasonsStateNotProper]=
    var exstisting_states: HashSet[string] = init_hash_set[string]()
    for i in states:
        exstisting_states.incl(i.name)
    for i in states:
        if i.case0.kind == CaseBodyKind.CONTINUE:
            if not (i.case0.goto.name in exstisting_states):
                var reason_not_proper = new_reasons_state_not_proper(i.case0.goto.value)
                return err[ProperStates, ReasonsStateNotProper](reason_not_proper)
        if i.case1.kind == CaseBodyKind.CONTINUE:
            if not (i.case1.goto.name in exstisting_states):
                var reason_not_proper = new_reasons_state_not_proper(i.case0.goto.value)
                return err[ProperStates, ReasonsStateNotProper](reason_not_proper)
    if not ("main" in exstisting_states):
        return err[ProperStates, ReasonsStateNotProper](new_reasons_state_not_proper())
    return okay[ProperStates, ReasonsStateNotProper](ProperStates(states: states))


func get_states*(node: Tree): Result[ProperStates, ReasonsStateNotProper]=
    var states: seq[State] = @[]
    for i in node.seperate(3).branch:
        var node_name: Tree = i[1]
        var name: string = node_name.token_val.value
        var node_body: Tree = i[2]
        var state_body: StateBody = get_state_body(node_body)
        states.add(State(name: name,
                        body: state_body))
    return new_proper_states(states)


type GetStatable* = Parsable or Tree


func get_states*(par: Parsable): Result[ProperStates, ReasonsStateNotProper]=
    return get_states(parse(par))
