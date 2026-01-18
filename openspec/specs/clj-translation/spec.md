# clj-translation

## Exception Handling Translation
The system translates Clojure try/catch/finally forms to equivalent Elixir try/rescue/after constructs.

### Basic try/catch translation
- **WHEN** translating `(try (throw "error") (catch RuntimeError e "caught"))`
- **THEN** it should produce Elixir AST equivalent to `try do raise "error" rescue e in RuntimeError -> "caught" end`

### Multiple catch blocks translation
- **WHEN** translating `(try expr (catch RuntimeError e "runtime") (catch ArgumentError e "general"))`
- **THEN** it should produce Elixir AST with multiple rescue clauses

### Finally block translation
- **WHEN** translating `(try expr (finally "cleanup"))`
- **THEN** it should produce Elixir AST with after clause

### Complete try/catch/finally translation
- **WHEN** translating `(try expr (catch RuntimeError e "handle") (finally "cleanup"))`
- **THEN** it should produce Elixir AST with both rescue and after clauses

### Exception variable binding
- **WHEN** translating `(try expr (catch RuntimeError e (str "caught: " e)))`
- **THEN** the exception variable `e` should be bound and available in the catch body

### Function Call Validation
The system validates `throw` as a built-in function when used within try/catch contexts.

- **WHEN** calling `(throw "error")` within a try block
- **THEN** it should be recognized as a valid function call
- **WHEN** calling `(throw "error")` outside try/catch context
- **THEN** it should raise appropriate error if not defined