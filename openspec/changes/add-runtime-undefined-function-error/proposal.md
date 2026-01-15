# Change: Add runtime UndefinedFunctionError for undefined function calls

## Why
Currently, CljCompiler validates function calls at compile time and raises `CompileError` for undefined functions. However, this prevents legitimate runtime scenarios where functions might be dynamically available or where the user wants to handle missing functions at runtime. The user wants calls to undefined functions at runtime to raise Elixir's standard `UndefinedFunctionError` instead.

## What Changes
- **ADDED**: Runtime fallback mechanism that raises `UndefinedFunctionError` for functions that pass compile-time validation but don't exist at runtime
- **MODIFIED**: Generated code will include runtime existence checks for functions that cannot be fully validated at compile time
- **NOT CHANGED**: Compile-time undefined function validation remains active
- **NOT BREAKING**: Maintains existing compile-time error behavior, adds runtime safety

## Impact
- Affected specs: `function-resolution` capability
- Affected code: `CljCompiler.Translator.translate_expr/7`, function call generation
- Testing: Need to add tests for runtime `UndefinedFunctionError` scenarios
- Error handling: Users get both compile-time validation AND runtime safety for edge cases