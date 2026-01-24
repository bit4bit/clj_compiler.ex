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

### Requirement: Multi-Arity defn Translation
The system SHALL translate multi-arity `defn` forms to Elixir multi-clause function definitions.

#### Scenario: Translate two-arity defn to Elixir
- **WHEN** translating `(defn concat ([] "") ([a] (str "hola " a)))`
- **THEN** it SHALL produce Elixir AST equivalent to:
  ```elixir
  def concat(), do: ""
  def concat(a), do: "hola " <> a
  ```

#### Scenario: Translate three-arity defn
- **WHEN** translating `(defn foo ([] 0) ([x] x) ([x y] (+ x y)))`
- **THEN** it SHALL produce Elixir AST with three `def` clauses
- **THEN** each clause SHALL have correct parameter count
- **THEN** arity 0 returns 0, arity 1 returns the argument, arity 2 returns sum

#### Scenario: Translate 0-arity and 1-arity combination
- **WHEN** translating `(defn greet ([] "Hello!") ([name] (str "Hello, " name)))`
- **THEN** the 0-arity SHALL translate to `def greet(), do: "Hello!"`
- **THEN** the 1-arity SHALL translate to `def greet(name), do: ...`

#### Scenario: Preserve line numbers for each clause
- **WHEN** translating multi-arity defn with clauses on different lines
- **THEN** each generated `def` clause SHALL have correct line metadata

#### Scenario: Multi-arity with docstring
- **WHEN** translating `(defn concat "Concatenates" ([] "") ([a] a))`
- **THEN** the docstring SHALL be preserved as `@doc` attribute
- **THEN** the arity clauses SHALL be generated after the docstring

### Requirement: Multi-Arity Body Translation
The system SHALL correctly translate the body of each arity clause.

#### Scenario: Translate body expressions in each defn clause
- **WHEN** translating `(defn math ([] 0) ([x] (* x 2)) ([x y] (+ x y)))`
- **THEN** each body expression SHALL be translated using the existing translation logic
- **THEN** the `*` operator SHALL become Elixir `*`
- **THEN** the `+` operator SHALL become Elixir `+`

#### Scenario: Use let bindings in multi-arity defn body
- **WHEN** translating `(defn with-let ([] (let [x 1] x)) ([y] (let [z y] z)))`
- **THEN** each arity clause SHALL correctly translate let bindings
- **THEN** variable scoping SHALL be correct per clause

#### Scenario: Nested expressions in multi-arity defn body
- **WHEN** translating `(defn nested ([] (if true "a" "b")) ([x] (if (nil? x) "c" "d")))`
- **THEN** the if expressions SHALL be translated correctly per clause

### Requirement: Multi-Arity Function Calls
The system SHALL correctly route function calls to the appropriate arity clause.

#### Scenario: Call 0-arity defn function
- **WHEN** calling `(concat)` where concat has 0-arity clause
- **THEN** it SHALL invoke the 0-arity clause
- **THEN** the result SHALL be from the 0-arity body

#### Scenario: Call 1-arity defn function
- **WHEN** calling `(concat "world")` where concat has 1-arity clause
- **THEN** it SHALL invoke the 1-arity clause
- **THEN** the result SHALL be from the 1-arity body

#### Scenario: Call with wrong arity raises Elixir function clause error
- **WHEN** calling a multi-arity function with unsupported argument count
- **THEN** Elixir runtime SHALL raise a FunctionClauseError
- **THEN** the behavior SHALL match standard Elixir

#### Scenario: Multi-arity function in let binding
- **WHEN** binding `(let [f concat] (f) (f "x"))` where concat is multi-arity
- **THEN** each call SHALL resolve to the correct arity clause

### Requirement: Multi-Arity Local Function References
The system SHALL correctly handle local function definitions with multiple arities.

#### Scenario: Reference multi-arity defn in same namespace
- **WHEN** defining `(defn local ([] 0) ([x] x))` and calling `(local)` and `(local 5)`
- **THEN** both calls SHALL correctly invoke respective arity clauses
- **THEN** validation SHALL recognize both arities exist

#### Scenario: Multi-arity defn with fn inside body
- **WHEN** defining `(defn outer ([] (fn [x] (* x 2))) ([y] y))`
- **THEN** the outer function SHALL have two arities
- **THEN** the inner fn SHALL be a single-arity anonymous function
- **THEN** all clauses SHALL translate correctly

### Requirement: Multi-Arity Error Handling
The system SHALL provide appropriate error handling for invalid multi-arity function definitions.

#### Scenario: Missing arity clause raises error
- **WHEN** translating `(defn empty [])`
- **THEN** it SHALL raise a meaningful error indicating missing arity clauses

#### Scenario: Non-vector arity raises error
- **WHEN** translating `(defn bad (x) x)`
- **THEN** it SHALL raise an error for invalid arity specification

#### Scenario: Missing body raises error
- **WHEN** translating `(defn incomplete ([]))`
- **THEN** it SHALL raise an error for missing body expressions

#### Scenario: Duplicate arity raises error
- **WHEN** translating `(defn dup ([] 1) ([x] 2) ([y] 3))`
- **THEN** it SHALL raise an error for duplicate arities
- **THEN** error message SHALL indicate which arity is duplicated

### Requirement: Multi-Arity Function in Namespace Context
Multi-arity functions SHALL work correctly within namespace definitions and with qualified function calls.

#### Scenario: Multi-arity defn in namespace
- **WHEN** defining `(ns myapp.core) (defn util ([] 0) ([x] x))`
- **THEN** the function SHALL be accessible as `Myapp.Core.util()`
- **THEN** calling `Myapp.Core.util()` with no args returns `0`
- **THEN** calling `Myapp.Core.util(5)` returns `5`

#### Scenario: Calling multi-arity function from another namespace
- **WHEN** namespace A defines multi-arity function and namespace B uses it
- **THEN** calls from namespace B SHALL resolve to the correct clauses

#### Scenario: Single-arity fn passed to higher-order functions
- **WHEN** translating `(map (fn [x] (* x 2)) [1 2 3])`
- **THEN** the fn SHALL translate to a single-arity anonymous function
- **THEN** `map` SHALL invoke the function with one argument for each element

### Requirement: nil Literal Translation
The system SHALL translate the Clojure `nil` literal to Elixir `nil` value, consistent with how `true` and `false` are translated.

#### Scenario: Translate nil literal
- **WHEN** translating `nil`
- **THEN** it SHALL produce Elixir AST equivalent to `nil`

#### Scenario: nil in expressions
- **WHEN** translating `(if condition nil "default")`
- **THEN** the `nil` SHALL be translated to Elixir `nil`
- **THEN** the expression SHALL evaluate correctly

#### Scenario: nil in bindings
- **WHEN** translating `(let [x nil] x)`
- **THEN** the binding SHALL be initialized to `nil`
- **THEN** the result SHALL be `nil`

#### Scenario: nil alongside true and false
- **WHEN** translating a form containing `nil`, `true`, and `false`
- **THEN** each literal SHALL be translated correctly to its Elixir equivalent

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