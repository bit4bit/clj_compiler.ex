# LLM-Assisted

# Walking Skeleton Design Document

## Current Implementation Status

### Phase: Walking Skeleton (Hello World)

**Goal**: Minimal end-to-end implementation that demonstrates the compile-time compilation pipeline.

---

## Architecture Overview

```
Directory of .clj files → CljCompiler.use/1 → Reader → Namespace Extraction → Translator → Elixir AST → Nested Modules
```

---

## File Structure and Roles

### 1. `lib/clj_compiler.ex`
**Role**: Main entry point providing the `use` macro

**Responsibilities**:
- Define `__using__/1` macro accepting `dir` option (string or list of strings)
- Capture parent module name from calling context
- Scan directory(ies) for all `.clj` files
- Register each file as `@external_resource` for recompilation
- Extract `(ns ...)` declaration from each file
- Convert namespace to Elixir module name prefixed with parent module
- Generate `defmodule` for each namespace nested under parent
- Delegate to Reader for parsing
- Delegate to Translator for AST generation
- Inject generated modules into compilation

**Example**:
```elixir
defmodule MyApp do
  use CljCompiler, dir: "src"
end

# Or multiple directories
defmodule MyApp do
  use CljCompiler, dir: ["src", "lib/clj", "vendor/clj"]
end
```
With `(ns example.core)` creates `MyApp.Example.Core`

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
  - `{:map, [...]}`
- Handle comments (`;` line comments)
- Match parentheses and brackets
- Parse `(ns ...)` declarations
- Track line and column numbers during parsing
- Report syntax errors with precise location info
- Provide descriptive error messages
- Parse map literals `{:key value}`

**Current Implementation**: Supports lists, vectors, maps, symbols, strings, numbers, keywords, booleans, nested structures, namespace declarations, parent module function calls, and detailed error reporting with line/column information

---

### 3. `lib/clj_compiler/translator.ex`
**Role**: Convert intermediate AST to Elixir AST

**Responsibilities**:
- Walk intermediate AST tree
- Translate `defn` forms to `def` AST
- Translate `let` forms to sequential bindings
- Translate `recur` to recursive calls
- Handle Elixir interop (`Enum/count` → `Enum.count`)
- Handle parent module function calls (qualify unknown functions)
- Distinguish built-in operators from function calls
- Fallback to Kernel functions when not in parent module
- Translate map literals to Elixir map syntax
- Translate keywords to atoms
- Translate boolean literals (true/false)
- Validate tail position for `recur`
- Generate idiomatic Elixir code

**Current Implementation**: Handles `defn` with parameters, `let` bindings, `if` conditionals, arithmetic operations, function calls, string concatenation, maps, keywords, booleans, Elixir interop, parent module function calls, and Kernel function fallback

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
- [x] `use CljCompiler, dir: "path"` macro (supports single or multiple directories)
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
- [x] Parent module function access from Clojure code
- [x] Built-in operator detection
- [x] Kernel function fallback
- [x] Multiple directories support
- [x] Error reporting with line and column numbers
- [x] Descriptive parse errors (unclosed parenthesis, unclosed bracket)
- [x] Map literals with keyword keys
- [x] Keywords as atoms
- [x] Boolean literals (true/false)
- [x] conj function (prepend behavior)
- [x] Keyword-as-function for map access
- [x] get function for map access
- [x] assoc function for map updates
- [x] dissoc function for map key removal (vector syntax)
- [x] :use namespace declaration for Elixir module injection (with atom and keyword list options)

### Not Yet Implemented
- [ ] `recur` as special tail-call form
- [ ] Multiple function arities
- [ ] Reader macros
- [ ] Destructuring in let
- [ ] More comprehensive error messages for translation errors
- [ ] Map destructuring

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

**Compile-Time Undefined Function Validation**: Added validation to detect undefined function calls at compile time
- Extract local function names from `defn` forms
- Extract namespace uses from `ns` declarations
- Validate function calls against local functions, parameters, attributes, built-in operators, special forms, Elixir interop, and CljCompiler.Compat functions
- Provide detailed error messages with available options and suggestions
- Added 10 new tests covering error cases and pass cases
- All 59 tests passing (49 existing + 10 new)
- Implemented namespace to module name conversion
- Modules now generated dynamically from namespace declarations
- Single `use CljCompiler, dir: "path"` compiles all files in directory
- All 5 tests passing with new architecture

**Parent Module Nesting**: Namespace modules nested under calling module
- Generated modules prefixed with parent module name
- `ClojureProject` with `(ns example.math)` creates `ClojureProject.Example.Math`
- Allows multiple projects with same namespaces without conflicts
- All 5 tests passing with nested module structure

**Parent Module Function Access**: Clojure code can call parent module functions
- Unknown function calls (not operators, not local functions) are qualified with parent module
- Example: `(do_sum a b)` in Clojure calls `ClojureProject.do_sum(a, b)`
- Built-in operators (+, -, *, <, >, etc.) remain unqualified
- Local recursive calls remain unqualified
- Enables sharing Elixir functions with Clojure code
- All 7 tests passing with parent function calls

**Automatic Runtime Fallback**: Dynamic resolution of parent vs Kernel functions
- Removed hardcoded list of Kernel functions
- Created `CljCompiler.Runtime.call_with_fallback/3` helper
- Uses `function_exported?/3` at runtime to check parent module first
- Falls back to Kernel automatically if not in parent module
- No need to maintain list of Kernel functions
- All functions automatically available from Kernel
- All 8 tests passing with automatic fallback

**Multiple Directories Support**: Compile from multiple source directories
- `dir` option accepts string or list of strings
- Example: `dir: ["src", "lib/clj", "vendor/clj"]`
- All directories scanned for `.clj` files
- Files from all directories compiled into same parent module
- Enables organizing code across multiple directories
- All 10 tests passing with multiple directories

**Improved Error Reporting**: Line and column tracking with descriptive messages
- Reader now tracks line and column numbers during tokenization
- Created `CljCompiler.Reader.ParseError` exception with file, line, column info
- Detects unclosed parentheses and brackets with exact location
- Detects missing namespace declarations
- Error messages include file path, line number, column number, and description
- All 11 tests passing with improved error handling

**Map Literals Support**: Full map syntax with keywords and booleans
- Added tokenization for braces `{` and `}`
- Created `parse_map` function to handle map literals
- Translate map literals to Elixir `%{key: value}` syntax
- Keywords parsed as atoms (`:name` → `name`)
- Boolean literals (true/false) translated correctly
- Support for nested maps, vectors, and lists inside maps
- Detect unclosed braces with line/column information
- Add test fixtures with map usage
- All 15 tests passing with map support

**conj Function**: Collection conjunction with prepend behavior
- Added `CljCompiler.Runtime.conj/2` function
- Implements prepend operation `[item | collection]` for O(1) efficiency
- Handled as special case in translator
- Matches Clojure list behavior (not vector behavior)
- Both lists and vectors use prepend since no runtime distinction exists
- Added test fixtures in `collections.clj`
- All 18 tests passing with conj support

**Keyword-as-Function**: Map access using keywords as functions
- Keywords in function position translate to map access
- Syntax: `(:key map)` translates to `Map.get(map, :key)`
- Matches Clojure idiom for map lookups
- Added tests for passing and processing maps as function arguments
- Functions can receive maps and extract values using keyword access
- All 21 tests passing with keyword-as-function support

**Map Access Functions**: get, assoc, and dissoc for map manipulation
- Added `CljCompiler.Runtime.get/2` and `get/3` for map value retrieval
- `get/2` retrieves value for key, `get/3` provides default value
- Added `CljCompiler.Runtime.assoc/3` for adding/updating map keys
- Translates to `Map.put/3` in Elixir
- Added `CljCompiler.Runtime.dissoc/2` for removing keys from map
- Requires vector syntax: `(dissoc m [:a :b :c])`
- Uses `Enum.reduce` with `Map.delete/2` for multiple keys
- No special handling needed in translator
- Added tests for get with/without default, assoc add/update, dissoc single/multiple
- All 27 tests passing with map access functions

**Vector syntax for dissoc**: Simplified dissoc to use vector syntax
- Refactored dissoc to accept list of keys as second argument
- DSL syntax requires vector: `(dissoc m [:a :b :c])`
- `dissoc/2` accepts map and list of keys
- Use `Enum.reduce` with `Map.delete/2` for multiple keys
- Added test for dissoc with 5 keys
- All 28 tests passing with vector syntax dissoc

**Translator Refactoring**: Decoupled translator from runtime function knowledge
- Added `runtime_functions/0` in Runtime module listing all runtime functions
- Translator uses `@runtime_functions` module attribute from Runtime
- Removed hardcoded runtime function checks from translator
- Created `translate_runtime_call/2` helper for runtime function translation
- Translator no longer needs updates when adding new runtime functions
- All 28 tests passing with refactored translator

**Enhanced Delimiter Error Reporting**: Precise error messages for mismatched delimiters
- Refactored reader to use stack-based parsing with delimiter tracking
- Enhanced error messages with opening delimiter references and positions
- Detects missing, mismatched, and extra delimiters with accurate line/column info
- Prioritizes outermost unclosed delimiters for better error reporting
- Added comprehensive test coverage for all delimiter error scenarios
- All 49 tests passing with enhanced error handling

**Remove dissoc special case from translator**: Fully decoupled translator
- Changed DSL syntax to require vector for dissoc keys
- Syntax: `(dissoc m [:key1 :key2])` instead of `(dissoc m :key1 :key2)`
- Removed special `translate_runtime_call/2` clause for dissoc
- Translator now handles dissoc like any other runtime function
- Runtime implementation uses single clause with guard `when is_list(keys)`
- Updated all test fixtures to use vector syntax
- Added test for vector syntax
- All 29 tests passing with fully decoupled translator

**Namespace :use Declaration**: Elixir use macro integration in namespace
- Added :use keyword support in namespace declarations
- Syntax: `(ns my.namespace (:use [ModuleName] [AnotherModule {:option value}]))`
- Translates to Elixir `use` statements in generated modules
- Supports modules without options: `(:use [Phoenix.Controller])`
- Supports modules with options: `(:use [Phoenix.View {:layout false}])`
- Multiple :use declarations in single namespace
- Options parsed from maps and converted to keyword lists
- Fixed mix.exs elixirc_paths typo (list -> lib)
- Fixed namespace parsing to handle clauses in ns form
- Created test support modules with __using__ macros
- All 32 tests passing with :use namespace support

**Atom Option Support for :use**: Support atom as second argument
- Added support for atom options in :use declarations
- Syntax: `(:use [PhoenixWeb :controller])` translates to `use PhoenixWeb, :controller`
- Added parse_use_module clause for vector with keyword option
- Created test for atom option usage
- All 33 tests passing with atom option support

**Function Resolution for Imports**: Allow use-imported functions to work
- Changed unknown function calls from call_with_fallback to direct calls
- Unknown functions now called unqualified: `render(args)` not `call_with_fallback(...)`
- Elixir's normal resolution finds imports from use statements first
- Parent module functions must be explicitly qualified: `ParentModule/function`
- Updated test fixtures to qualify parent module calls
- Removed dependency on call_with_fallback for unknown functions
- Enables Phoenix controller functions like render/2 to work correctly
- All 33 tests passing with improved function resolution

**Unknown Symbol Validation**: Compile-time error for unresolved top-level symbols
- Added validation for unknown symbols in top-level forms
- Only `ns` and `defn` allowed at top level
- Unknown symbols like `defa` raise `CompileError` with message "Unable to resolve symbol: defa in this context"
- Added explicit `translate_form` clause for `ns` forms
- Added catch-all clause raising error for unknown top-level symbols
- All 34 tests passing with symbol validation

**def Form for Module Attributes**: Support compile-time constants
- Added `def` form to define module attributes
- Syntax: `(def max-size 100)` translates to `@max_size 100` in Elixir
- Attribute names with hyphens converted to underscores (max-size → max_size)
- Symbols referencing attributes in function bodies translated to module attribute access
- Added `extract_attr_names/1` to track defined attributes
- Pass attr_names through translation pipeline for symbol resolution
- Function names normalized to replace hyphens with underscores
- Added float parsing support in reader (3.14 parsed as number, not symbol)
- Changed `parse_atom/1` to check Float.parse after Integer.parse
- Created test fixture attrs.clj with numeric, string, and float attributes
- All 39 tests passing with def and float support

**Location Metadata for Warnings**: Improved compiler warnings with .clj file locations
- Added file parameter to `translate/3` function
- Pass file path through translation pipeline
- Add location metadata `[file: charlist, line: 1]` to generated function AST
- Parameters now include file/line metadata for better compiler warnings
- Track param_names through translation to properly reference parameters
- Unused variable warnings eliminated by proper parameter handling
- Generated functions now show .clj file in compilation messages
- Fixed clause ordering warning by grouping translate_form functions
- Added test verifying location metadata includes .clj file path in AST
- CompileError now includes file and actual line number from source for unknown symbols
- Reader now attaches line metadata to list forms: `{:list, elements, line}`
- Translator extracts and uses actual line numbers from forms
- Updated pattern matching to handle both old and new list formats
- Added test assertions verifying error.file and error.line in CompileError
- Test verifies error.line == 3 for error on line 3 of source
- All 40 tests passing with actual line number tracking

**Compat Module with Import Support**: Allow unqualified runtime function access via use
- Renamed `CljCompiler.Runtime` to `CljCompiler.Compat` with `__using__/1` that imports the module
- Removed special runtime function handling from `translator.ex` (@runtime_functions and translate_runtime_call)
- Runtime functions now available unqualified in clj code via `(:use [CljCompiler.Compat])`
- Simplifies translator by relying on standard Elixir import resolution
- Updated all existing test fixtures to include Compat use
- Added test fixture and test for unqualified runtime function access
- All tests passing with improved module organization

**Removed Unused function_names Variable**: Simplified translator by removing unnecessary code
- Removed extraction and passing of function_names variable in translator.ex
- Variable was not used in function call resolution logic
- Removed MapSet.member? check for function_names in translate_expr
- All function calls now fall through to unqualified calls
- No change in behavior or generated code
- All 41 tests passing with simplified translator

**Fixed Delimiter Validation**: Consolidated duplicate function clauses
- Delimiter validation feature had duplicate function clause groups for parse_list/4 and parse_map/4
- In Elixir, separated clause groups override each other instead of merging
- Removed duplicate parse_list/4 clauses that were being overridden (lines 225-277)
- Removed duplicate parse_map/4 clauses that were being overridden (lines 279-335)
- Removed unused _get_token_position/1 function to eliminate compiler warning
- Fixed test expectations for column numbers to match actual tokenization
- Fixed test expectations to report outermost unclosed delimiter as intended
- Delimiter validation now works correctly for nested structures like maps within lists
- All 49 tests passing with no compiler warnings






