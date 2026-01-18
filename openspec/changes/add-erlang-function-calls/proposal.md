# Change: Add Erlang Module and Function Call Support

## Why
Currently, the Clojure compiler cannot call Erlang functions from any Erlang module like `:erlang`, `:ets`, `:lists`, or `:timer`. When users attempt to call Erlang functions using the Clojure-like keyword syntax (`:module/function`), the compiler fails with "undefined variable" errors because:

1. The lexer tokenizes `:module` as a keyword and `/function` as a separate symbol
2. The translator doesn't handle keyword-module calls
3. There's no validation or translation path for Erlang module function calls

Users need access to Erlang's powerful built-in functions for:
- `:erlang` module - unique integers, process management, system info, time functions
- `:ets` module - Erlang Term Storage operations
- `:lists` module - list operations
- `:timer` module - timing and scheduling
- Any other Erlang module

## What Changes
- **ADDED** support for calling **any Erlang module** via `:module/function` syntax
- **ADDED** translator logic to handle keyword-module function calls
- **ADDED** validation that recognizes keyword-module patterns (`:Module/function`) as valid Erlang calls
- **ADDED** tests for `:erlang/unique_integer` and `:erlang/unique_integer [:positive]`
- **ADDED** tests for other Erlang modules like `:lists`, `:ets`, `:timer`

## Impact
- Affected specs: `specs/clj-translation/spec.md`
- Affected code:
  - `lib/clj_compiler/translator.ex` - Add keyword-module function call handling
  - `test/clj_compiler_test.exs` - Add Erlang function call tests
  - `test/fixtures/lib/clj/erlang.clj` - Add fixture for Erlang function tests
  - `test/fixtures/lib/clj/erlang-modules.clj` - Add fixture for various Erlang modules (ets, lists, timer, etc.)