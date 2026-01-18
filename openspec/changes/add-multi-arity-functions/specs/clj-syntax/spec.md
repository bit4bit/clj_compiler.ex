## ADDED Requirements

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

### Requirement: Multi-Arity fn Syntax (Same Arity Only)
The system SHALL support defining anonymous functions with multiple clauses, but all clauses MUST have the same arity.

#### Scenario: Multi-arity fn with same arity (1 parameter)
- **WHEN** parsing `(fn ([x] (* x 2)) ([x] (+ x 1)))`
- **THEN** the form SHALL be parsed as an anonymous function with two clauses
- **THEN** both clauses SHALL have exactly one parameter `x`
- **THEN** the clauses have different bodies

#### Scenario: Multi-arity fn with same arity (2 parameters)
- **WHEN** parsing `(fn ([x y] (+ x y)) ([x y] (* x y)))`
- **THEN** the form SHALL be parsed as an anonymous function with two clauses
- **THEN** both clauses SHALL have exactly two parameters `x` and `y`

#### Scenario: Multi-arity fn with 0-arity and 1-arity is rejected
- **WHEN** parsing `(fn ([] 0) ([x] (* x 2)))`
- **THEN** an error SHALL be raised because different arities are not allowed for anonymous functions
- **THEN** error message SHALL indicate that fn requires same arity across all clauses

#### Scenario: Multi-arity fn with 1-arity and 2-arity is rejected
- **WHEN** parsing `(fn ([x] x) ([x y] (+ x y)))`
- **THEN** an error SHALL be raised because different arities are not allowed for anonymous functions

### Requirement: Single-Arity fn Remains Unchanged
The system SHALL continue to support single-arity fn syntax for backward compatibility.

#### Scenario: Single-parameter fn
- **WHEN** parsing `(fn [x] (* x 2))`
- **THEN** it SHALL parse as a single-arity anonymous function
- **THEN** the body SHALL be a simple expression

#### Scenario: Multi-parameter fn (same arity)
- **WHEN** parsing `(fn [x y] (+ x y))`
- **THEN** it SHALL parse as a single-arity anonymous function with two parameters

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

#### Scenario: Reject fn with different arities
- **WHEN** parsing `(defn bad ([] 1) ([x] 2) ([x y] 3))`
- **THEN** it SHALL report an error for fn requiring same arity

#### Scenario: Require at least one arity clause
- **WHEN** parsing `(defn empty [])`
- **THEN** it SHALL report an error for missing arity clauses

#### Scenario: Require vectors for arity parameters
- **WHEN** parsing `(defn bad (x) x)`
- **THEN** it SHALL report an error for non-vector arity specification

#### Scenario: Require bodies for each arity
- **WHEN** parsing `(defn incomplete ([]) ([x]))`
- **THEN** it SHALL report an error for missing body expressions