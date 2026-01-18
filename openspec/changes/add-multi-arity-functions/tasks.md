# Tasks: Add Multi-Arity Function Support

## 1. Parser Updates
- [ ] 1.1 Detect multi-arity `defn` pattern: `(defn name ([params] body) ([params] body) ...)`
- [ ] 1.2 Detect multi-arity `fn` pattern: `(fn ([params] body) ([params] body) ...)`
- [ ] 1.3 Add validation: all `fn` clauses must have the same arity
- [ ] 1.4 Add validation: `defn` arities must be unique
- [ ] 1.5 Add error messages for invalid multi-arity definitions

## 2. Translator Updates for defn
- [ ] 2.1 Generate Elixir `def` clauses for each arity
- [ ] 2.2 Translate each body expression using existing logic
- [ ] 2.3 Preserve line metadata for each clause
- [ ] 2.4 Handle optional docstring before arity clauses

## 3. Translator Updates for fn
- [ ] 3.1 Generate Elixir anonymous function with multiple clauses
- [ ] 3.2 Validate all clauses have same arity before translation
- [ ] 3.3 Translate each body expression correctly
- [ ] 3.4 Support guard clauses in fn (Elixir native feature)

## 4. Testing
- [ ] 4.1 Add test for multi-arity `defn` with 2 arities
- [ ] 4.2 Add test for multi-arity `defn` with 3+ arities
- [ ] 4.3 Add test for 0-arity `defn` function
- [ ] 4.4 Add test for multi-arity `fn` with same arity
- [ ] 4.5 Add test for multi-arity `fn` with guards
- [ ] 4.6 Add test for `fn` error when arities differ
- [ ] 4.7 Add test for calling multi-arity functions with different arguments
- [ ] 4.8 Add test for multi-arity fn passed to higher-order functions
- [ ] 4.9 Verify existing single-arity tests still pass
- [ ] 4.10 Add integration tests with .clj file compilation

## 5. Documentation
- [ ] 5.1 Update README with multi-arity examples
- [ ] 5.2 Document `defn` multi-arity syntax
- [ ] 5.3 Document `fn` multi-arity limitations (same arity only)

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

### fn Multi-Arity (Same Arity Required)
```clojure
(fn ([x] (* x 2)) ([x] (+ x 1)))  ;; Error: different arities not allowed
```
```clojure
(fn ([x] (* x 2)) ([x] (+ x 1)))  ;; This is WRONG - same arity only
```
```clojure
(fn ([x] (* x 2)) ([x] (+ x 1)))  ;; Valid: same arity (1 param), different bodies
```
↓ translates to ↓
```elixir
fn
  x -> x * 2
  x -> x + 1
end
```

### fn with Guards (Same Arity)
```clojure
(fn ([x] (if (< x 0) (- x) x)) ([x y] (+ x y)))  ;; Error: different arities
```
```clojure
(fn ([x] (if (< x 0) (- x) x)) ([x y] (+ x y)))  ;; This is WRONG
```
```clojure
(fn ([x] (when (< x 0) (- x)) ([x] (when >= x 0) x))  ;; Same arity with guards
```
↓ translates to ↓
```elixir
fn
  x when x < 0 -> -x
  x when x >= 0 -> x
end
```
