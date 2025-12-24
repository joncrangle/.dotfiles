---
description: Review staged changes, create commit message, ask for confirmation before committing.
agent: build
model: google/gemini-3-flash
---

Generate a commit message and perform the commit following these rules explicitly:

All commits must follow the **Conventional Commits** specification.

## Format
```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

## Types
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only changes
- `style`: Code style changes (formatting, no logic change)
- `refactor`: Code refactoring (no feature change or bug fix)
- `perf`: Performance improvements
- `test`: Adding or updating tests
- `chore`: Maintenance tasks (dependencies, build, etc.)
- `ci`: CI/CD pipeline changes

## Rules
1. **Description**: Imperative mood ("add" not "added"), lowercase, no period, max 72 chars.
2. **Body**: Explain *why*, not *what*. Wrap at 72 chars.
3. **Breaking Changes**: Use an exclamation mark `!` in the message should be placed immediately before the colon in the commit message. The format is: <type>(<scope>)!: <description>

## Examples

**Good:**
```
feat(ml): add DCASE23 dataset preprocessor
fix(firmware): resolve I2C timeout on startup
docs(gateway): update wiring diagram
```

**Bad:**
```
Fixed bug.
Added new feature
feat: updates
```
