# Clojure-like Compile-Time DSL for Elixir (Design Doc)

## 1. Objective

Build an Elixir library that allows writing Elixir modules using a **Clojure-flavored Lisp syntax**, compiled **entirely at Elixir compile time** using macros.

For each Elixir module:

```elixir
defmodule MyModule do
  use CljCompiler
end
```

The compiler will:

* Read `MyModule.clj` at compile time
* Parse a minimal Clojure-like syntax
* Translate it into **idiomatic Elixir AST**
* Inject function definitions into the module

This is **not Clojure compatibility**, only **Clojure-like syntax**.

---

## 2. Supported Language Subset

### 2.1 Forms

Only the following core forms are supported:

| Form    | Purpose             |
| ------- | ------------------- |
| `defn`  | Function definition |
| `let`   | Lexical bindings    |
| `recur` | Tail recursion      |

No macro system exists in the DSL itself.

---

### 2.2 Syntax Rules

* Lisp-style S-expressions
* Whitespace-separated tokens
* Parentheses for lists
* No reader macros
* No metadata
* Only line comments using `;`

Example:

```clojure
(defn sum [lst acc]
  (if (empty? lst)
    acc
    (recur (rest lst) (+ acc (first lst)))))
```

---

## 3. Compile-Time Architecture

### 3.1 Compilation Pipeline

At `use CljCompiler` expansion time:

1. **Resolve source file**

   * Compute `MyModule.clj`
   * Mark as `@external_resource` for recompilation

2. **Read file**

   * Load raw text at compile time

3. **Parse**

   * Custom Clojure-like reader written in Elixir
   * Output: Lisp AST (lists, vectors, symbols, literals)

4. **Normalize**

   * Validate supported forms
   * Reject unknown forms early

5. **Translate**

   * Convert Lisp AST → Elixir AST
   * Produce idiomatic constructs (pattern matching, recursion)

6. **Inject**

   * Return quoted AST defining functions in the module

---

## 4. Reader (Parser) Design

### 4.1 Output AST (Intermediate Representation)

The reader produces a simple tagged AST:

```elixir
{:list, [...]}
{:vector, [...]}
{:symbol, "defn"}
{:number, 42}
{:string, "abc"}
{:keyword, :foo}
```

### 4.2 Responsibilities

* Tokenization
* Parenthesis matching
* Vector parsing (`[...]`)
* Comment stripping (`; ...`)
* Symbol resolution deferred to translation phase

No semantic interpretation happens here.

---

## 5. Translation Rules (Lisp AST → Elixir AST)

### 5.1 `defn`

```clojure
(defn foo [a b] body...)
```

Translates to:

```elixir
def foo(a, b) do
  ...
end
```

Rules:

* One function per `defn`
* Multiple arities allowed via multiple `defn` with same name
* Always public functions

---

### 5.2 `let`

```clojure
(let [a 1 b 2]
  expr)
```

Translates to:

```elixir
a = 1
b = 2
expr
```

Rules:

* Implemented via nested blocks
* No destructuring (initially)
* Bindings evaluated sequentially

---

### 5.3 `recur`

```clojure
(recur x y)
```

Rules:

* Only valid in tail position
* Translates to:

  * Either a recursive function call
  * Or a `case`-based loop if optimized
* Compiler must statically ensure tail position

---

## 6. Function Calls & Interop

### 6.1 Elixir Interop

Forms like:

```clojure
(Enum/count lst)
```

Translate directly to:

```elixir
Enum.count(lst)
```

Rules:

* Symbols containing `/` or `.` are treated as Elixir module calls
* No name resolution inside the DSL
* Elixir compiler handles errors

---

### 6.2 Data Structure Mapping

| Clojure | Elixir                    |
| ------- | ------------------------- |
| list    | list                      |
| vector  | list                      |
| map     | map                       |
| keyword | atom                      |
| symbol  | variable or function name |

---

## 7. Error Handling

All errors are **compile-time errors**.

### 7.1 Error Types

* Syntax errors (reader)
* Unsupported form errors
* Arity mismatch
* Invalid `recur` placement

### 7.2 Diagnostics

Errors must:

* Include `.clj` filename
* Include line and column if available
* Fail compilation immediately

---

## 8. Recompilation Strategy

* Each `.clj` file is declared using `@external_resource`
* Any file change triggers recompilation automatically

---

## 9. Generated Code Constraints

* Only Elixir AST is emitted
* No `.ex` files generated
* AST should be idiomatic:

  * Prefer pattern matching
  * Avoid deeply nested anonymous functions
  * Use recursion naturally

---

## 10. Non-Goals (Explicit)

* Full Clojure compatibility
* Macros inside `.clj`
* Runtime evaluation
* JVM semantics
* Advanced reader features

---

## 11. Implementation Guidance for LLM

When implementing:

1. Keep reader **dumb and deterministic**
2. Perform **all semantic checks during translation**
3. Fail fast with clear compile-time errors
4. Prefer clarity over clever optimizations
5. Treat `.clj` as a **syntax layer**, not a language
