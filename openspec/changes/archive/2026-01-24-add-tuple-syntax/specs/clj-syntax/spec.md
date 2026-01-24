## ADDED Requirements
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
