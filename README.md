# LLM-Assisted

# CljCompiler

Elixir library for writing modules using Clojure-like syntax, compiled at Elixir compile time.

## Installation

Clone the repository and fetch dependencies:

```sh
cd clj_compiler
mix deps.get
```

## Usage

Create a module that uses `CljCompiler`:

```elixir
defmodule MyModule do
  use CljCompiler
end
```

Create a corresponding `.clj` file at `test/fixtures/Elixir.MyModule.clj`:

```clojure
(defn hello [] "Hello World")
```

The compiler will read the `.clj` file at compile time and generate the Elixir function.

Call the function:

```elixir
MyModule.hello()
# => "Hello World"
```

## Running Tests

```sh
mix test
```

## Current Features

- Function definitions with `defn` (with parameters)
- String literals and concatenation with `str`
- Numbers and arithmetic operations (`+`, `-`, `*`, `<`, `>`)
- Conditional expressions with `if`
- Local bindings with `let`
- Recursive function calls
- Elixir module interop (`Enum/count`, etc.)
- Vectors `[]`
- Compile-time error reporting

## Roadmap

- True `recur` tail-call optimization
- Multiple function arities
- Keywords (`:keyword`)
- Map literals `{}`
- Destructuring in `let`
- Error messages with line numbers
- More operators and built-in functions

## Architecture

The compilation pipeline:

1. Read `.clj` file at compile time
2. Parse into intermediate AST
3. Translate to Elixir AST
4. Inject functions into module

See `spec.md` for detailed design documentation.