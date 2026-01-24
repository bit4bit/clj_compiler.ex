## ADDED Requirements
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
