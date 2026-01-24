## 1. Implementation
- [x] 1.1 The `extract_use_clauses/1` function already supports multiple `:use` declarations - no changes needed
- [x] 1.2 Added test case for multiple `:use` declarations on separate lines

## 2. Validation
- [x] 2.1 Ran tests - 159 tests pass, including new test for multi-line `:use`
- [x] 2.2 Ran `openspec validate add-multiple-use-declarations --strict` - passes
