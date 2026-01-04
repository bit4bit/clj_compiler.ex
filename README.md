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
defmodule ClojureProject do
  use CljCompiler, dir: "lib/clj"
end
```

All generated modules will be nested under `ClojureProject`.

Create `.clj` files in the specified directory with namespace declarations:

```clojure
(ns my.app.core)

(defn hello [] "Hello World")

(defn greet [name] (str "Hello, " name))
```

The compiler will:
1. Scan all `.clj` files in the directory at compile time
2. Extract namespace declarations `(ns ...)`
3. Convert namespaces to module names (e.g., `my.app.core` → `My.App.Core`)
4. Nest generated modules under the parent module
5. Generate `defmodule` for each namespace
6. Inject functions into those modules

Call the functions using the nested module path:

```elixir
ClojureProject.My.App.Core.hello()
# => "Hello World"

ClojureProject.My.App.Core.greet("Alice")
# => "Hello, Alice"
```

The namespace `my.app.core` becomes `ClojureProject.My.App.Core` because modules are nested under the parent.

### Calling Parent Module Functions

Functions defined in the parent module are accessible from Clojure code:

```elixir
defmodule ClojureProject do
  use CljCompiler, dir: "lib/clj"
  
  def do_sum(a, b), do: a + b
end
```

```clojure
(ns my.math)

(defn calculate [x y]
  (do_sum x y))
```

```elixir
ClojureProject.My.Math.calculate(5, 10)
# => 15
```

Unknown function calls are resolved in this order:
1. Built-in operators (`+`, `-`, `*`, etc.) - left unqualified
2. Local functions defined in the same namespace - left unqualified
3. Unknown functions - runtime check: parent module first, then Kernel fallback

The compiler automatically tries to call functions from the parent module first. If the function doesn't exist there, it falls back to `Kernel` automatically at runtime using `function_exported?/3`.

Example using Kernel function:

```clojure
(ns my.utils)

(defn get_size [lst]
  (length lst))
```

```elixir
ClojureProject.My.Utils.get_size([1, 2, 3])
# => 3
```

The `length` function is not defined in `ClojureProject`, so it automatically falls back to `Kernel.length/1`.

## Running Tests

```sh
mix test
```

## Current Features

- Namespace declarations `(ns ...)`
- Directory scanning and multi-file compilation
- Dynamic module generation from namespaces
- **Parent module function access** - Call Elixir functions defined in the parent module from Clojure code
- **Automatic Kernel fallback** - Any Kernel function automatically available when not in parent module
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