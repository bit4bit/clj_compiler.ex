# CljCompiler

Elixir library for writing modules using Clojure-like syntax, compiled at Elixir compile time.

## Installation

Clone the repository and fetch dependencies:

```sh
cd clj_compiler
mix deps.get
```

## Usage

Create a module that uses `CljCompiler` with a directory (or multiple directories):

```elixir
defmodule ClojureProject do
  use CljCompiler, dir: "lib/clj"
end
```

```elixir
# Or with multiple directories
defmodule ClojureProject do
  use CljCompiler, dir: ["src", "lib/clj", "vendor/clj"]
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
1. Scan all `.clj` files in the directory (or directories) at compile time
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

### Maps and Keywords

Maps use Clojure-style syntax with keyword keys:

```clojure
(ns my.data)

(defn create_person [name age]
  {:name name :age age})

(defn get_config []
  {:host "localhost" :port 8080 :debug true})
```

```elixir
ClojureProject.My.Data.create_person("Alice", 30)
# => %{name: "Alice", age: 30}

ClojureProject.My.Data.get_config()
# => %{host: "localhost", port: 8080, debug: true}
```

Keywords are automatically converted to Elixir atoms, and maps compile to native Elixir map syntax.

## Running Tests

```sh
mix test
```

## Current Features

- Namespace declarations `(ns ...)`
- **Multiple directories support** - Specify single directory or list of directories
- Directory scanning and multi-file compilation
- Dynamic module generation from namespaces
- **Parent module function access** - Call Elixir functions defined in the parent module from Clojure code
- **Automatic Kernel fallback** - Any Kernel function automatically available when not in parent module
- **Improved error reporting** - Parse errors with line numbers, column numbers, and descriptive messages
- Function definitions with `defn` (with parameters)
- String literals and concatenation with `str`
- Numbers and arithmetic operations (`+`, `-`, `*`, `<`, `>`)
- Conditional expressions with `if`
- Local bindings with `let`
- Recursive function calls
- Elixir module interop (`Enum/count`, etc.)
- Vectors `[]`
- **Map literals** - `{:key value}` syntax with keyword keys
- **Keywords** - `:keyword` becomes atom in Elixir
- **Boolean literals** - `true` and `false`
- Compile-time error reporting with precise location info
- Automatic recompilation on `.clj` file changes

## Error Reporting

The compiler provides detailed error messages with file paths, line numbers, and column numbers:

```
Parse error at line 4, column 3 in lib/clj/example.clj:
Unclosed parenthesis
```

Common errors detected:
- Unclosed parentheses or brackets
- Missing namespace declarations
- Invalid syntax with exact location information

### Undefined Function Errors

The compiler validates function calls at compile time and provides helpful error messages for undefined functions:

```
** (CompileError) example/collections.clj:4: Undefined function: conj

Available options:
- Local functions: add_to_list
- Parent module: qualify with MyApp/conj
- Imported modules: (none)
- Elixir interop: Module/function (e.g., Enum/map)
- Built-in operators: +, -, *, /, <, >, etc.

Hint: Did you forget (:use [CljCompiler.Compat]) in your namespace?
```

This helps developers quickly identify and fix undefined function calls by suggesting available options.

## Roadmap

- True `recur` tail-call optimization
- Multiple function arities
- Map access functions (get, assoc, dissoc)
- Map destructuring
- Destructuring in `let`
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