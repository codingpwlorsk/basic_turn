import states
import std/options
import result
import vm


type TapeValueKind = enum 
    ZERO,
    ONE,
    VALUE


type TapeValuePatternKind = enum
    IS_NOT,
    REG


type DirrectionPatternKind = enum
    IS_NOT,
    REG


type DirrectionKind = enum
    LEFT,
    RIGHT,
    SIDE


type TapeValuePattern = ref object
    filled: Option[TapeValue] = none(TapeValue)
    case kind: TapeValuePatternKind:
        of REG:
            pattern: TapeValueKind
        of IS_NOT:
            other: TapeValuePattern


func new_zero_pattern(): TapeValuePattern=
    return TapeValuePattern(kind: TapeValuePatternKind.REG,
                            pattern: TapeValueKind.ZERO)


func new_one_pattern(): TapeValuePattern=
    return TapeValuePattern(kind: TapeValuePatternKind.REG,
                            pattern: TapeValueKind.ONE)


func new_value_pattern(): TapeValuePattern=
    return TapeValuePattern(kind: TapeValuePatternKind.REG,
                            pattern: TapeValueKind.VALUE)


func match(self: var TapeValuePattern, other: TapeValue): bool=
    if self.filled.is_some:
        return self.filled.get() == other
    case self.kind:
        of REG:
            case self.pattern:
                of ONE:
                    debugEcho "ONE"
                    if other == TapeValue.ONE:
                        self.filled = some(other)
                        return true
                    return false
                of ZERO:
                    debugEcho "ZERO"
                    if other == TapeValue.ZERO:
                        self.filled = some(other)
                        return true
                    return false
                of VALUE:
                    debugEcho "VALUE"
                    self.filled = some(other)
                    return true
        of IS_NOT:
            if not self.other.match(other):
                self.filled = some(other)
                return true
            debugEcho other
            debugEcho self.other.pattern
            debugEcho self.other.filled
            debugEcho "IS NOOOOT"
            return false

func `not`(self: TapeValuePattern): TapeValuePattern=
    case self.kind:
        of REG:
            return TapeValuePattern(kind: TapeValuePatternKind.IS_NOT,
                                    other: self)
        of IS_NOT:
            return self.other


type DirrectionPattern = ref object
    filled: Option[Dirrection] = none(Dirrection)
    case kind: DirrectionPatternKind:
        of REG:
            pattern: DirrectionKind
        of IS_NOT:
            other: DirrectionPattern


func new_left_pattern(): DirrectionPattern=
    return DirrectionPattern(kind: DirrectionPatternKind.REG,
                             pattern: DirrectionKind.LEFT)


func new_right_pattern(): DirrectionPattern=
    return DirrectionPattern(kind: DirrectionPatternKind.REG,
                             pattern: DirrectionKind.RIGHT)


func new_side_pattern(): DirrectionPattern=
    return DirrectionPattern(kind: DirrectionPatternKind.REG,
                             pattern: DirrectionKind.SIDE)


func match(self: var DirrectionPattern, other: Dirrection): bool=
    if self.filled.is_some:
        return self.filled.get() == other
    case self.kind:
        of REG:
            case self.pattern:
                of LEFT:
                    debugEcho "LEFT"
                    if other == Dirrection.LEFT:
                        self.filled = some(other)
                        return true
                    return false
                of RIGHT:
                    debugEcho "RIGHT"
                    if other == Dirrection.RIGHT:
                        self.filled = some(other)
                        return true
                    return false
                of SIDE:
                    debugEcho "SIDE"
                    self.filled = some(other)
                    return true
        of IS_NOT:
            debugEcho "IS_NOT"
            if not self.other.match(other):
                self.filled = some(other)
                return true
            return false


func `not`(self: DirrectionPattern): DirrectionPattern=
    case self.kind:
        of REG:
            return DirrectionPattern(kind: DirrectionPatternKind.IS_NOT,
                                     other: self)
        of IS_NOT:
            return self.other


type CasePatternKind = enum 
    ANY,
    HALT,
    CONTINUE


type CasePattern[T] = ref object
    filled: Option[Case] = none(Case)
    tape_val: TapeValuePattern
    kind: CasePatternKind
    set*: TapeValuePattern
    move*: DirrectionPattern
    goto*: T


func `not`(self: CasePattern): CasePattern=
    return CasePattern(tape_val: not self.tape_val,
                       kind: CasePatternKind.CONTINUE,
                       set: not self.set,
                       move: not self.move,
                       goto: self.goto)



func match*(self: var CasePattern, pattern: Case, current: string, other: ExecFormat): bool=
    if self.filled.is_some:
        return self.filled.get() == pattern
    var did_match = self.tape_val.match(pattern.case_val)
    if not did_match:
        return did_match
    case self.kind:
        of CONTINUE:
            did_match = self.set.match(pattern.set.tape_val)
            if not did_match:
                debugEcho "set"
                return did_match
            did_match = self.move.match(pattern.move.dir)
            if not did_match:
                debugEcho "move"
                return did_match
            did_match = self.goto.match(current, other)
            if not did_match:
                debugEcho "goto"
            self.filled = some(pattern)
            return did_match
        of HALT:
            if pattern.kind == CaseBodyKind.HALT:
                self.filled = some(pattern)
                return true
        of ANY:
            self.filled = some(pattern)
            return true


type StatePatternKind = enum 
    ANY,
    RESTRICTIONS


type StatePattern* = ref object
    filled: Option[State] = none(State)
    kind*: StatePatternKind = StatePatternKind.RESTRICTIONS
    cases*: array[2, CasePattern[StatePattern]]


func new_any_state_pattern(): StatePattern=
    return StatePattern(kind: StatePatternKind.ANY)


func match*(self: var StatePattern, start_state: string, other: ExecFormat): bool=
    if self.filled.is_some:
        return self.filled.get()  == other[start_state]
    case self.kind:
        of ANY:
            self.filled = some(other[start_state])
            return true
        of RESTRICTIONS:
            var did_match: bool = self.cases[0].match(other[start_state].case0, start_state, other)
            if not did_match:
                return did_match
            did_match = self.cases[1].match(other[start_state].case1, start_state, other)
            if not did_match:
                return did_match
            self.filled = some(other[start_state])


func do_nothing(goto: StatePattern, move: DirrectionPattern): StatePattern=
    return StatePattern(
    cases: [
        CasePattern[StatePattern](
            tape_val: new_one_pattern(),
            move: move,
            set: new_one_pattern(),
            goto: goto
        ),
        CasePattern[StatePattern](
            tape_val: new_zero_pattern(),
            move: move,
            set: new_zero_pattern(),
            goto: goto
        )
        ]
    )


var primary_side = new_side_pattern()
var primary_value = new_value_pattern()


var first_state = StatePattern(
    kind: StatePatternKind.RESTRICTIONS,
    cases: [
        CasePattern[StatePattern](
            kind: CasePatternKind.CONTINUE,
            move: primary_side,
            set: primary_value,
            goto: new_any_state_pattern(),
            tape_val: primary_value
        ),
        CasePattern[StatePattern](
            kind: CasePatternKind.CONTINUE,
            move: primary_side,
            set: not primary_value,
            goto: new_any_state_pattern(),
            tape_val: not primary_value
        )
    ]
)


echo first_state.match(
"a",
states_to_exec_fmt("""
state main {
    got 0 {
        set 1
        move LEFT
        goto a
    }
    got 1 {
        set 0
        move LEFT
        goto a
    }
}
state a {
    got 0 {
        set 0
        move RIGHT
        goto b
    }
    got 1 {
        set 1
        move RIGHT
        goto b
    }
}

state b {
    got 0 {
        halt
    }
    got 1 {
        halt
    }
}""").get())


echo states_to_exec_fmt("""
state main {
    got 0 {
        set 1
        move LEFT
        goto a
    }
    got 1 {
        set 0
        move LEFT
        goto a
    }
}
state a {
    got 0 {
        set 0
        move RIGHT
        goto b
    }
    got 1 {
        set 1
        move RIGHT
        goto b
    }
}

state b {
    got 0 {
        halt
    }
    got 1 {
        halt
    }
}""").get()["b"]
