# Diseño: Refactorización de Reader a Parser Combinators

## Contexto

El módulo `Reader` actual implementa un lexer y parser manual para código Clojure. La implementación actual:

- **~811 líneas** en un solo módulo
- **25+ cláusulas** de `tokenize_impl` para tokenización
- **57 cláusulas** distribuidas en `parse_list`, `parse_vector`, `parse_map`
- **Acoplamiento** entre tokenización y parsing
- **Testabilidad limitada** - no hay forma de testear componentes aislados

### Restricciones del proyecto

- Elixir 1.15 compatible
- Sin runtime dependencies (la dependencia debe ser solo para compilación)
- API compatible hacia atrás
- Mantener mensajes de error con línea y columna

## Objetivos / No-Objetivos

### Objetivos
1. Reducir líneas de código en ~60-70%
2. Eliminar duplicación entre `parse_list`, `parse_vector`, `parse_map`
3. Lograr testabilidad unitaria de cada parser
4. Mejorar mantenibilidad con parsers composables
5. Mantener comportamiento idéntico para tests existentes

### No-Objetivos
1. Cambiar la API pública de `Reader.parse/2`
2. Añadir nuevas características de parsing (solo refactorización)
3. Optimizar rendimiento (la implementación actual es suficientemente rápida)
4. Soportar sintaxis Clojure adicional (fuera de scope)

## Decisiones Técnicas

### Decisión 1: Usar NimbleParsec

**Elección**: NimbleParsec (Dashbit)

**Justificación**:
- Sin runtime dependencies (compila a funciones puras)
- Composable y extensible
- Excelente soporte para tracking de posición (line, column)
- Ampliamente usado en el ecosistema Elixir (Phoenix, Ecto)
- API pequeña y bien documentada

**Alternativas consideradas**:
- `erlang_parsec` - requiere Erlang, menos integrado con Elixir
- `combine` - más antiguo, menos mantenimientos recientes
- Implementación manual - lo que tenemos actualmente (problemático)

### Decisión 2: Separación Lexer/Parser

**Estructura propuesta**:

```
lib/clj_compiler/
├── reader.ex        # API pública, orquestación
├── lexer.ex         # Parsers primitivos: string, number, symbol, delimiters
└── parser.ex        # Parsers compuestos: list, vector, map, forms
```

**Justificación**:
- Separación de concerns clara
- Testabilidad: cada módulo puede testearse independientemente
- Reutilización: el lexer puede usarse para otras herramientas (highlighting, etc.)

### Decisión 3: Estrategia de Tracking de Posición

**Elección**: Usar `line` y `column` de NimbleParsec con unwrap

**Justificación**:
- NimbleParsec provee `:line` y `:column` automáticamente
- Comportamiento similar al actual (tracking por carácter)
- Compatible con mensajes de error existentes

**Implementación**:

```elixir
# Ejemplo de parser con tracking
defp string do
  ignore(ascii_char([?"]))
  |> repeat(
    lookahead_not(ascii_char([?"]))
    |> utf8_char()
  )
  |> ignore(ascii_char([?"]))
  |> tag(:string)
  |> unwrap_and_tag(:token)
end
```

### Decisión 4: Manejo de Comments y Skip

**Elección**: Parser de forms ignora tokens de skip implícitamente

**Justificación**:
- `#_` (discard next form) es un feature del reader, no del lexer
- El parser de forms puede filtrar tokens `:skip` automáticamente
- Mantiene el lexer simple

**Implementación**:

```elixir
defp forms do
  choice([
    list,
    vector,
    map,
    string,
    number,
    symbol
  ])
  |> repeat()
  |> reject_has(:skip)  # Filtrar tokens de skip
end
```

### Decisión 5: Representación de Tokens

**Elección**: Mantener estructura actual `{type, value, line, column}`

**Justificación**:
- Compatibilidad con código existente
- Tests existentes esperan este formato
-便于调试

## Arquitectura Propuesta

### Flujo de Parsing

```
Source Code (string)
       ↓
    Lexer.parsec()  ← NimbleParsec parser
       ↓
    Tokens [{:token, value, line, col}, ...]
       ↓
    Parser.parsec()  ← Combina tokens en estructuras anidadas
       ↓
    Forms [{:list, [...], line}, {:vector, [...], line}, ...]
```

### Módulos y Responsabilidades

| Módulo | Responsabilidad |
|--------|-----------------|
| `Reader` | API pública, manejo de errores, orquestación |
| `Lexer` | Tokenización: strings, numbers, symbols, delimiters |
| `Parser` | Estructuras anidadas: list, vector, map |

## Riesgos y Mitigaciones

### Riesgo 1: Regresiones de comportamiento

**Probabilidad**: Media  
**Impacto**: Alto

**Mitigación**:
- Mantener tests existentes como suite de regresión
- Crear tests unitarios para cada parser
- Comparar salida de refactor vs original con casos de prueba

### Riesgo 2: Diferencias en mensajes de error

**Probabilidad**: Baja  
**Impacto**: Medio

**Mitigación**:
- Configurar errores personalizados en NimbleParsec
- Mantener mismo formato de `ParseError`
- Tests específicos para mensajes de error

### Riesgo 3: Rendimiento degradado

**Probabilidad**: Baja  
**Impacto**: Bajo

**Mitigación**:
- NimbleParsec compila a código nativo eficiente
- Benchmark antes y después
- Si es necesario, usar `parsec` vs `parsec_d` según profiling

## Plan de Migración

### Fase 1: Preparación
1. Añadir `{:nimble_parsec, "~> 1.4", only: :dev}` a `mix.exs`
2. Crear módulo `Lexer` con parsers primitivos
3. Crear tests unitarios para cada parser del lexer

### Fase 2: Lexer
1. Implementar `Lexer.string/0`
2. Implementar `Lexer.number/0`
3. Implementar `Lexer.symbol/0`
4. Implementar `Lexer.delimiter/0`
5. Verificar que token output es compatible

### Fase 3: Parser
1. Implementar `Parser.list/0`
2. Implementar `Parser.vector/0`
3. Implementar `Parser.map/0`
4. Implementar `Parser.forms/0`
5. Integrar con lexer

### Fase 4: Integración
1. Refactorizar `Reader` para usar nuevo lexer/parser
2. Mantener firma de `parse/2`
3. Verificar todos los tests existentes pasen
4. Eliminar código duplicado antiguo

### Fase 5: Limpieza
1. Eliminar `tokenize_impl` antiguo
2. Eliminar `parse_list`, `parse_vector`, `parse_map` duplicados
3. Documentar nuevos módulos
4. Actualizar CHANGELOG

## Preguntas Abiertas

1. ¿Debería el lexer manejar `#_` (discard) o debe ser responsabilidad del parser?
   - Recomendación: lexer lo emite como token `:skip`, parser lo ignora

2. ¿Mantener soporte para reader macros en el futuro?
   - Si, la arquitectura debe permitir añadir parsers de reader macros

3. ¿Cómo manejar caracteres Unicode correctamente?
   - NimbleParsec soporta UTF-8 nativamente, debe funcionar igual que ahora

## Métricas de Éxito

- Reducción de líneas de código: ~60% (de 811 a ~300)
- Eliminación de duplicación: 0 cláusulas idénticas entre funciones
- Testabilidad: 100% de parsers con tests unitarios
- Compatibilidad: 100% de tests existentes pasan