## Context
Clojure's try/catch/finally syntax provides exception handling similar to Java/Elixir but with Clojure's Lisp-style syntax. The current CljCompiler supports basic forms but lacks exception handling.

## Goals / Non-Goals
- Goals:
  - Support Clojure's try/catch/finally syntax
  - Translate to Elixir's try/rescue/after
  - Handle multiple catch blocks with pattern matching
  - Support finally block for cleanup
- Non-Goals:
  - Support Java-style checked exceptions
  - Support custom exception hierarchies
  - Support try-with-resources (Java 7+)

## Decisions
- Decision: Use Elixir's try/rescue/after for translation
  - Rationale: Direct mapping to Elixir's exception handling
  - Alternatives considered: Custom exception handling macros
- Decision: Support multiple catch blocks with pattern matching
  - Rationale: Matches Clojure's flexibility
  - Implementation: Translate to multiple rescue clauses
- Decision: finally block translates to after block
  - Rationale: Direct semantic equivalence

## Risks / Trade-offs
- Risk: Complex nested forms may be challenging to parse
  - Mitigation: Follow existing pattern for nested forms
- Risk: Error messages for malformed try/catch
  - Mitigation: Clear compile-time errors

## Migration Plan
No migration needed - new feature

## Open Questions
- Should we support re-throwing exceptions with (throw ...)?
- Should we support custom exception types beyond standard Elixir exceptions?