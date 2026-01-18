# clj-translation

## Purpose
This specification defines how Clojure code is translated to Elixir, including function call translation, exception handling, and Erlang module integration.

## Requirements

### Requirement: Erlang Module Function Call Translation
The system SHALL support calling functions from any Erlang module using the `:module/function` syntax.

#### Scenario: Call :erlang/unique_integer with no arguments
- **WHEN** translating `(:erlang/unique_integer)`
- **THEN** it should produce Elixir AST equivalent to `:erlang.unique_integer()`
- **THEN** the call should return an integer

#### Scenario: Call :erlang/unique_integer with options
- **WHEN** translating `(:erlang/unique_integer [:positive])`
- **THEN** it should produce Elixir AST equivalent to `:erlang.unique_integer([:positive])`
- **THEN** the call should return a positive integer

#### Scenario: Call :lists/append function
- **WHEN** translating `(:lists/append [1 2] [3 4])`
- **THEN** it should produce Elixir AST equivalent to `:lists.append([1, 2], [3, 4])`
- **THEN** the call should return `[1, 2, 3, 4]`

#### Scenario: Call :maps/get function with default
- **WHEN** translating `(:maps/get :key {:key 1 :other 2} :not-found)`
- **THEN** it should produce Elixir AST equivalent to `:maps.get(:key, %{key: 1, other: 2}, :not_found)`
- **THEN** the call should return `1`

#### Scenario: Call :timer/sleep function
- **WHEN** translating `(:timer/sleep 100)`
- **THEN** it should produce Elixir AST equivalent to `:timer.sleep(100)`
- **THEN** the call should pause execution for 100 milliseconds

#### Scenario: Call :string/trim function
- **WHEN** translating `(:string/trim "  hello  ")`
- **THEN** it should produce Elixir AST equivalent to `:string.trim("  hello  ")`
- **THEN** the call should return `"hello"`

#### Scenario: Use Erlang function in expression
- **WHEN** translating `(+ (:erlang/unique_integer) 1)`
- **THEN** it should produce Elixir AST equivalent to `(:erlang.unique_integer() + 1)`
- **THEN** the expression should evaluate correctly

#### Scenario: Call Erlang function in let binding
- **WHEN** translating `(let [id (:erlang/unique_integer)] id)`
- **THEN** it should produce Elixir AST with the Erlang call in the binding
- **THEN** the bound variable should contain the integer value

### Requirement: Erlang Function Call Validation
The system SHALL validate Erlang module function calls and skip standard validation for keyword-module pattern calls (`:Keyword/function`).

#### Scenario: :erlang module calls are allowed
- **WHEN** calling `(:erlang/unique_integer)`
- **THEN** it should not raise "undefined function" errors
- **THEN** it should compile successfully

#### Scenario: :lists module calls are allowed
- **WHEN** calling `(:lists/map inc [1 2 3])`
- **THEN** it should not raise "undefined function" errors
- **THEN** it should compile successfully and return `[2, 3, 4]`

#### Scenario: :ets module calls are allowed
- **WHEN** calling `(:ets/new :my_table [:set])`
- **THEN** it should not raise "undefined function" errors
- **THEN** it should compile successfully and return a table reference

#### Scenario: Multiple :erlang calls work correctly
- **WHEN** calling `(:erlang/unique_integer)` multiple times
- **THEN** each call should return a unique integer
- **THEN** the integers should be monotonically increasing

#### Scenario: Any Erlang module name is valid
- **WHEN** calling functions from modules like `:gen_server`, `:supervisor`, `:application`
- **THEN** they should all be accepted without "undefined function" errors
- **THEN** the pattern `:Keyword/function` works for any valid module name

### Requirement: Keyword-Module Function Call Parsing
The system SHALL handle the case where `:module` keyword is followed by `/function` symbol in a list, for any module name.

#### Scenario: Keyword followed by slash function parses correctly
- **WHEN** lexing and parsing `(:erlang/unique_integer)`
- **THEN** the lexer should produce tokens for `{:keyword, :erlang}` and `{:symbol, "/unique_integer"}`
- **THEN** the translator should combine them into a module.function call

#### Scenario: :lists module parsing
- **WHEN** lexing and parsing `(:lists/append [1] [2])`
- **THEN** the lexer should produce tokens for `{:keyword, :lists}` and `{:symbol, "/append"}`
- **THEN** the translator should combine them into `:lists.append([1], [2])`

#### Scenario: :maps module parsing
- **WHEN** lexing and parsing `(:maps/get :key {:a 1})`
- **THEN** the lexer should produce tokens for `{:keyword, :maps}` and `{:symbol, "/get"}`
- **THEN** the translator should combine them into `:maps.get(:key, %{a: 1})`

#### Scenario: Nested Erlang function calls
- **WHEN** translating `(:erlang/unique_integer (:erlang/unique_integer))`
- **THEN** both calls should be translated correctly
- **THEN** the outer call should receive the inner call's result

#### Scenario: Chained Erlang function calls
- **WHEN** translating `(:lists/map (:erlang/unique_integer) [1 2 3])`
- **THEN** both the `:erlang/unique_integer` and `:lists/map` calls should be translated
- **THEN** the result should be a list with the unique integer applied as a function

## Exception Handling Translation
The system translates Clojure try/catch/finally forms to equivalent Elixir try/rescue/after constructs.

### Basic try/catch translation
- **WHEN** translating `(try (throw "error") (catch RuntimeError e "caught"))`
- **THEN** it should produce Elixir AST equivalent to `try do raise "error" rescue e in RuntimeError -> "caught" end`

### Multiple catch blocks translation
- **WHEN** translating `(try expr (catch RuntimeError e "runtime") (catch ArgumentError e "general"))`
- **THEN** it should produce Elixir AST with multiple rescue clauses

### Finally block translation
- **WHEN** translating `(try expr (finally "cleanup"))`
- **THEN** it should produce Elixir AST with after clause

### Complete try/catch/finally translation
- **WHEN** translating `(try expr (catch RuntimeError e "handle") (finally "cleanup"))`
- **THEN** it should produce Elixir AST with both rescue and after clauses

### Exception variable binding
- **WHEN** translating `(try expr (catch RuntimeError e (str "caught: " e)))`
- **THEN** the exception variable `e` should be bound and available in the catch body

### Function Call Validation
The system validates `throw` as a built-in function when used within try/catch contexts.

- **WHEN** calling `(throw "error")` within a try block
- **THEN** it should be recognized as a valid function call
- **WHEN** calling `(throw "error")` outside try/catch context
- **THEN** it should raise appropriate error if not defined