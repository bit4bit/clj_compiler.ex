# Contributing to CljCompiler

Elixir library for writing modules using Clojure-like syntax, compiled at Elixir compile time using Elixir’s macro system.

---

## Build / Lint / Test Commands

1. **Build project**: `mix compile` – compiles all Elixir source files
2. **Run all tests**: `mix test` – executes the full test suite
3. **Run a specific test file**: `mix test test/clj_compiler_test.exs`
4. **Run test at a specific line**: `mix test test/clj_compiler_test.exs:42`
5. **Run tests with tags**: `mix test --only some_tag` – executes tests marked `@tag some_tag`
6. **Run tests in watch mode**: `mix test.watch` – continuously reruns tests on file changes (requires `test.watch` dependency)
7. **Format code**: `mix format` – formats all Elixir files according to standard style
8. **Check formatting**: `mix format --check-formatted` – verifies formatting without modifying files
9. **Clean build artifacts**: `mix clean` – removes compiled artifacts from `_build`
10. **Interactive console**: `iex -S mix` – starts an interactive Elixir session with the project loaded
11. **Dependencies**: `mix deps.get` – fetches project dependencies (none currently required)

---

## Core Principles

1. **Test-Driven Development**: Write tests before implementing code; cover success and failure scenarios.
2. **Self-Documenting Code**: Use clear, descriptive names; functions should have single responsibilities.
3. **Explicit Implementation Only**: Implement exactly what is requested; avoid anticipatory features.
4. **Direct Corrections**: Fix issues immediately; let code reflect the fix.
5. **Collaborative Review**: Always involve human reviewers before finalizing changes.
6. **Functional Paradigm**: Favor immutable data, pure functions, and functional composition.

---

## Workflow

1. **Requirement Analysis**: Read `spec.md` and `ruleset.md` before starting any task.
2. **Test-First Approach**: Write failing tests defining expected behavior before implementing code.
3. **Minimal Implementation**: Write only the code necessary to pass tests, adhering to functional principles.
4. **Changelog Update**: Update `spec.md` with descriptions of changes.
5. **Verification**: Run the complete test suite and ensure all tests pass.
6. **Focused Commits**: One commit per feature, including its tests.
7. **Code Review**: Share changes with reviewers for feedback.
8. **Documentation Sync**: Update `README.md` for user-facing changes and `spec.md` for technical details.

---

## Implementation Coding Rules (TDD)

**CRITICAL: Never skip approval steps! Each approval gate is mandatory.**

1. **Write Tests First**: Based on acceptance criteria.
2. **Request Approval #1**: Ask the human reviewer for explicit approval before implementing any code.
3. **Run Tests**: Verify they fail (red).
4. **Write Minimal Code**: Implement the simplest code to pass tests (green).
5. **Run Tests**: Verify they pass (green).
6. **Request Approval #2**: Ask the human reviewer for explicit approval before proceeding with refactoring, documentation, or any other steps.
7. **Refactor** (if needed): Improve code while keeping tests green.
8. **Validate**: Ensure requirements are satisfied.
9. **Request Approval #3**: Ask the human reviewer for explicit approval before finalizing (documentation updates, changelog, etc.).

**STOP at each "Request Approval" step and wait for explicit human approval before continuing.**

---

## Testing Rules

* **Comprehensive Coverage**: Every path, function, and error condition must have tests.
* **Assertion Uniqueness**: Each test validates a unique aspect; do not duplicate assertions.
* **Test Immutability**: Never modify assertions during refactoring; adjust the implementation instead.
* **Continuous Verification**: Run tests after each change.
* **Descriptive Names**: Test names should clearly describe the behavior tested.
* **Organization**: Group related tests in `describe` blocks.
* **Failure Analysis**: Provide clear, actionable error messages.

---

## Naming Conventions

* **Functions**: `snake_case` (e.g., `parse_expression`)
* **Modules**: `PascalCase` (e.g., `CljCompiler.Reader`)
* **Variables / Parameters**: `snake_case`
* **Constants**: `ALL_CAPS` (e.g., `MAX_RECURSION_DEPTH`)
* **Test Names**: Descriptiv
