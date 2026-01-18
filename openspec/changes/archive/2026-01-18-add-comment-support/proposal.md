# Change: Add Comment Support for Clojure-like Code

## Why
The current comment handling in the Clojure-like code reader is basic and has limitations. Comments are essential for code documentation and developer readability. The current implementation only handles simple line comments and may incorrectly handle comments within strings. We need robust comment support including line comments, block comments via reader macros, and proper handling of comments within string literals.

## What Changes
- Add support for line comments starting with `;` with proper handling within strings
- Add support for block comments using the `#_` reader macro (skips the next form)
- Add support for `comment` special form for multi-line/multi-form comments
- Improve the lexer to correctly identify comments vs semicolons in strings
- Update error reporting to reference original line numbers correctly

## Impact
- Affected specs: `clj-syntax`
- Affected code: `lib/clj_compiler/reader.ex`
- Breaking changes: None
- Backward compatible: Yes
