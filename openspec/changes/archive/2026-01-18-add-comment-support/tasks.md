## 1. Implementation
- [x] 1.1 Update `remove_comments/1` to handle comments within strings correctly
- [x] 1.2 Add support for `#_` reader macro to skip next form
- [x] 1.3 Add `comment` special form translation that returns nil
- [x] 1.4 Update tokenization to preserve line numbers for error reporting
- [x] 1.5 Add tests for all comment scenarios
- [x] 1.6 Verify existing tests pass

## 2. Validation
- [x] 2.1 Run `openspec validate add-comment-support --strict`
- [x] 2.2 Run test suite to ensure no regressions
