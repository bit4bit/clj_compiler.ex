## ADDED Requirements

### Requirement: Line Comments
The system SHALL support line comments starting with `;` character.

#### Scenario: Simple line comment at start
- **WHEN** parsing `(defn foo [] ; this is a comment\n  "body")`
- **THEN** the comment should be stripped and not affect parsing
- **THEN** the form should parse successfully

#### Scenario: Line comment after code
- **WHEN** parsing `(defn foo [] "body" ; comment after code)`
- **THEN** everything after `;` should be treated as comment
- **THEN** the form should parse successfully

#### Scenario: Comment within string should not be stripped
- **WHEN** parsing `(defn foo [] "string with ; semicolon")`
- **THEN** the semicolon inside the string should be preserved
- **THEN** the form should parse successfully with the string intact

#### Scenario: Multiple comments on same line
- **WHEN** parsing `(defn foo [] ; comment 1 ; comment2\n  "body")`
- **THEN** only the first `;` should start the comment
- **THEN** the form should parse successfully

### Requirement: Block Comments via Reader Macro
The system SHALL support block comments using the `#_` reader macro that skips the next complete form.

#### Scenario: Skip next form with #_
- **WHEN** parsing `(defn foo [] #_ (skip-me) "body")`
- **THEN** the form `(skip-me)` should be completely ignored
- **THEN** the remaining code should parse successfully

#### Scenario: Skip nested form with #_
- **WHEN** parsing `(defn foo [] #_ [a b c] "body")`
- **THEN** the vector `[a b c]` should be ignored
- **THEN** the form should parse successfully

#### Scenario: Skip map with #_
- **WHEN** parsing `(defn foo [] #_ {:key "value"} "body")`
- **THEN** the map should be ignored
- **THEN** the form should parse successfully

#### Scenario: Multiple #_ in sequence
- **WHEN** parsing `(defn foo [] #_ (a) #_ (b) "body")`
- **THEN** both forms should be skipped
- **THEN** the form should parse successfully

### Requirement: Nested Comments
The system SHALL correctly handle nested structures when comments are involved.

#### Scenario: Comment inside list
- **WHEN** parsing `(defn foo [] (list 1 ; inner comment\n 2 3))`
- **THEN** the inner comment should be stripped
- **THEN** the list should parse correctly

#### Scenario: #_ inside list
- **WHEN** parsing `(defn foo [] (list 1 #_ (skip) 2 3))`
- **THEN** the skipped form should be removed from the list
- **THEN** the list should contain only `[1, 2, 3]`

### Requirement: Comment Special Form
The system SHALL support the `comment` special form for multi-line code commenting.

#### Scenario: Basic comment form
- **WHEN** parsing `(comment (defn foo [] "body") (defn bar [] "other"))`
- **THEN** the forms inside should be ignored
- **THEN** the comment form should evaluate to `nil`

#### Scenario: Comment with single form
- **WHEN** parsing `(comment (defn foo [] "body"))`
- **THEN** the inner form should be ignored
- **THEN** the result should be `nil`

#### Scenario: Nested comment forms
- **WHEN** parsing `(comment (comment (defn foo [] "body")))`
- **THEN** both levels should be handled correctly
- **THEN** the result should be `nil`

#### Scenario: Comment with expressions
- **WHEN** parsing `(comment 1 2 3 "string" :keyword)`
- **THEN** all expressions should be ignored
- **THEN** the result should be `nil`

#### Scenario: Comment inside function definition
- **WHEN** parsing `(defn foo [] (comment this is ignored) "body")`
- **THEN** the comment form should be removed during translation
- **THEN** the function should compile to just `"body"`

### Requirement: Mixed Comment Types
The system SHALL allow combining different comment types.

#### Scenario: #_ with comment form
- **WHEN** parsing `(comment #_ (skip-me) (keep-me))`
- **THEN** the `#_` should skip the first form
- **THEN** the `comment` form should ignore remaining forms
- **THEN** the result should be `nil`

#### Scenario: Line comments with comment form
- **WHEN** parsing `(comment
  (defn foo [] "body")
  ; line comment
  (defn bar [] "other"))`
- **THEN** all content should be ignored
- **THEN** the result should be `nil`
