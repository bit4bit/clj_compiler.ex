# Change: Refactorizar Reader a Parser Combinators con NimbleParsec

## Por qué

El módulo actual `Reader` (`lib/clj_compiler/reader.ex`) tiene ~811 líneas con problemas arquitectónicos severos:

1. **Duplicación de código**: Tres funciones (`parse_list`, `parse_vector`, `parse_map`) con ~19 cláusulas idénticas cada una
2. **Tokenizer monolítico**: `tokenize_impl` tiene 25+ cláusulas de pattern matching, difíciles de mantener y testear
3. **Acoplamiento**: El tokenizer inyecta tokens de control como `{:skip, line, col}`, mezclando concerns
4. **Testabilidad**: No es posible hacer unit testing de componentes individuales

NimbleParsec es una librería ligera (sin runtime dependencies) que permite crear parsers composables y testearlos de forma aislada.

## Qué cambia

- **Nuevo módulo `Lexer`** con parsers primitivos (strings, numbers, symbols, delimiters)
- **Nuevo módulo `Parser`** que combina parsers para formar estructuras anidadas
- **Eliminación de `Reader.tokenize_impl`** (~25 cláusulas) por parsers NimbleParsec
- **Eliminación de duplicación** en `parse_list`, `parse_vector`, `parse_map`
- **Mantenimiento de API**: `Reader.parse/2` mantiene misma firma y comportamiento

## Impacto

- **Specs afectadas**: `clj-syntax` (nuevos requisitos para parser combinators)
- **Archivos afectados**: `lib/clj_compiler/reader.ex` → refactorizado
- **Nuevos archivos**: `lib/clj_compiler/lexer.ex`, `lib/clj_compiler/parser.ex`
- **Dependencia nueva**: `{:nimble_parsec, "~> 1.4"}` en `mix.exs`
- **Breaking changes**: Ninguno (API compatible hacia atrás)
- **Tests**: Los tests existentes deben pasar sin modificaciones