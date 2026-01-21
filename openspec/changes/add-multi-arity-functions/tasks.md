# Tasks: Add Multi-Arity Function Support

## 1. Parser Updates
- [ ] 1.1 Detect multi-arity `defn` pattern: `(defn name ([params] body) ([params] body) ...)`
- [ ] 1.2 Add validation: `defn` arities must be unique
- [ ] 1.3 Add error messages for invalid multi-arity definitions

## 2. Translator Updates for defn
- [ ] 2.1 Generate Elixir `def` clauses for each arity
- [ ] 2.2 Translate each body expression using existing logic
- [ ] 2.3 Preserve line metadata for each clause
- [ ] 2.4 Handle optional docstring before arity clauses

## 3. Testing
- [ ] 3.1 Add test for multi-arity `defn` with 2 arities
- [ ] 3.2 Add test for multi-arity `defn` with 3+ arities
- [ ] 3.3 Add test for 0-arity `defn` function
- [ ] 3.4 Add test for calling multi-arity functions with different arguments
- [ ] 3.5 Add test for multi-arity defn with docstring
- [ ] 3.6 Verify existing single-arity tests still pass
- [ ] 3.7 Add integration tests with .clj file compilation

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
