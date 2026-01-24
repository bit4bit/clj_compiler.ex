# Change: Add support for multiple :use declarations in ns forms

## Why
Users want to import multiple namespaces using separate `:use` declarations, similar to how Clojure allows multiple `:use` clauses in the `ns` form. Currently, the compiler only supports a single `:use` declaration, which forces users to combine multiple imports into one clause like `(:use [A B C])` instead of allowing `(:use [A] :use [B])`.

## What Changes
- The `extract_use_clauses/1` function in `lib/clj_compiler.ex` will be modified to collect modules from all `:use` declarations, not just the first one.
- The `ns` form parser will accept multiple `:use` keyword clauses.
- Documentation will be updated to reflect the new syntax.

## Impact
- Affected specs: `specs/clj-syntax/spec.md`
- Affected code: `lib/clj_compiler.ex` (extract_use_clauses function)
- Backward compatible: Yes, existing single `:use` declarations continue to work
