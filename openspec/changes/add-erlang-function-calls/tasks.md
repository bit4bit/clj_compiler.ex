# Implementation Tasks: Add Erlang Module and Function Call Support

## 1. Translator Updates
- [ ] 1.1 Add handler for keyword-module function calls in `translate_expr/7`
- [ ] 1.2 Update `validate_function_call!/8` to allow keyword-module pattern calls (`:Module/function`)
- [ ] 1.3 Handle `:module/function` syntax generically for any Erlang module
- [ ] 1.4 Support vector arguments (e.g., `[:positive]`) in Erlang function calls
- [ ] 1.5 Generate correct Elixir AST for `Module.function(args)` calls

## 2. Lexer Evaluation
- [ ] 2.1 Verify current lexer behavior with `:erlang/unique_integer` syntax
- [ ] 2.2 Confirm lexer produces `{:keyword, :erlang}` and `{:symbol, "/unique_integer"}`
- [ ] 2.3 No lexer changes needed - translator will handle keyword-symbol combination

## 3. Test Coverage - :erlang Module
- [ ] 3.1 Add tests for `:erlang/unique_integer` (no arguments)
- [ ] 3.2 Add tests for `:erlang/unique_integer [:positive]`
- [ ] 3.3 Add tests for multiple unique_integer calls to verify uniqueness
- [ ] 3.4 Add tests for unique_integer used in expressions
- [ ] 3.5 Add tests for `:erlang/spawn`, `:erlang/send` (process management)

## 4. Test Coverage - Other Erlang Modules
- [ ] 4.1 Add tests for `:lists/append`, `:lists/map`, `:lists/filter`
- [ ] 4.2 Add tests for `:maps/get`, `:maps/put`, `:maps/merge`
- [ ] 4.3 Add tests for `:string/trim`, `:string/len`
- [ ] 4.4 Add tests for `:timer/sleep`, `:timer/tc`

## 5. Fixture Updates
- [ ] 5.1 Create `test/fixtures/lib/clj/erlang.clj` for :erlang module tests
- [ ] 5.2 Create `test/fixtures/lib/clj/erlang-modules.clj` for other modules (lists, maps, string, timer)
- [ ] 5.3 Ensure fixtures have proper namespace declarations with `:use [CljCompiler.Compat]`

## 6. Integration Testing
- [ ] 6.1 Run full test suite to ensure no regressions
- [ ] 6.2 Test keyword-module calls in nested contexts (let, if, function bodies)
- [ ] 6.3 Test Erlang function calls with multiple arguments
- [ ] 6.4 Test Erlang function calls returning different types (integers, lists, maps, pids)

## 7. Error Handling
- [ ] 7.1 Verify error messages for invalid Erlang module calls
- [ ] 7.2 Test handling of non-existent functions in valid Erlang modules
- [ ] 7.3 Test handling of completely invalid module names

## 8. Documentation
- [ ] 8.1 Add documentation for Erlang module call syntax in README
- [ ] 8.2 Document that `:module/function` works with any Erlang module
- [ ] 8.3 Provide examples for :erlang, :lists, :maps, :timer, :string modules