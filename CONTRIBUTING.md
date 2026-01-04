# Contributing to CljCompiler

## LLM Agent Contribution Guidelines

This project is developed with LLM assistance. Follow these rules:

### Core Principles

1. **Test-Driven Development**: Write tests before implementation
2. **No Comments**: Code should be self-explanatory
3. **No Examples**: Only write code that's explicitly requested
4. **No Apologies**: Just fix and move forward

### Workflow

1. Read `spec.md` before making changes
2. Write failing test first
3. Implement minimal code to pass test
4. Update `spec.md` changelog after completion
5. Run all tests before committing
6. One feature per commit

### Testing Rules

- Write assertions for all code
- No duplicate test assertions
- Never modify test assertions during refactoring
- Run tests after every change

### Code Standards

- Use functional style (explicit parameters, immutability, declarative)
- Short functions, one responsibility
- No over-engineering
- Prefer pattern matching over conditionals

### Commit Strategy

- Each prompt = one commit
- Self-contained commits with tests
- 50/70 commit message format (subject line ≤ 50 chars, body ≤ 70 chars per line)
- Never commit automatically - require approval

### Error Handling

- All errors must include file, line, column information
- Provide descriptive error messages
- Fail fast at compile time

### Documentation

- Update `spec.md` changelog after each feature
- Update `README.md` if user-facing changes
- Keep documentation concise
- Use Markdown for all docs

### What NOT to Do

- Don't change test assertions when refactoring
- Don't skip failing tests
- Don't invent APIs - ask if unsure
- Don't commit without running tests
- Don't add robustness unless requested
- Don't create examples unless requested

### Before Submitting

1. All tests pass (`mix test`)
2. Check `git diff` to verify changes
3. Update relevant documentation
4. Verify no regressions introduced