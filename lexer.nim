when not declared(imported_lexer):
    var imported_lexer: int = 1


    type Token = object
        value: string
        start_place: int
        end_place: int
        line_number: int


    type Lexable = string


    func lex(text: string): seq[Token]=
        var tokens: seq[Token] = @[]
        var end_place: int = 0
        var line_number: int = 0
        var tokens_text: string = ""
        for charictor in text:
            end_place += 1
            if charictor == '\n':
                line_number += 1
            if charictor in WHITESPACE:
                if not (tokens_text == ""):
                    tokens.add(Token(value: tokens_text,
                                    start_place: end_place - tokens_text.len(),
                                    end_place: end_place,
                                    line_number: line_number))
                    tokens_text = ""
            else:
                tokens_text.add(charictor)
        return tokens

