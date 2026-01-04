# CljCompiler

Elixir library for writing modules using Clojure-like syntax, compiled at Elixir compile time.

## Installation

Clone the repository and fetch dependencies:

```sh
cd clj_compiler
mix deps.get
```

## Usage

Create a module that uses `CljCompiler` with a directory:

```elixir
defmodule MyApp do
  use CljCompiler, dir: "lib/clj"
end
```

Create `.clj` files in the specified directory with namespace declarations:

```clojure
(ns my.app.core)

(defn hello [] "Hello World")

(defn greet [name] (str "Hello, " name))
```

The compiler will:
1. Scan all `.clj` files in the directory at compile time
2. Extract namespace declarations
3. Generate corresponding Elixir modules
4. Inject functions into those modules

Call the functions using the generated module:

```elixir
My.App.Core.hello()
# => "Hello World"

My.App.Core.greet("Alice")
# => "Hello, Alice"
```

## Running Tests

```sh
mix test
```

## Current Features

- Namespace declarations `(ns ...)`
- Directory scanning and multi-file compilation
- Dynamic module generation from namespaces
- Function definitions with `defn` (with parameters)
- String literals and concatenation with `str`
- Numbers and arithmetic operations (`+`, `-`, `*`, `<`, `>`)
- Conditional expressions with `if`
- Local bindings with `let`
- Recursive function calls
- Elixir module interop (`Enum/count`, etc.)
- Vectors `[]`
- Compile-time error reporting
- Automatic recompilation on `.clj` file changes

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

1. Scan directory for `.clj` files at compile time
2. Register each file as `@external_resource`
3. Parse each file into intermediate AST
4. Extract namespace declarations
5. Convert namespaces to Elixir module names
6. Translate functions to Elixir AST
7. Generate `defmodule` for each namespace
8. Inject modules into compilation

See `spec.md` for detailed design documentation.