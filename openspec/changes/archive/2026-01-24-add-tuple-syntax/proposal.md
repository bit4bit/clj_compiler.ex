# Change: Add Tuple Syntax Support

## Why
Elixir has tuple data type (`{:a, :b}`) that is commonly used for lightweight data structures and function returns. Currently, the Clojure-like syntax only supports lists, vectors, and maps. Adding tuple syntax enables users to write Clojure code that translates to Elixir tuples.

## What Changes
- Add `#[...]` reader macro syntax for tuples
- Support nested forms inside tuple syntax (vectors, maps, lists, other tuples)
- Translate tuple elements to Elixir tuple format `{:elem1, :elem2, ...}`
- Add lexer tokens for tuple delimiter recognition
- Add parser support for tuple form parsing
- Add translator support for tuple element translation

## Impact
- Affected specs: `clj-syntax`
- Affected code: `lib/clj_compiler/lexer.ex`, `lib/clj_compiler/parser.ex`, `lib/clj_compiler/translator.ex`
- New syntax: `#[:a :b]` → `{:a, :b}`, `#[{:a 1} [1 2]]` → `{%{a: 1}, [1, 2]}`
