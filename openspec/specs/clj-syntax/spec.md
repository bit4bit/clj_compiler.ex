# clj-syntax

## Exception Handling Syntax
The system supports Clojure-style try/catch/finally syntax for exception handling.

### Basic try/catch
- **WHEN** parsing `(try (throw "error") (catch RuntimeError e "caught"))`
- **THEN** it should parse successfully as a try form with catch clause

### Try with multiple catch blocks
- **WHEN** parsing `(try expr (catch RuntimeError e "runtime") (catch ArgumentError e "general"))`
- **THEN** it should parse successfully with multiple catch clauses

### Try with finally
- **WHEN** parsing `(try expr (finally "cleanup"))`
- **THEN** it should parse successfully with finally clause

### Try/catch/finally combination
- **WHEN** parsing `(try expr (catch RuntimeError e "handle") (finally "cleanup"))`
- **THEN** it should parse successfully with both catch and finally clauses

### Nested try blocks
- **WHEN** parsing `(try (try inner (catch RuntimeError e "inner")) (catch RuntimeError e "outer"))`
- **THEN** it should parse successfully with nested try forms