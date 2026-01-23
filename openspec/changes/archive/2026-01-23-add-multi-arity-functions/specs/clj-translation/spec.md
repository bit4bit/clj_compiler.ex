# Change: Add Multi-Arity Function Support
## ADDED Requirements

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