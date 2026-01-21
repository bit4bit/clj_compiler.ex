# Tasks: Add Multi-Arity Function Support
# Tasks: Add Multi-Arity Function Support (defn only)

## 1. Parser Updates
- [x] 1.1 Detect multi-arity `defn` pattern: `(defn name ([params] body) ([params] body) ...)`
- [x] 1.2 Add validation: `defn` arities must be unique
- [x] 1.3 Add error messages for invalid multi-arity definitions

## 2. Translator Updates for defn
- [x] 2.1 Generate Elixir `def` clauses for each arity
- [x] 2.2 Translate each body expression using existing logic
- [x] 2.3 Preserve line metadata for each clause
- [x] 2.4 Handle optional docstring before arity clauses

## 3. Testing
- [x] 3.1 Add test for multi-arity `defn` with 2 arities
- [x] 3.2 Add test for multi-arity `defn` with 3+ arities
- [x] 3.3 Add test for 0-arity `defn` function
- [x] 3.4 Add test for calling multi-arity functions with different arguments
- [x] 3.5 Add test for multi-arity defn with docstring
- [x] 3.6 Verify existing single-arity tests still pass
- [x] 3.7 Add integration tests with .clj file compilation

## 4. Documentation
- [ ] 4.1 Update README with multi-arity examples
- [ ] 4.2 Document `defn` multi-arity syntax

## Implementation Examples

### defn Multi-Arity
```clojure
(defn concat ([] "") ([a] (str "hola " a)))
```
↓ translates to ↓
```elixir
def concat(), do: ""
def concat(a), do: "hola " <> a
```

### Single-Arity fn (unchanged)
```clojure
(fn [x] (* x 2))
```
↓ translates to ↓
```elixir
fn x -> x * 2 end
```

## Summary
All implementation tasks completed. The compiler now supports multi-arity `defn` syntax:
- `(defn name ([params] body) ([params] body) ...)` generates multiple Elixir `def` clauses
- Docstrings are preserved as `@doc` module attributes
- Duplicate arities are detected and raise an error
- Legacy single-arity `defn` syntax continues to work
- All 124 tests pass