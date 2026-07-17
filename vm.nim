import std/tables
import std/strformat
import states
import result


type ExecFormat* = object
    table*: TableRef[string, State]


func `[]`*(self: ExecFormat, key: string): State=
    return self.table[key]


func states_to_exec_fmt*(states: ProperStates): Result[ExecFormat, ReasonsStateNotProper]=
    var table: TableRef[string, State] = new_table[string, State]()
    for i in states.states:
        table[i.name] = i
    return okay[ExecFormat, ReasonsStateNotProper](ExecFormat(table: table))


proc states_to_exec_fmt*(stateable: GetStatable): Result[ExecFormat, ReasonsStateNotProper]=
    var potentail_states = get_states(stateable)
    if not potentail_states.is_okay:
        return err[ExecFormat, ReasonsStateNotProper](potentail_states.err)
    return states_to_exec_fmt(potentail_states.get())


type GetExecable* = GetStatable or ProperStates


type MachionState* = object
    tape*: seq[TapeValue]
    current_state_name*: string
    current_head_place*: int
    current_head_value*: TapeValue


iterator pass_through_state*(states: ExecFormat): MachionState=
    var tape: seq[TapeValue] = @[TapeValue.ZERO]
    var min_head: int = 0
    var max_head: int = 0
    var head: int = 0
    var current_state_name: string = "main"
    var halt: bool = false
    proc move(move: Dirrection): void=
        case move:
            of Dirrection.LEFT:
                head -= 1
            of Dirrection.RIGHT:
                head += 1
        if head > max_head:
            max_head += 1
            tape.add(TapeValue.ZERO)
        elif head < min_head:
            min_head -= 1
            tape.insert(TapeValue.ZERO, 0)
    proc set(value: TapeValue): void=
        tape[head-min_head] = value
    while not halt:
        var current_state: State = states[current_state_name]
        var current_value: TapeValue = tape[head-min_head]
        var case0: Case = current_state.case0
        var case1: Case = current_state.case1
        case current_value:
            of TapeValue.ZERO:
                if case0.kind == CaseBodyKind.HALT:
                    halt = true
                    break
                set(case0.set.tape_val)
                move(case0.move.dir)
                current_state_name = case0.goto.name
            of TapeValue.ONE:
                if case1.kind == CaseBodyKind.HALT:
                    halt = true
                    break
                set(case1.set.tape_val)
                move(case1.move.dir)
                current_state_name = case1.goto.name
        yield MachionState(tape:tape,
                            current_state_name: current_state_name,
                            current_head_place: head,
                            current_head_value: tape[head-min_head])


proc exec*(states: ExecFormat): void=
    for i in pass_through_state(states):
        echo i.tape


proc exec*(states: GetExecable): Result[void, ReasonsStateNotProper]=
    var potential_states: Result[ExecFormat, ReasonsStateNotProper] = states_to_exec_fmt(states)
    if potential_states.is_err:
        return err[void, ReasonsStateNotProper](potential_states.err)
    exec(potential_states.get())


proc debug*(states: ExecFormat): void=
    for i in pass_through_state(states):
        echo fmt"tape {i.tape}"
        echo fmt"head place {i.current_head_place}"
        echo fmt"head value {i.current_head_value}"
        echo fmt"state_name {i.current_state_name}"
        var _ = stdin.readLine()


proc debug*(states: GetExecable): Result[void, ReasonsStateNotProper]=
    var potential_states: Result[ExecFormat, ReasonsStateNotProper] = states_to_exec_fmt(states)
    if potential_states.is_err:
        return err[void, ReasonsStateNotProper](potential_states.err)
    debug(potential_states.get())

type Runnable* = ExecFormat or GetExecable
