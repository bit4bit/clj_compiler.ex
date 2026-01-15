## ADDED Requirements
### Requirement: Exception Handling Translation
The system SHALL translate Clojure try/catch/finally forms to equivalent Elixir try/rescue/after constructs.

#### Scenario: Basic try/catch translation
- **WHEN** translating `(try (throw "error") (catch Exception e "caught"))`
- **THEN** it should produce Elixir AST equivalent to `try do throw "error" rescue e in Exception -> "caught" end`

#### Scenario: Multiple catch blocks translation
- **WHEN** translating `(try expr (catch RuntimeError e "runtime") (catch Exception e "general"))`
- **THEN** it should produce Elixir AST with multiple rescue clauses

#### Scenario: Finally block translation
- **WHEN** translating `(try expr (finally "cleanup"))`
- **THEN** it should produce Elixir AST with after clause

#### Scenario: Complete try/catch/finally translation
- **WHEN** translating `(try expr (catch Exception e "handle") (finally "cleanup"))`
- **THEN** it should produce Elixir AST with both rescue and after clauses

#### Scenario: Exception variable binding
- **WHEN** translating `(try expr (catch Exception e (str "caught: " e)))`
- **THEN** the exception variable `e` should be bound and available in the catch body

## MODIFIED Requirements
### Requirement: Function Call Validation
The system SHALL validate `throw` as a built-in function when used within try/catch contexts.

#### Scenario: Throw function validation
- **WHEN** calling `(throw "error")` within a try block
- **THEN** it should be recognized as a valid function call
- **WHEN** calling `(throw "error")` outside try/catch context
- **THEN** it should raise appropriate error if not defined