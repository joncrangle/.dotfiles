---
description: Remove AI code slop
---

Check the code against master, and remove all AI generated slop introduced in this diff.

This includes:

- Extra comments that a human wouldn't add or is inconsistent with the rest of the file
- Extraneous markdown files
- One-time use scripts
- Extra defensive checks or try/catch blocks that are abnormal for that area of the codebase (especially if called by trusted / validated codepaths)
- Casts to any to get around type issues
- Any other style that is inconsistent with the file
- Unnecessary emoji usage

Report at the end with only a 1-3 sentence summary of what you changed
