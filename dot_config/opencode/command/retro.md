---
description: Capture lessons learned and update Prevention Patterns.
agent: build
model: google/antigravity-gemini-3-flash
---
# Retro Command

Runs a mini-retrospective to capture knowledge.

## 1. Trigger
Run this after a successful feature or bug fix.

## 2. Analysis
Ask the user:
1. "What went wrong during this task?"
2. "What pattern caused the bug?"
3. "How can we prevent this next time?"

## 3. Update Knowledge
Based on the answer, propose an update to `skill/prevention-patterns/SKILL.md`.
- Draft a new entry under the appropriate section.
- Ask user for confirmation to write it.
