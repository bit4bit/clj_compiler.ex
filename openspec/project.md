# Project Context

## Purpose
Elixir library for writing modules using Clojure-like syntax, compiled at Elixir compile time. Allows developers to write code in Clojure syntax that compiles to Elixir modules with seamless interop between Clojure and Elixir code.

## Tech Stack
- Elixir ~1.15
- Mix build tool
- ExUnit for testing
- No external dependencies

## Project Conventions

### Code Style
- Follows Elixir standard formatting with `.formatter.exs`
- Snake_case for Elixir functions and variables
- CamelCase for module names
- Keywords as atoms (e.g., `:keyword`)
- Parentheses for function calls in Clojure syntax
- Indentation: 2 spaces

### Architecture Patterns
- **Simple design principle**: Minimal, focused components with single responsibilities
- Compile-time macro expansion using `__using__` and `__before_compile__`
- AST transformation pipeline: Clojure → Intermediate AST → Elixir AST
- Module generation with dynamic nesting based on namespace hierarchy
- Parent-child module relationship for function resolution
- External resource tracking for file change detection
- **TDD-driven design**: Architecture emerges from test requirements, not upfront over-engineering

### Testing Strategy
- **Test-Driven Development (TDD) approach**: Write tests first, then implement functionality
- **Red-Green-Refactor cycle**: Start with failing test, make it pass, then improve code
- Unit tests for individual components (Reader, Translator, Compat)
- Integration tests with actual `.clj` file compilation
- Test fixtures in `test/fixtures/` directory
- Error case testing for parse errors and undefined functions
- Test coverage for all supported Clojure forms

### Design Principles

- **Simple design principle**: Tests drive minimal implementation that satisfies requirements

### Git Workflow
- Conventional commits with descriptive messages
- Feature branches for new functionality
- Pull requests with comprehensive testing
- Commit messages follow pattern: "Add/Update/Fix [feature]"
- Regular updates to documentation and spec files

## Domain Context
- Clojure syntax parsing and transformation
- Elixir metaprogramming and macro system
- Namespace-based module organization
- Cross-language interoperability patterns
- Compile-time vs runtime function resolution
- Error reporting with precise location information

## Important Constraints
- Must maintain Elixir 1.15 compatibility
- No runtime dependencies allowed
- Must support incremental compilation
- Error messages must include file, line, and column information
- Must handle edge cases in Clojure syntax
- Parent module functions must be accessible from Clojure code
- Kernel functions must be available as fallback

## External Dependencies
- None (pure Elixir library)
- Uses Elixir standard library only
- Integration with Mix compilation pipeline
- Compatible with Elixir's code loading system
