# clj-syntax

## Purpose
This specification defines the syntax and parsing rules for the Clojure-like language compiler, including support for comments, exception handling, and core language constructs.
## Requirements
### Requirement: Line Comments
The system SHALL support line comments starting with `;` character.

#### Scenario: Simple line comment at start
- **WHEN** parsing `(defn foo [] ; this is a comment\n  "body")`
- **THEN** the comment should be stripped and not affect parsing
- **THEN** the form should parse successfully

#### Scenario: Line comment after code
- **WHEN** parsing `(defn foo [] "body" ; comment after code)`
- **THEN** everything after `;` should be treated as comment
- **THEN** the form should parse successfully

#### Scenario: Comment within string should not be stripped
- **WHEN** parsing `(defn foo [] "string with ; semicolon")`
- **THEN** the semicolon inside the string should be preserved
- **THEN** the form should parse successfully with the string intact

#### Scenario: Multiple comments on same line
- **WHEN** parsing `(defn foo [] ; comment 1 ; comment2\n  "body")`
- **THEN** only the first `;` should start the comment
- **THEN** the form should parse successfully

### Requirement: Block Comments via Reader Macro
The system SHALL support block comments using the `#_` reader macro that skips the next complete form.

#### Scenario: Skip next form with #_
- **WHEN** parsing `(defn foo [] #_ (skip-me) "body")`
- **THEN** the form `(skip-me)` should be completely ignored
- **THEN** the remaining code should parse successfully

#### Scenario: Skip nested form with #_
- **WHEN** parsing `(defn foo [] #_ [a b c] "body")`
- **THEN** the vector `[a b c]` should be ignored
- **THEN** the form should parse successfully

#### Scenario: Skip map with #_
- **WHEN** parsing `(defn foo [] #_ {:key "value"} "body")`
- **THEN** the map should be ignored
- **THEN** the form should parse successfully

#### Scenario: Multiple #_ in sequence
- **WHEN** parsing `(defn foo [] #_ (a) #_ (b) "body")`
- **THEN** both forms should be skipped
- **THEN** the form should parse successfully

### Requirement: Nested Comments
The system SHALL correctly handle nested structures when comments are involved.

#### Scenario: Comment inside list
- **WHEN** parsing `(defn foo [] (list 1 ; inner comment\n 2 3))`
- **THEN** the inner comment should be stripped
- **THEN** the list should parse correctly

#### Scenario: #_ inside list
- **WHEN** parsing `(defn foo [] (list 1 #_ (skip) 2 3))`
- **THEN** the skipped form should be removed from the list
- **THEN** the list should contain only `[1, 2, 3]`

### Requirement: Comment Special Form
The system SHALL support the `comment` special form for multi-line code commenting.

#### Scenario: Basic comment form
- **WHEN** parsing `(comment (defn foo [] "body") (defn bar [] "other"))`
- **THEN** the forms inside should be ignored
- **THEN** the comment form should evaluate to `nil`

#### Scenario: Comment with single form
- **WHEN** parsing `(comment (defn foo [] "body"))`
- **THEN** the inner form should be ignored
- **THEN** the result should be `nil`

#### Scenario: Nested comment forms
- **WHEN** parsing `(comment (comment (defn foo [] "body")))`
- **THEN** both levels should be handled correctly
- **THEN** the result should be `nil`

#### Scenario: Comment with expressions
- **WHEN** parsing `(comment 1 2 3 "string" :keyword)`
- **THEN** all expressions should be ignored
- **THEN** the result should be `nil`

#### Scenario: Comment inside function definition
- **WHEN** parsing `(defn foo [] (comment this is ignored) "body")`
- **THEN** the comment form should be removed during translation
- **THEN** the function should compile to just `"body"`

### Requirement: Mixed Comment Types
The system SHALL allow combining different comment types.

#### Scenario: #_ with comment form
- **WHEN** parsing `(comment #_ (skip-me) (keep-me))`
- **THEN** the `#_` should skip the first form
- **THEN** the `comment` form should ignore remaining forms
- **THEN** the result should be `nil`

#### Scenario: Line comments with comment form
- **WHEN** parsing `(comment\n  (defn foo [] "body")\n  ; line comment\n  (defn bar [] "other"))`
- **THEN** all content should be ignored
- **THEN** the result should be `nil`

### Requirement: Exception Handling Syntax
The system SHALL support Clojure-style try/catch/finally syntax for exception handling.

#### Scenario: Basic try/catch
- **WHEN** parsing `(try (throw "error") (catch RuntimeError e "caught"))`
- **THEN** it should parse successfully as a try form with catch clause

#### Scenario: Try with multiple catch blocks
- **WHEN** parsing `(try expr (catch RuntimeError e "runtime") (catch ArgumentError e "general"))`
- **THEN** it should parse successfully with multiple catch clauses

#### Scenario: Try with finally
- **WHEN** parsing `(try expr (finally "cleanup"))`
- **THEN** it should parse successfully with finally clause

#### Scenario: Try/catch/finally combination
- **WHEN** parsing `(try expr (catch RuntimeError e "handle") (finally "cleanup"))`
- **THEN** it should parse successfully with both catch and finally clauses

#### Scenario: Nested try blocks
- **WHEN** parsing `(try (try inner (catch RuntimeError e "inner")) (catch RuntimeError e "outer"))`
- **THEN** it should parse successfully with nested try forms

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

### Requirement: Multi-Arity defn Syntax
The system SHALL support defining functions with multiple arities using the `defn` special form with multiple clause definitions.

#### Scenario: Multi-arity defn with two arities
- **WHEN** parsing `(defn concat ([] "") ([a] (str "hola " a)))`
- **THEN** the form SHALL be parsed as a defn with name "concat" and two arity clauses
- **THEN** the first arity SHALL have empty parameter vector `[]` with body `""`
- **THEN** the second arity SHALL have parameter vector `[a]` with body `(str "hola " a)`

#### Scenario: Multi-arity defn with three arities
- **WHEN** parsing `(defn foo ([] 0) ([x] x) ([x y] (+ x y)))`
- **THEN** the form SHALL be parsed as a defn with three arity clauses
- **THEN** arity 0 returns 0, arity 1 returns the argument, arity 2 returns sum

#### Scenario: Multi-arity defn with 0-arity and 1-arity
- **WHEN** parsing `(defn greet ([] "Hello!") ([name] (str "Hello, " name)))`
- **THEN** the 0-arity form SHALL be recognized with empty parameter vector
- **THEN** the 1-arity form SHALL have single parameter

#### Scenario: Multi-arity defn with docstring
- **WHEN** parsing `(defn concat "Concatenates strings" ([] "") ([a] (str "hola " a)))`
- **THEN** the docstring "Concatenates strings" SHALL be preserved before arity clauses
- **THEN** the arity clauses SHALL be parsed after the docstring

### Requirement: Single-Arity defn Remains Unchanged
The system SHALL continue to support single-arity defn syntax for backward compatibility.

#### Scenario: Single-arity defn with params vector
- **WHEN** parsing `(defn foo [x] (* x 2))`
- **THEN** it SHALL parse as single-arity defn
- **THEN** the body SHALL be a simple expression list

#### Scenario: Single-arity defn with docstring
- **WHEN** parsing `(defn foo "Doubles a number" [x] (* x 2))`
- **THEN** it SHALL parse as single-arity defn with docstring
- **THEN** the docstring SHALL be preserved

### Requirement: Multi-Arity defn Detection
The system SHALL distinguish between single-arity and multi-arity defn forms.

#### Scenario: Single-arity defn with params vector
- **WHEN** parsing `(defn foo [x] (* x 2))`
- **THEN** it SHALL parse as single-arity defn
- **THEN** the body SHALL be a simple expression list

#### Scenario: Multi-arity defn with multiple ([params] body) clauses
- **WHEN** parsing `(defn bar ([] 1) ([x] 2))`
- **THEN** it SHALL parse as multi-arity defn
- **THEN** the parser SHALL recognize the multiple vector-body pairs

### Requirement: Multi-Arity Syntax Validation
The system SHALL validate multi-arity function definitions for correctness.

#### Scenario: Reject duplicate arities in defn
- **WHEN** parsing `(defn dup ([] 1) ([x] 2) ([y] 3))`
- **THEN** it SHALL report an error for duplicate arities (0-arity appears once)
- **THEN** error message SHALL indicate which arity is duplicated

#### Scenario: Require at least one arity clause
- **WHEN** parsing `(defn empty [])`
- **THEN** it SHALL report an error for missing arity clauses

#### Scenario: Require vectors for arity parameters
- **WHEN** parsing `(defn bad (x) x)`
- **THEN** it SHALL report an error for non-vector arity specification

#### Scenario: Require bodies for each arity
- **WHEN** parsing `(defn incomplete ([]) ([x]))`
- **THEN** it SHALL report an error for missing body expressions

### Requirement: Tuple Syntax
The system SHALL support tuple data type using `#[...]` reader macro syntax.

#### Scenario: Simple tuple with atoms
- **WHEN** parsing `#[:a :b]`
- **THEN** the form SHALL be parsed as a tuple containing `:a` and `:b`
- **THEN** it SHALL translate to Elixir AST equivalent to `{:a, :b}`

#### Scenario: Tuple with nested map
- **WHEN** parsing `#[{:a 1} [1 2]]`
- **THEN** the form SHALL be parsed as a tuple with a map and a vector
- **THEN** it SHALL translate to Elixir AST equivalent to `{%{a: 1}, [1, 2]}`

#### Scenario: Empty tuple
- **WHEN** parsing `#[]`
- **THEN** the form SHALL be parsed as an empty tuple
- **THEN** it SHALL translate to Elixir AST equivalent to `{}`

#### Scenario: Tuple with single element
- **WHEN** parsing `#[{:a}]`
- **THEN** the form SHALL be parsed as a tuple with one element
- **THEN** it SHALL translate to Elixir AST equivalent to `{:a}`

#### Scenario: Tuple with multiple elements
- **WHEN** parsing `#[{:a 1 "string" :keyword}]`
- **THEN** the form SHALL be parsed as a tuple with four elements
- **THEN** it SHALL translate to Elixir AST equivalent to `{:a, 1, "string", :keyword}`

#### Scenario: Nested tuples
- **WHEN** parsing `#[[:a :b] [:c :d]]`
- **THEN** the form SHALL be parsed as a tuple containing two vectors
- **THEN** it SHALL translate to Elixir AST equivalent to `{:a, :b, :c, :d}`

#### Scenario: Tuple with list
- **WHEN** parsing `#(`
- **THEN** the form SHALL be parsed as a tuple containing a list
- **THEN** the list elements SHALL be translated first, then wrapped in tuple

#### Scenario: Tuple with keyword-module call
- **WHEN** parsing `#[:erlang/unique_integer []]}`
- **THEN** the form SHALL be parsed as a tuple containing an Erlang function call
- **THEN** it SHALL translate to Elixir AST equivalent to `{:erlang.unique_integer(), []}`

### Requirement: Tuple in Function Context
The system SHALL support tuples used within function bodies and definitions.

#### Scenario: Tuple as let binding value
- **WHEN** translating `(let [t #[:a :b]] t)`
- **THEN** the binding SHALL be initialized to `{:a, :b}`
- **THEN** the result SHALL be `{:a, :b}`

#### Scenario: Tuple as function return
- **WHEN** translating `(defn get-pair [] #[:a :b])`
- **THEN** the function SHALL return `{:a, :b}`
- **THEN** the Elixir definition SHALL be `def get_pair(), do: {:a, :b}`

#### Scenario: Tuple element access via elem
- **WHEN** translating `(elem #[:a :b] 0)`
- **THEN** it SHALL produce Elixir AST equivalent to `elem({:a, :b}, 0)`
- **THEN** the result SHALL be `:a`

#### Scenario: Tuple in function call argument
- **WHEN** translating `(some-fn #[:a :b] :other)`
- **THEN** the tuple SHALL be passed as an argument
- **THEN** the Elixir call SHALL be `some_fn({:a, :b}, :other)`

### Requirement: Tuple Parsing Edge Cases
The system SHALL handle edge cases in tuple syntax parsing.

#### Scenario: Tuple with comments
- **WHEN** parsing `#[{:a ; comment
 :b}]`
- **THEN** the comment SHALL be stripped
- **THEN** the tuple SHALL contain `:a` and `:b`

#### Scenario: Tuple with discard directive
- **WHEN** parsing `#[{:a #_ :skip :b}]`
- **THEN** the discarded form SHALL be ignored
- **THEN** the tuple SHALL contain `:a` and `:b`

#### Scenario: Tuple with mixed nested structures
- **WHEN** parsing `#[[:a] {:b 2} #[{:c 3}] :d]`
- **THEN** all nested forms SHALL be parsed correctly
- **THEN** the resulting Elixir tuple SHALL contain the translated elements

#### Scenario: Tuple after symbol
- **WHEN** parsing `my-symbol#[:a :b]`
- **THEN** the tuple SHALL be parsed as a separate form
- **THEN** the result SHALL be `my_symbol` followed by `{:a, :b}`

### Requirement: Tuple Error Handling
The system SHALL provide meaningful error messages for invalid tuple syntax.

#### Scenario: Unclosed tuple
- **WHEN** parsing `#[{:a :b`
- **THEN** it SHALL report a parse error with location information
- **THEN** error message SHALL indicate unclosed tuple

#### Scenario: Invalid element in tuple
- **WHEN** parsing `#(`
- **THEN** it SHALL report an appropriate parse error

