## ADDED Requirements
### Requirement: Exception Handling Syntax
The system SHALL support Clojure-style try/catch/finally syntax for exception handling.

#### Scenario: Basic try/catch
- **WHEN** parsing `(try (throw "error") (catch Exception e "caught"))`
- **THEN** it should parse successfully as a try form with catch clause

#### Scenario: Try with multiple catch blocks
- **WHEN** parsing `(try expr (catch RuntimeError e "runtime") (catch Exception e "general"))`
- **THEN** it should parse successfully with multiple catch clauses

#### Scenario: Try with finally
- **WHEN** parsing `(try expr (finally "cleanup"))`
- **THEN** it should parse successfully with finally clause

#### Scenario: Try/catch/finally combination
- **WHEN** parsing `(try expr (catch Exception e "handle") (finally "cleanup"))`
- **THEN** it should parse successfully with both catch and finally clauses

#### Scenario: Nested try blocks
- **WHEN** parsing `(try (try inner (catch Exception e "inner")) (catch Exception e "outer"))`
- **THEN** it should parse successfully with nested try forms