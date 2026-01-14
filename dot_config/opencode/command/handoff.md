---
description: Handoff current context to a new session or agent.
agent: build
model: google/antigravity-gemini-3-flash
---
# Handoff Command

Generates a **Continuation Prompt** to seamlessly transfer work.

## 1. Gather State
- **Goal**: What was the original objective?
- **Progress**: What has been done? (Check git status/log)
- **Pending**: What is left to do?
- **Context**: Critical file paths or decisions made.

## 2. Generate Prompt
Output a code block like this:

```markdown
# 🔄 CONTINUATION HANDOFF

**Objective**: [Original Goal]

**Status**:
- [x] Step 1
- [ ] Step 2 (Current Focus)

**Context**:
- Modified files: [List]
- Key decisions: [Notes]

**Next Action**:
- Continue with Step 2.
- Be aware of [Risk/Constraint].
```

## 3. Instructions
Tell the user: "Copy the block above and paste it into your next session."
