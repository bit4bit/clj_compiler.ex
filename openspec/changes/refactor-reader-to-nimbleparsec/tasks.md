# Tasks: Refactorizar Reader a Parser Combinators

## 1. Preparación

- [ ] 1.1 Añadir `{:nimble_parsec, "~> 1.4"}` a `mix.exs` en `:dev` y `:test`
- [ ] 1.2 Ejecutar `mix deps.get` para verificar instalación
- [ ] 1.3 Verificar tests existentes: `mix test` (debe pasar 100%)

## 2. Módulo Lexer - Parsers Primitivos

- [ ] 2.1 Crear `lib/clj_compiler/lexer.ex` con estructura básica
- [ ] 2.2 Implementar `Lexer.whitespace/0` (espacios, tabs, newlines)
- [ ] 2.3 Implementar `Lexer.string/0` (strings con escape `\"`)
- [ ] 2.4 Implementar `Lexer.number/0` (integers, floats)
- [ ] 2.5 Implementar `Lexer.symbol/0` (identifiers, keywords con `:`)
- [ ] 2.6 Implementar `Lexer.keyword/0` (keywords starting with `:`)
- [ ] 2.7 Implementar `Lexer.delimiter/0` (paréntesis, corchetes, llaves)
- [ ] 2.8 Implementar `Lexer.comment/0` (líneas que empiezan con `;`)
- [ ] 2.9 Implementar `Lexer.discard/0` (`#_` para skip del siguiente form)
- [ ] 2.10 Escribir tests unitarios para cada parser del Lexer
- [ ] 2.11 Verificar output de tokens compatible con parser existente

## 3. Módulo Parser - Parsers Compuestos

- [ ] 3.1 Crear `lib/clj_compiler/parser.ex` con estructura básica
- [ ] 3.2 Implementar `Parser.form/0` (un form individual)
- [ ] 3.3 Implementar `Parser.list/0` (`(...)` → `{:list, forms, line}`)
- [ ] 3.4 Implementar `Parser.vector/0` (`[...]` → `{:vector, forms, line}`)
- [ ] 3.5 Implementar `Parser.map/0` (`{...}` → `{:map, forms, line}`)
- [ ] 3.6 Implementar `Parser.forms/0` (múltiples forms en secuencia)
- [ ] 3.7 Manejar correctamente `:skip` tokens de `#_` discard
- [ ] 3.8 Escribir tests unitarios para cada parser del Parser

## 4. Integración con Reader

- [ ] 4.1 Crear `Reader.Lexer` wrapper que usa el nuevo Lexer
- [ ] 4.2 Crear `Reader.Parser` wrapper que usa el nuevo Parser
- [ ] 4.3 Refactorizar `Reader.parse/2` para usar wrappers nuevos
- [ ] 4.4 Mantener compatibilidad de API (`parse(source, file)`)
- [ ] 4.5 Mantener formato de `ParseError` (línea, columna, archivo)
- [ ] 4.6 Verificar que todos los tests existentes pasen
- [ ] 4.7 Comparar output del nuevo Reader vs anterior con casos de prueba

## 5. Limpieza de Código Legacy

- [ ] 5.1 Eliminar función `tokenize_impl` antigua (~25 cláusulas)
- [ ] 5.2 Eliminar función `parse_list` duplicada (~19 cláusulas)
- [ ] 5.3 Eliminar función `parse_vector` duplicada (~19 cláusulas)
- [ ] 5.4 Eliminar función `parse_map` duplicada (~19 cláusulas)
- [ ] 5.5 Eliminar funciones helper duplicadas de parsing
- [ ] 5.6 Refactorizar `parse_forms` si ya no es necesaria
- [ ] 5.7 Limpiar imports no utilizados en Reader

## 6. Documentación y Finalización

- [ ] 6.1 Documentar módulo `Lexer` con @moduledoc
- [ ] 6.2 Documentar módulo `Parser` con @moduledoc
- [ ] 6.3 Actualizar @moduledoc de `Reader` con nueva arquitectura
- [ ] 6.4 Añadir ejemplos de uso en documentación
- [ ] 6.5 Actualizar CHANGELOG con refactorización
- [ ] 6.6 Verificar coverage de tests: `mix coveralls`

## Criterios de Aceptación

- [ ] 100% de tests existentes pasan sin modificaciones
- [ ] Reducción de líneas de código: de ~811 a ~300 (60% reducción)
- [ ] 0 cláusulas duplicadas entre parse_list/parse_vector/parse_map
- [ ] 100% de parsers nuevos tienen tests unitarios
- [ ] API pública de `Reader.parse/2` compatible hacia atrás
- [ ] Mensajes de error mantienen mismo formato
