# Change: Add Multi-Arity Function Support

## Why
Currently, the compiler only supports single-arity function definitions where `defn` and `fn` accept exactly one parameter vector. This limits expressiveness compared to Clojure, which supports defining multiple function bodies with different arities. Multi-arity functions are a fundamental Clojure feature used extensively for:
- Providing default arguments (0-arity for defaults, n-arity for actual work)
- Overloading behavior based on argument count
- Optimized fast paths for common cases

For example, the Clojure pattern:
```clojure
(defn concat ([] "") ([a] (str "hola " a)))
```
cannot be expressed in the current compiler.

## What Changes
- **defn multi-arity**: Support `(defn name ([params] body) ([params] body) ...)` syntax
- **fn multi-arity**: Support `(fn ([params] body) ([params] body) ...)` with same arity across all clauses (Elixir compatible)
- **Parser**: Extend the parser to recognize multi-arity function definitions with multiple `[params body]` pairs
- **Translator**: 
  - For `defn`: Generate Elixir multi-clause function definitions
  - For `fn`: Generate Elixir anonymous function with multiple clauses (same arity required)
- **Validation**: Ensure arities are valid and provide clear error messages

## Impact
- **Affected specs**: `clj-syntax`, `clj-translation`
- **Affected code**:
  - `lib/clj_compiler/translator.ex` - New pattern matching for multi-arity forms
  - Tests will need new test cases for multi-arity scenarios
- **Breaking changes**: None - this is purely additive
- **Migration**: None required, existing single-arity functions continue to work

## Limitations
- Anonymous functions (`fn`) must have all clauses with the same arity (matching Elixir's limitation)
- Multi-arity anonymous functions cannot have different arities per clause