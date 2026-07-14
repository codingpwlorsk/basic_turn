when not declared(imported_prarser):
    const imported_prarser = 1
    include lexer
    import math

    type TreeKind = enum
        TEXT,
        BRANCH


    type Tree = object
        case kind: TreeKind:
            of TEXT:
                text: Token
            of BRANCH:
                branch: seq[Tree]


    func `[]`(self: Tree, index: int): Tree=
        return self.branch[index]


    func add(self: var Tree, item: Tree): void=
        self.branch.add(item)


    func token_val(self: Tree): Token=
        return self.text


    func new_tree(text: Token): Tree=
        return Tree(kind: TreeKind.TEXT, text: text)


    func new_tree(branch: seq[Tree]): Tree=
        return Tree(kind: TreeKind.BRANCH, branch: branch)


    func seperate(branch: Tree, amout: int): Tree=
        var new_branch: seq[Tree] = @[]
        for block_i in 0..int(branch.branch.len()/amout)-1:
            var segment: seq[Tree] = @[]
            for i in 0..amout-1:
                segment.add(branch[block_i * amout + i])
            new_branch.add(new_tree(segment))
        return new_tree(new_branch)


    type Parsable = seq[Token] or Lexable


    func parse(tokens: var seq[Token]): Tree=
        var body: seq[Tree] = @[]
        while true:
            if len(tokens) == 0:
                return new_tree(body)
            var first_word: Token = tokens[0]
            tokens.delete(0)
            if first_word.value == "}":
                return new_tree(body)
            if first_word.value == "{":
                body.add(parse(tokens))
            elif not (first_word.value == ""):
                body.add(new_tree(first_word))


    func parse(text: Lexable): Tree=
        var lex_result = lex(text)
        return parse(lex_result)

    proc echo_parser(self: Tree, depth = 0): void=
        if self.kind == TreeKind.TEXT:
            var echo_result = ""
            for _ in 0..depth:
                echo_result.add("\t")
            echo_result.add(self.text.value)
            echo echo_result
        else:
            for i in self.branch:
                echo_parser(i, depth + 1)
