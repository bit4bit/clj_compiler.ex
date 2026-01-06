# Contributing to CljCompiler

### Build/Lint/Test Commands

1. **Build project**: `mix compile` - compiles all Elixir source files
2. **Run all tests**: `mix test` - executes the complete test suite
3. **Run specific test file**: `mix test test/clj_compiler_test.exs` - runs tests in a specific file
4. **Run test at specific line**: `mix test test/clj_compiler_test.exs:42` - runs test at line 42 in specific file
5. **Run tests with tags**: `mix test --only some_tag` - runs tests marked with @tag some_tag
6. **Run tests in watch mode**: `mix test.watch` - runs tests continuously on file changes (requires test.watch dependency)
7. **Format code**: `mix format` - automatically formats all Elixir files according to standard Elixir style
8. **Format check**: `mix format --check-formatted` - checks if files are properly formatted without modifying them
9. **Clean build**: `mix clean` - removes compiled artifacts from _build directory
10. **Interactive console**: `iex -S mix` - starts an interactive Elixir session with project loaded
11. **Dependencies**: `mix deps.get` - fetches all project dependencies (none currently required)

### Core Principles

1. **Test-Driven Development**: Write comprehensive tests before implementing any code changes. Ensure every public function has corresponding test coverage that validates both success and failure scenarios.
2. **Self-Documenting Code**: Code must be written with clear, meaningful names and structure that makes its purpose obvious without requiring comments. Functions should have single responsibilities with descriptive names.
3. **Explicit Code Only**: Never write code that isn't explicitly requested. Focus on the minimal implementation that satisfies the requirements without adding unnecessary features or anticipatory code.
4. **Direct Communication**: When issues are identified in code, fix them immediately without apologies or explanations. Let the corrected code speak for itself.
5. **Collaborative Review**: Always involve human reviewers before finalizing refactored code to ensure alignment with project goals and standards.
6. **Functional Paradigm**: Prioritize immutable data structures, pure functions, and functional composition over mutable state and object-oriented patterns.

### Workflow

1. **Requirement Analysis**: Begin every task by carefully reading `spec.md` and `ruleset.md` to understand project requirements and constraints
2. **Test-First Approach**: Write failing tests that clearly define the expected behavior before implementing any code
3. **Minimal Implementation**: Create the simplest possible code that passes the tests, following functional programming principles
4. **Changelog Update**: Update `spec.md` with a clear description of what changed and why
5. **Verification**: Run the complete test suite and ensure all tests pass
6. **Focused Commits**: Make one commit per feature, ensuring each commit is self-contained with its associated tests
7. **Code Review**: Share changes with human reviewers for feedback and validation
8. **Documentation Sync**: Update README.md for any user-facing changes, while keeping technical docs in spec.md

### Testing Rules

- **Comprehensive Coverage**: Every code path, function, and error condition must have corresponding test assertions
- **Assertion Uniqueness**: Never duplicate test assertions across different tests - each test should validate a unique aspect
- **Test Immutability**: Never modify test assertions when refactoring code; change the implementation instead
- **Continuous Verification**: Execute tests after every code modification to catch regressions immediately
- **Descriptive Test Names**: Use clear, descriptive test names that explain what behavior is being validated
- **Test Organization**: Group related tests using `describe` blocks with clear names that match functionality
- **Failure Analysis**: Tests should produce clear error messages that pinpoint exactly what failed and why

### Naming Conventions

- **Functions**: Use snake_case for all function names (e.g., `parse_expression`, `translate_function`)
- **Modules**: Use PascalCase for module names (e.g., `CljCompiler.Reader`, `CljCompiler.Translator`)
- **Variables and Parameters**: Use snake_case for all variables, function parameters, and atoms (e.g., `current_module`, `parse_result`)
- **Constants**: Use ALL_CAPS with underscores for module-level constants (e.g., `MAX_RECURSION_DEPTH`)
- **Test Names**: Use descriptive snake_case names that explain the tested behavior (e.g., `parses_nested_lists`, `handles_syntax_errors`)
- **Aliases**: When aliasing modules, use the last part of the module name (e.g., `alias CljCompiler.Reader` becomes just `Reader`)

### Code Standards

- **Functional Style**: Prefer explicit parameters, immutable data, and declarative expression over mutable state and imperative operations
- **Function Length**: Keep functions short and focused with single responsibilities; break down complex functions into smaller, named helper functions
- **Pattern Matching**: Use pattern matching in function heads and case expressions instead of conditional statements wherever possible
- **Recursion**: Implement recursive algorithms using tail recursion when possible to avoid stack overflow issues
- **Data Structures**: Use maps, structs, and tuples for data representation; avoid creating custom structs unless absolutely necessary
- **Error Handling**: Return `{:ok, result}` for success and `{:error, reason}` for failure; use descriptive error messages with file/line/column information
- **Function Signatures**: Define clear, descriptive function signatures that make parameter requirements obvious
- **Module Organization**: Group related functions together within modules; use clear module boundaries that separate concerns

### Import and Dependency Management

- **Minimal Imports**: Only import functions that are actually used in the module; avoid wildcard imports (`import Module, only: :functions`)
- **Explicit Aliases**: Use `alias` statements for long module names, but avoid aliasing commonly used modules
- **Dependency Declaration**: List only necessary dependencies in `mix.exs`; avoid adding libraries unless explicitly required for functionality
- **Standard Library Use**: Prefer Elixir's standard library functions over external dependencies whenever possible
- **Import Organization**: Place all `alias`, `import`, and `require` statements at the top of the module after any module attributes

### Error Handling

- **Compile-Time Failures**: Detect and report errors during compilation rather than runtime when possible
- **Descriptive Messages**: Every error must include specific details about file, line, column, and the nature of the problem
- **Structured Errors**: Use consistent error tuple format `{:error, %{file: file, line: line, column: column, message: message}}`
- **Fast Failure**: Stop processing immediately when encountering irrecoverable errors; avoid defensive programming
- **Test Coverage**: Ensure error conditions have comprehensive test coverage with specific assertions about error messages
- **User-Friendly Messages**: Provide clear, actionable error messages that help developers understand and fix issues quickly

### Code Organization

- **Module Structure**: Begin modules with aliases/imports, then module attributes, public functions, private functions
- **Function Ordering**: Arrange functions from most general to most specific; place helper functions after their callers
- **File Organization**: Each module gets one file with matching name (e.g., `lib/clj_compiler/reader.ex` for `CljCompiler.Reader`)
- **Directory Structure**: Keep production code in `lib/`, tests in `test/`, test fixtures in `test/fixtures/`
- **Integration Tests**: Place integration test projects in `integration_test/` directory to validate full system behavior

### Patterns and Idioms

- **Pipe Operator**: Chain function calls using the `|>` operator to create readable data transformation pipelines
- **With Expression**: Use `with` for complex conditional logic that must succeed in sequence or fail cleanly
- **Function Composition**: Build complex operations from simple, focused functions that can be easily tested and reused
- **List Comprehensions**: Use list comprehensions for transforming collections when they improve clarity
- **Guard Clauses**: Use guard expressions in function heads for early input validation and clear preconditions

### Commit Strategy

- **One Feature Per Commit**: Each commit should implement exactly one feature with its complete test coverage
- **Self-Contained Changes**: Commits must be independent and functional, requiring neither previous nor subsequent commits
- **Message Format**: Use 50/70 format - subject line ≤ 50 characters, body lines ≤ 70 characters each
- **Descriptive Content**: Focus commit messages on what changed and why, not how the implementation works
- **Manual Commits Only**: Never commit automatically; always require explicit human approval before committing
- **Test Inclusion**: Every feature commit must include corresponding tests that validate the new functionality

### Documentation

- **Spec Updates**: Always update `spec.md` with new features, changes, and bug fixes to maintain a comprehensive changelog
- **README Changes**: Modify `README.md` only when introducing user-facing changes like new CLI commands or API changes
- **Concise Writing**: Keep all documentation focused and to the point; avoid verbose explanations
- **Markdown Format**: Use standard Markdown for all documentation files in the project
- **Version Tracking**: Maintain accurate version information and release notes in spec.md
- **Technical Details**: Document implementation details in spec.md, leaving README.md for usage instructions

### What NOT to Do

- **Altering Test Assertions**: Never modify test assertions to make tests pass; change the implementation instead
- **Skipping Tests**: Always run and fix failing tests; never commit with failing test suite
- **Unrequested APIs**: Create APIs only when explicitly requested; avoid anticipating future needs
- **Automatic Commits**: Require human approval for all commits; never commit automatically
- **Unnecessary Robustness**: Don't add error handling or defensive code unless specifically requested
- **Unused Examples**: Never create example code, demonstrations, or unused proof-of-concept implementations
- **Excessive Comments**: Write self-documenting code instead of adding comments to explain unclear code
- **External Dependencies**: Don't add libraries or dependencies unless absolutely required for the task
- **Complex Solutions**: Prefer simple, straightforward implementations over complex or over-engineered approaches
- **Premature Optimization**: Focus on correct functionality first; optimize only when performance issues are demonstrated
- **Mutable State**: Avoid mutable variables and global state; use functional programming principles instead
- **Conditional Logic**: Prefer pattern matching over if/else conditionals whenever feasible
- **Long Functions**: Don't write functions that exceed single-screen readability; break them into smaller functions

### Before Submitting

1. **Test Verification**: Run `mix test` and ensure all tests pass without warnings or errors
2. **Code Review**: Use `git diff` to review all changes for consistency and correctness
3. **Documentation Update**: Verify `spec.md` includes changelog entries for all new features and changes
4. **README Check**: If changes affect users, ensure `README.md` reflects the updated functionality
5. **Formatting**: Run `mix format` to ensure code follows Elixir formatting standards
6. **Regression Testing**: Confirm no existing functionality has been broken by the changes
7. **Dependency Check**: Verify the project compiles and runs without errors in a clean environment
8. **Peer Review**: Have another developer review the changes before final submission
9. **Conflict Resolution**: Resolve any merge conflicts and ensure the branch is up to date with main
10. **Final Test Run**: Execute the full test suite one final time before marking the task complete
