when not declared(imported_optimizer):
    var imported_optimizer = true
    include states


    type OptimizerFunc = (proc(states: ProperStates): ProperStates {.noSideEffect})
    var known_optimizers: seq[OptimizerFunc] = @[]


    func remove_unused_nodes(states: ProperStates): ProperStates=
        var names_of_used_nodes: seq[string] = @[]
        for i in states.states:
            if i.case0.kind ==  CaseBodyKind.CONTINUE:
                names_of_used_nodes.add(i.case0.goto.name)
            if i.case1.kind ==  CaseBodyKind.CONTINUE:
                names_of_used_nodes.add(i.case1.goto.name)
        var optomized_states: seq[State] = @[]
        for i in states.states:
            if i.name in names_of_used_nodes:
                optomized_states.add(i)
        var prop_state = new_proper_states(optomized_states)
        return prop_state.get()

    known_optimizers.add(remove_unused_nodes)

    iterator optimize_loop(states: ProperStates,
                      optimizers=known_optimizers): ProperStates=
        var new_state: ProperStates = states
        var completed_optimizations: bool = false
        while true:
            var optimize_at_all = false
            var changed: bool = false
            for optimizer in optimizers:
                var transformed_state: ProperStates = optimizer(new_state)
                if transformed_state != new_state:
                    new_state = transformed_state
                    changed = true
                    yield new_state
            if not changed:
                break


    proc optimize(states: ProperStates): ProperStates=
        var new_optomized_states: ProperStates
        for i in optimize_loop(states):
            new_optomized_states = i
        return new_optomized_states


    proc optimize(states: GetStatable): ProperStates=
        return optimize(get_states(states).get())
