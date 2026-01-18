## ADDED Requirements
### Requirement: Lexer Tokenization with NimbleParsec
The system SHALL provide a `Lexer` module that tokenizes Clojure source code into tokens using NimbleParsec parser combinators.

#### Scenario: Tokenize simple symbol
- **WHEN** lexing the input `"hello"`
- **THEN** the lexer SHALL produce `[{:symbol, "hello", 1, 1}]`

#### Scenario: Tokenize string with escapes
- **WHEN** lexing the input `"hello\\"world\\""`
- **THEN** the lexer SHALL produce `[{:string, "hello\\"world\\"", 1, 1}]`

#### Scenario: Tokenize number
- **WHEN** lexing the input `"42"`
- **THEN** the lexer SHALL produce `[{:number, "42", 1, 1}]`

#### Scenario: Tokenize keyword
- **WHEN** lexing the input `":keyword"`
- **THEN** the lexer SHALL produce `[{:keyword, ":keyword", 1, 1}]`

#### Scenario: Tokenize delimiters
- **WHEN** lexing the input `"()[]{}"`
- **THEN** the lexer SHALL produce `[{:paren_open, 1, 1}, {:paren_close, 1, 2}, {:bracket_open, 1, 3}, {:bracket_close, 1, 4}, {:brace_open, 1, 5}, {:brace_close, 1, 6}]`

#### Scenario: Tokenize comment
- **WHEN** lexing the input `"; comment\\nnext"`
- **THEN** the lexer SHALL ignore the comment and produce `[{:symbol, "next", 2, 1}]`

#### Scenario: Tokenize discard directive
- **WHEN** lexing the input `"#_ignored symbol"`
- **THEN** the lexer SHALL produce `[{:skip, 1, 1}]`

#### Scenario: Tokenize whitespace
- **WHEN** lexing the input `"  \\t  \\nsymbol"`
- **THEN** the lexer SHALL ignore whitespace and produce `[{:symbol, "symbol", 2, 3}]`

#### Scenario: Tokenize nested structures
- **WHEN** lexing the input `"(defn foo [x] x)"`
- **THEN** the lexer SHALL produce tokens for each element with correct positions

### Requirement: Parser Composition with NimbleParsec
The system SHALL provide a `Parser` module that composes tokens into nested Clojure forms using NimbleParsec parser combinators.

#### Scenario: Parse list form
- **WHEN** parsing the token list `[{:paren_open, 1, 1}, {:symbol, "list", 1, 2}, {:paren_close, 1, 7}]`
- **THEN** the parser SHALL produce `[{:list, [{:symbol, "list", 1, 2}], 1, 1}]`

#### Scenario: Parse vector form
- **WHEN** parsing the token list `[{:bracket_open, 1, 1}, {:number, "1", 1, 2}, {:number, "2", 1, 4}, {:bracket_close, 1, 5}]`
- **THEN** the parser SHALL produce `[{:vector, [{:number, "1", 1, 2}, {:number, "2", 1, 4}], 1, 1}]`

#### Scenario: Parse map form
- **WHEN** parsing the token list `[{:brace_open, 1, 1}, {:keyword, ":a", 1, 2}, {:number, "1", 1, 4}, {:keyword, ":b", 1, 6}, {:number, "2", 1, 8}, {:brace_close, 1, 9}]`
- **THEN** the parser SHALL produce `[{:map, [{:keyword, ":a", 1, 2}, {:number, "1", 1, 4}, {:keyword, ":b", 1, 6}, {:number, "2", 1, 8}], 1, 1}]`

#### Scenario: Parse nested list in list
- **WHEN** parsing the token list `[{:paren_open, 1, 1}, {:paren_open, 1, 2}, {:symbol, "inner", 1, 3}, {:paren_close, 1, 9}, {:paren_close, 1, 10}]`
- **THEN** the parser SHALL produce `[{:list, [{:list, [{:symbol, "inner", 1, 3}], 1, 2}], 1, 1}]`

#### Scenario: Parse skip token from discard directive
- **WHEN** parsing the token list `[{:paren_open, 1, 1}, {:skip, 1, 2}, {:symbol, "keep", 1, 10}, {:paren_close, 1, 14}]`
- **THEN** the parser SHALL ignore the skip token and produce `[{:list, [{:symbol, "keep", 1, 10}], 1, 1}]`

#### Scenario: Parse multiple forms in sequence
- **WHEN** parsing the input `"symbol1 symbol2"`
- **THEN** the parser SHALL produce `[{:symbol, "symbol1", 1, 1}, {:symbol, "symbol2", 1, 9}]`

#### Scenario: Parse mixed forms
- **WHEN** parsing the input `"(list [1 2 3] {:key :value})"`
- **THEN** the parser SHALL produce correctly nested structures

### Requirement: Reader Integration with Parser Combinators
The `Reader` module SHALL integrate with the new Lexer and Parser modules while maintaining backward compatibility with the existing API.

#### Scenario: Parse returns same structure as before
- **WHEN** parsing the input `"(defn foo [x] x)"`
- **THEN** the output SHALL be identical to the original `Reader.parse/2` implementation

#### Scenario: Parse error includes location
- **WHEN** parsing the input `"(unclosed"`
- **THEN** the error SHALL include file, line, and column information

#### Scenario: API signature unchanged
- **WHEN** calling `Reader.parse(source, file)`
- **THEN** the function SHALL accept the same arguments and return the same format as before

#### Scenario: Reader handles all existing test cases
- **WHEN** running the existing test suite
- **THEN** all tests SHALL pass without modifications

#### Scenario: ParseError format preserved
- **WHEN** a parse error occurs
- **THEN** the error message SHALL follow the format `"Parse error at line X, column Y in file: reason"`

### Requirement: Lexer Testability
The `Lexer` module SHALL provide parsers that can be tested independently using ExUnit.

#### Scenario: Whitespace parser test
- **GIVEN** a whitespace parser defined in `Lexer`
- **WHEN** testing with `"  \\t\\n  "`
- **THEN** the parser SHALL consume all whitespace and return empty token list

#### Scenario: String parser test
- **GIVEN** a string parser defined in `Lexer`
- **WHEN** testing with `'"hello"'`
- **THEN** the parser SHALL return `[{:string, "hello", 1, 1}]`

#### Scenario: Symbol parser test
- **GIVEN** a symbol parser defined in `Lexer`
- **WHEN** testing with `"my-symbol"`
- **THEN** the parser SHALL return `[{:symbol, "my-symbol", 1, 1}]`

#### Scenario: Number parser test
- **GIVEN** a number parser defined in `Lexer`
- **WHEN** testing with `"123"`
- **THEN** the parser SHALL return `[{:number, "123", 1, 1}]`

#### Scenario: Delimiter parser test
- **GIVEN** delimiter parsers defined in `Lexer`
- **WHEN** testing with `"()[]{}"`
- **THEN** each delimiter SHALL produce the correct token with position

### Requirement: Parser Testability
The `Parser` module SHALL provide composable parsers that can be tested independently using ExUnit.

#### Scenario: List parser test
- **GIVEN** a list parser defined in `Parser`
- **WHEN** testing with `"()"`
- **THEN** the parser SHALL return `[{:list, [], 1, 1}]`

#### Scenario: Vector parser test
- **GIVEN** a vector parser defined in `Parser`
- **WHEN** testing with `"[]"`
- **THEN** the parser SHALL return `[{:vector, [], 1, 1}]`

#### Scenario: Map parser test
- **GIVEN** a map parser defined in `Parser`
- **WHEN** testing with `"{}"`
- **THEN** the parser SHALL return `[{:map, [], 1, 1}]`

#### Scenario: Form parser test
- **GIVEN** a form parser defined in `Parser`
- **WHEN** testing with various inputs
- **THEN** the parser SHALL correctly identify the form type

### Requirement: Code Quality - Duplication Elimination
The refactoring SHALL eliminate all code duplication between `parse_list`, `parse_vector`, and `parse_map` functions.

#### Scenario: No duplicate parsing logic
- **GIVEN** the refactored codebase
- **WHEN** examining `parse_list`, `parse_vector`, and `parse_map`
- **THEN** there SHALL be no identical clauses across these functions

#### Scenario: Shared parsing logic extracted
- **GIVEN** the refactored codebase
- **WHEN** examining the parsing logic
- **THEN** common patterns SHALL be extracted into reusable parsers in `Parser` module

### Requirement: Code Quality - Lines of Code Reduction
The refactoring SHALL reduce the total lines of code in the Reader-related modules.

#### Scenario: Reader module reduced
- **GIVEN** the refactored codebase
- **WHEN** counting lines in `lib/clj_compiler/reader.ex`
- **THEN** the module SHALL have at most 300 lines

#### Scenario: New modules added
- **GIVEN** the refactored codebase
- **WHEN** counting lines in `lib/clj_compiler/lexer.ex` and `lib/clj_compiler/parser.ex`
- **THEN** the combined lines SHALL be at most 400 lines

#### Scenario: Total reduction achieved
- **GIVEN** the refactored codebase
- **WHEN** comparing total lines of Reader, Lexer, and Parser modules to the original Reader module
- **THEN** there SHALL be at least 60% reduction in code
