---
description: Review staged changes, create commit message, ask for confirmation before committing.
agent: build
model: google/antigravity-gemini-3-flash
---

Generate a commit message and perform the commit following these rules explicitly:

If a message was provided via arguments, use it: $ARGUMENTS

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

## Safety Checks

**❌ STOP and WARN if detected:**
- Secrets: `.env*`, `*.key`, `*.pem`, `credentials.json`, `secrets.yaml`, `id_rsa`, `*.p12`, `*.pfx`, `*.cer`
- API Keys: Any `*_API_KEY`, `*_SECRET`, `*_TOKEN` variables with real values (not placeholders like `your-api-key`, `xxx`, `placeholder`)
- Large files: `>10MB` without Git LFS
- Build artifacts: `node_modules/`, `dist/`, `build/`, `__pycache__/`, `*.pyc`, `.venv/`
- Temp files: `.DS_Store`, `thumbs.db`, `*.swp`, `*.tmp`

**API Key Validation:**
Check modified files for patterns like:
```bash
OPENAI_API_KEY=sk-proj-xxxxx  # ❌ Real key detected!
AWS_SECRET_KEY=AKIA...         # ❌ Real key detected!
STRIPE_API_KEY=sk_live_...    # ❌ Real key detected!

# ✅ Acceptable placeholders:
API_KEY=your-api-key-here
SECRET_KEY=placeholder
TOKEN=xxx
API_KEY=<your-key>
SECRET=${YOUR_SECRET}
```
