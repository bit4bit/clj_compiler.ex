# LLM-Assisted

# Walking Skeleton Design Document

## Current Implementation Status

### Phase: Walking Skeleton (Hello World)

**Goal**: Minimal end-to-end implementation that demonstrates the compile-time compilation pipeline.

---

## Architecture Overview

```
.clj file → CljCompiler.use/1 → Reader → Translator → Elixir AST → Module Functions
```

---

## File Structure and Roles

### 1. `lib/clj_compiler.ex`
**Role**: Main entry point providing the `use` macro

**Responsibilities**:
- Define `__using__/1` macro accepting `dir` option
- Scan directory for all `.clj` files
- Register each file as `@external_resource` for recompilation
- Extract `(ns ...)` declaration from each file
- Convert namespace to Elixir module name
- Generate `defmodule` for each namespace
- Delegate to Reader for parsing
- Delegate to Translator for AST generation
- Inject generated modules into compilation

**Current Implementation**: Full namespace-based compilation - scans directory, extracts namespaces, creates modules dynamically

---

### 2. `lib/clj_compiler/reader.ex`
**Role**: Parse Clojure-like syntax into intermediate AST

**Responsibilities**:
- Tokenize raw `.clj` source text
- Build intermediate AST with tagged tuples:
  - `{:list, [...]}`
  - `{:vector, [...]}`
  - `{:symbol, name}`
  - `{:string, value}`
  - `{:number, value}`
  - `{:keyword, atom}`
- Handle comments (`;` line comments)
- Match parentheses and brackets
- Parse `(ns ...)` declarations
- Report syntax errors with location info

**Current Implementation**: Supports lists, vectors, symbols, strings, numbers, nested structures, and namespace declarations

---

### 3. `lib/clj_compiler/translator.ex`
**Role**: Convert intermediate AST to Elixir AST

**Responsibilities**:
- Walk intermediate AST tree
- Translate `defn` forms to `def` AST
- Translate `let` forms to sequential bindings
- Translate `recur` to recursive calls
- Handle Elixir interop (`Enum/count` → `Enum.count`)
- Validate tail position for `recur`
- Generate idiomatic Elixir code

**Current Implementation**: Handles `defn` with parameters, `let` bindings, `if` conditionals, arithmetic operations, function calls, string concatenation, and Elixir interop

---

### 4. `test/clj_compiler_test.exs`
**Role**: Integration test demonstrating end-to-end functionality

**Responsibilities**:
- Define test module using `CljCompiler`
- Verify generated functions work correctly
- Serve as executable documentation
- Catch regressions

**Current Tests**: 
- Zero-arity function (`hello/0`)
- Function with parameters (`greet/1`)
- Arithmetic operations (`add/2`)
- Conditional expressions (`is_positive/1`)
- Let bindings (`compute/1`)
- Recursive calls (`factorial/1`)
- Elixir interop (`list_length/1`)

---

### 5. `test/fixtures/Elixir.CljCompilerTest.Example.clj`
**Role**: Sample `.clj` source file for testing

**Responsibilities**:
- Demonstrate syntax
- Provide test fixture
- Show working example

**Current Content**: Deprecated - replaced by namespace-based fixtures in `test/fixtures/lib/clj/`

---

### 6. `test/fixtures/lib/clj/*.clj`
**Role**: Namespace-based test fixtures

**Responsibilities**:
- Demonstrate namespace declarations
- Provide multiple module examples
- Show working syntax

**Current Files**:
- `example.clj` with `(ns example.core)`
- `math.clj` with `(ns example.math)`

---

### 7. `mix.exs`
**Role**: Project configuration

**Responsibilities**:
- Define project metadata
- Specify dependencies
- Configure compilation

---

### 8. `README.md`
**Role**: User documentation

**Responsibilities**:
- Installation instructions
- Usage examples
- Running tests
- Project overview

---

## Walking Skeleton Scope

### Implemented
- [x] Project structure
- [x] `use CljCompiler, dir: "path"` macro
- [x] Directory scanning for `.clj` files
- [x] Namespace declaration parsing `(ns ...)`
- [x] Namespace to module name conversion
- [x] Dynamic module generation
- [x] External resource tracking
- [x] Reader (lists, vectors, symbols, strings, numbers)
- [x] Translator (defn, let, if, function calls)
- [x] Integration tests
- [x] Function parameters
- [x] Function body expressions
- [x] `let` bindings
- [x] Arithmetic operations (+, -, *, <, >)
- [x] Elixir interop calls (Module/function syntax)
- [x] Vectors
- [x] Numbers
- [x] String concatenation (str)
- [x] Conditional expressions (if)
- [x] Recursive function calls

### Not Yet Implemented
- [ ] `recur` as special tail-call form
- [ ] Multiple function arities
- [ ] Keywords
- [ ] Maps
- [ ] Error handling with line numbers
- [ ] Reader macros
- [ ] Destructuring in let

---

## Next Steps

1. Add true `recur` tail-call optimization
2. Add support for multiple function arities
3. Add keywords as atoms
4. Add map literals
5. Add destructuring in let bindings
6. Add error reporting with line numbers
7. Add more comprehensive operator support

---

## Change Log

**Initial Commit**: Walking skeleton with hello world function
- Created basic project structure
- Implemented minimal reader and translator
- Single test passes: `hello/0` returns `"Hello World"`

**Extended Implementation**: Core language features
- Added function parameters and argument passing
- Implemented string concatenation via `str` function
- Added arithmetic operations (+, -, *, <, >)
- Implemented `if` conditional expressions
- Added number parsing in reader
- Implemented `let` bindings with sequential evaluation
- Fixed vector parsing to handle nested lists
- Added Elixir module interop (Module/function syntax)
- All 7 integration tests passing

**Namespace Architecture**: Directory-based compilation
- Changed from per-module `.clj` files to directory scanning
- Added `(ns ...)` declaration support
- Implemented namespace to module name conversion
- Modules now generated dynamically from namespace declarations
- Single `use CljCompiler, dir: "path"` compiles all files in directory
- All 5 tests passing with new architecture
