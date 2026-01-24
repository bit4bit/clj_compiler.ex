# Change: Add nil Literal Support

## Why
The compiler currently supports Clojure boolean literals `true` and `false`, but lacks support for the `nil` literal. This means Clojure code using `nil` cannot be properly translated to Elixir, which uses `nil` for the same purpose (representing null/empty value).

## What Changes
- Add `nil` literal recognition in the translator alongside existing `true`/`false` handling
- Translate `nil` symbol to Elixir `nil` value
- Ensure consistent behavior with Clojure semantics

## Impact
- Affected specs: `clj-translation`
- Affected code: `lib/clj_compiler/translator.ex`
- Backward compatible: adds new capability without breaking existing functionality
