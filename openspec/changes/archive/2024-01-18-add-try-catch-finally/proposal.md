# Change: Add try/catch/finally like Clojure

## Why
Clojure provides try/catch/finally for exception handling, but the current CljCompiler lacks this essential control flow construct. Users need proper exception handling in their Clojure-like code to write robust applications.

## What Changes
- **ADDED**: try/catch/finally syntax support in Clojure reader
- **ADDED**: try/catch/finally translation to Elixir's try/rescue/after
- **MODIFIED**: Translator to handle new try/catch/finally forms
- **ADDED**: Tests for try/catch/finally functionality

## Impact
- Affected specs: `clj-syntax`, `clj-translation`
- Affected code: `lib/clj_compiler/reader.ex`, `lib/clj_compiler/translator.ex`, test files
- No breaking changes - adds new functionality