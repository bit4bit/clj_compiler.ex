## ADDED Requirements
### Requirement: Multiple :use Declarations on Separate Lines
The system SHALL support multiple `:use` declarations on separate lines within the same `ns` form.

#### Scenario: Two :use declarations on separate lines
- **WHEN** parsing
  ```
  (ns demo
   (:use [Application])
   (:use [CljCompiler.Compat]))
  ```
- **THEN** the system SHALL extract both `Application` and `CljCompiler.Compat` as use clauses

#### Scenario: Three :use declarations on separate lines
- **WHEN** parsing
  ```
  (ns demo
   (:use [A])
   (:use [B])
   (:use [C]))
  ```
- **THEN** the system SHALL extract `A`, `B`, and `C` as use clauses

#### Scenario: Single :use declaration remains unchanged
- **WHEN** parsing `(ns demo (:use [Application]))`
- **THEN** the system SHALL extract `Application` as a use clause
- **THEN** backward compatibility SHALL be maintained
